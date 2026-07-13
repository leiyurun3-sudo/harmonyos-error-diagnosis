import {
  HTTP_STATUS_RESOURCE_NAME,
  HTTP_STATUS_SCHEMA_NAME,
  STATIC_RESOURCE_SCHEMA_VERSION,
  STATIC_RESOURCE_VERSION
} from '../../constants/StaticResources';
import {
  HTTP_STATUS_CODE_MAX,
  HTTP_STATUS_CODE_MIN
} from '../../constants/AppLimits';
import { ErrorCode } from '../../constants/ErrorCodes';
import {
  AppResult,
  createFailureResult,
  createSuccessResult,
  HttpStatusEntry
} from '../../model/ResultModels';
import {
  HiLogService,
  LogLevel,
  LogMetadataKey
} from '../../service/platform/HiLogService';
import { RawResourceReader } from '../../storage/static/RawResourceStore';

interface HttpStatusDocument {
  schemaName: string;
  schemaVersion: number;
  resourceVersion: string;
  entries: Array<HttpStatusEntry>;
}

function isNonEmptyText(value: string): boolean {
  return typeof value === 'string' && value.trim().length > 0;
}

function isNonEmptyStringArray(value: Array<string>): boolean {
  if (!Array.isArray(value) || value.length === 0) {
    return false;
  }
  for (let index: number = 0; index < value.length; index++) {
    if (!isNonEmptyText(value[index])) {
      return false;
    }
  }
  return true;
}

function categoryFor(code: number): string {
  if (code < 200) {
    return 'Informational';
  }
  if (code < 300) {
    return 'Success';
  }
  if (code < 400) {
    return 'Redirection';
  }
  if (code < 500) {
    return 'Client Error';
  }
  return 'Server Error';
}

function isValidEntry(entry: HttpStatusEntry): boolean {
  return Number.isInteger(entry.code) &&
    entry.code >= HTTP_STATUS_CODE_MIN && entry.code <= HTTP_STATUS_CODE_MAX &&
    isNonEmptyText(entry.name) && entry.category === categoryFor(entry.code) &&
    isNonEmptyText(entry.description) && isNonEmptyStringArray(entry.causes) &&
    isNonEmptyStringArray(entry.steps);
}

function copyEntry(entry: HttpStatusEntry): HttpStatusEntry {
  return {
    code: entry.code,
    name: entry.name,
    category: entry.category,
    description: entry.description,
    causes: entry.causes.slice(),
    steps: entry.steps.slice()
  };
}

function copyEntries(entries: Array<HttpStatusEntry>): Array<HttpStatusEntry> {
  const copied: Array<HttpStatusEntry> = [];
  for (let index: number = 0; index < entries.length; index++) {
    copied.push(copyEntry(entries[index]));
  }
  return copied;
}

/** Loads, validates and caches the versioned HTTP status resource. */
export class HttpStatusResourceLoader {
  private reader: RawResourceReader;
  private logger: HiLogService;
  private cache?: Array<HttpStatusEntry>;

  constructor(reader: RawResourceReader, logger: HiLogService) {
    this.reader = reader;
    this.logger = logger;
  }

  async load(): Promise<AppResult<Array<HttpStatusEntry>>> {
    if (this.cache !== undefined) {
      return createSuccessResult<Array<HttpStatusEntry>>(copyEntries(this.cache));
    }
    const textResult = await this.reader.readText(HTTP_STATUS_RESOURCE_NAME);
    if (!textResult.success || textResult.data === undefined) {
      if (textResult.error !== undefined) {
        return createFailureResult<Array<HttpStatusEntry>>(textResult.error);
      }
      return this.failure('read', 'RAWFILE_READ');
    }

    let document: HttpStatusDocument;
    try {
      document = JSON.parse(textResult.data) as HttpStatusDocument;
    } catch (_) {
      return this.failure('parse', 'JSON_PARSE');
    }
    try {
      if (document.schemaName !== HTTP_STATUS_SCHEMA_NAME ||
        document.schemaVersion !== STATIC_RESOURCE_SCHEMA_VERSION) {
        return this.failure('schema', 'SCHEMA_UNSUPPORTED');
      }
      if (document.resourceVersion !== STATIC_RESOURCE_VERSION) {
        return this.failure('version', 'RESOURCE_VERSION_UNSUPPORTED');
      }
      if (!Array.isArray(document.entries) || document.entries.length === 0) {
        return this.failure('validate', 'RESOURCE_VALIDATION');
      }

      const entries: Array<HttpStatusEntry> = [];
      const codes: Array<number> = [];
      for (let index: number = 0; index < document.entries.length; index++) {
        const entry = document.entries[index];
        if (!isValidEntry(entry)) {
          return this.failure('validate', 'RESOURCE_VALIDATION');
        }
        if (codes.includes(entry.code)) {
          return this.failure('validate', 'DUPLICATE_IDENTIFIER');
        }
        codes.push(entry.code);
        entries.push(copyEntry(entry));
      }
      this.cache = copyEntries(entries);
      return createSuccessResult<Array<HttpStatusEntry>>(copyEntries(this.cache));
    } catch (_) {
      return this.failure('validate', 'RESOURCE_VALIDATION');
    }
  }

  private failure(stage: string, causeType: string): AppResult<Array<HttpStatusEntry>> {
    this.logger.log(LogLevel.ERROR, {
      domain: 'static_resource',
      event: 'http_status_failed',
      errorCode: ErrorCode.RULE_RESOURCE_FAILED,
      metadata: [
        { key: LogMetadataKey.RESOURCE_NAME, value: HTTP_STATUS_RESOURCE_NAME },
        { key: LogMetadataKey.STAGE, value: stage }
      ]
    });
    return createFailureResult<Array<HttpStatusEntry>>({
      code: ErrorCode.RULE_RESOURCE_FAILED,
      message: '内置 HTTP 状态资料暂时不可用。',
      retryable: false,
      causeType: causeType
    });
  }
}
