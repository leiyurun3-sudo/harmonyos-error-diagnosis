import {
  HTTP_STATUS_CODE_MAX,
  HTTP_STATUS_CODE_MIN
} from '../../constants/AppLimits';
import { ErrorCode } from '../../constants/ErrorCodes';
import { PRIVACY_NOTICE_RESOURCE_NAME } from '../../constants/StaticResources';
import { DiagnosisRule } from '../../model/DiagnosisModels';
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
import { DiagnosisRuleResourceLoader } from './DiagnosisRuleResourceLoader';
import { HttpStatusResourceLoader } from './HttpStatusResourceLoader';

export interface StaticContentRepository {
  loadDiagnosisRules(): Promise<AppResult<Array<DiagnosisRule>>>;
  getHttpStatus(code: number): Promise<AppResult<HttpStatusEntry>>;
  getPrivacyText(): Promise<AppResult<string>>;
}

function copyStatus(entry: HttpStatusEntry): HttpStatusEntry {
  return {
    code: entry.code,
    name: entry.name,
    category: entry.category,
    description: entry.description,
    causes: entry.causes.slice(),
    steps: entry.steps.slice()
  };
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

function createUnknownStatus(code: number): HttpStatusEntry {
  return {
    code: code,
    name: '暂无详细解释',
    category: categoryFor(code),
    description: '该状态码在当前内置资料中没有详细说明。',
    causes: ['状态码有效，但当前资源版本未收录其具体语义。'],
    steps: ['结合接口文档和响应内容进一步确认。']
  };
}

/** Read-only facade for bundled P0 static content. */
export class LocalStaticContentRepository implements StaticContentRepository {
  private diagnosisLoader: DiagnosisRuleResourceLoader;
  private statusLoader: HttpStatusResourceLoader;
  private reader: RawResourceReader;
  private logger: HiLogService;
  private privacyCache?: string;

  constructor(
    diagnosisLoader: DiagnosisRuleResourceLoader,
    statusLoader: HttpStatusResourceLoader,
    reader: RawResourceReader,
    logger: HiLogService
  ) {
    this.diagnosisLoader = diagnosisLoader;
    this.statusLoader = statusLoader;
    this.reader = reader;
    this.logger = logger;
  }

  loadDiagnosisRules(): Promise<AppResult<Array<DiagnosisRule>>> {
    return this.diagnosisLoader.load();
  }

  async getHttpStatus(code: number): Promise<AppResult<HttpStatusEntry>> {
    if (!Number.isInteger(code) || code < HTTP_STATUS_CODE_MIN || code > HTTP_STATUS_CODE_MAX) {
      return createFailureResult<HttpStatusEntry>({
        code: ErrorCode.VAL_FORMAT_INVALID,
        message: '请输入 100 到 599 之间的整数状态码。',
        retryable: false,
        causeType: 'HTTP_STATUS_RANGE'
      });
    }
    const result = await this.statusLoader.load();
    if (!result.success || result.data === undefined) {
      if (result.error !== undefined) {
        return createFailureResult<HttpStatusEntry>(result.error);
      }
      return createFailureResult<HttpStatusEntry>({
        code: ErrorCode.RULE_RESOURCE_FAILED,
        message: '内置 HTTP 状态资料暂时不可用。',
        retryable: false,
        causeType: 'RESOURCE_VALIDATION'
      });
    }
    for (let index: number = 0; index < result.data.length; index++) {
      if (result.data[index].code === code) {
        return createSuccessResult<HttpStatusEntry>(copyStatus(result.data[index]));
      }
    }
    return createSuccessResult<HttpStatusEntry>(createUnknownStatus(code));
  }

  async getPrivacyText(): Promise<AppResult<string>> {
    if (this.privacyCache !== undefined) {
      return createSuccessResult<string>(this.privacyCache);
    }
    const result = await this.reader.readText(PRIVACY_NOTICE_RESOURCE_NAME);
    if (!result.success || result.data === undefined) {
      if (result.error !== undefined) {
        return createFailureResult<string>(result.error);
      }
      return this.privacyFailure('read');
    }
    const text = result.data.trim();
    if (text.length === 0) {
      return this.privacyFailure('validate');
    }
    this.privacyCache = text;
    return createSuccessResult<string>(this.privacyCache);
  }

  private privacyFailure(stage: string): AppResult<string> {
    this.logger.log(LogLevel.ERROR, {
      domain: 'static_resource',
      event: 'privacy_text_failed',
      errorCode: ErrorCode.RULE_RESOURCE_FAILED,
      metadata: [
        { key: LogMetadataKey.RESOURCE_NAME, value: PRIVACY_NOTICE_RESOURCE_NAME },
        { key: LogMetadataKey.STAGE, value: stage }
      ]
    });
    return createFailureResult<string>({
      code: ErrorCode.RULE_RESOURCE_FAILED,
      message: '内置隐私说明暂时不可用。',
      retryable: false,
      causeType: 'RESOURCE_VALIDATION'
    });
  }
}
