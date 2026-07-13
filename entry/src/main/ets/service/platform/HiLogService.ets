/** Log levels defined by detailed design section 12.2. */
export enum LogLevel {
  DEBUG = 'DEBUG',
  INFO = 'INFO',
  WARN = 'WARN',
  ERROR = 'ERROR'
}

/** Exact metadata whitelist accepted by the logging facade. */
export enum LogMetadataKey {
  RULE_VERSION = 'ruleVersion',
  RECORD_COUNT = 'recordCount',
  TEXT_LENGTH_RANGE = 'textLengthRange',
  CAPABILITY_AVAILABLE = 'capabilityAvailable',
  PAGE_NAME = 'pageName',
  RESOURCE_NAME = 'resourceName',
  STAGE = 'stage'
}

export type LogMetadataValue = string | number | boolean;

export interface LogMetadataItem {
  key: string;
  value: LogMetadataValue;
}

export interface LogContext {
  domain: string;
  event: string;
  correlationId?: string;
  result?: string;
  durationMs?: number;
  errorCode?: string;
  metadata?: Array<LogMetadataItem>;
}

export interface LogRecord {
  timestamp: number;
  level: LogLevel;
  domain: string;
  event: string;
  correlationId?: string;
  result?: string;
  durationMs?: number;
  errorCode?: string;
  metadata: Array<LogMetadataItem>;
}

/** Injectable boundary implemented by the platform HiLog adapter. */
export interface LogSink {
  write(record: LogRecord): void;
}

function containsSensitiveMarker(value: string): boolean {
  const normalized = value.toLowerCase();
  return normalized.includes('token') ||
    normalized.includes('password') ||
    normalized.includes('authorization') ||
    normalized.includes('bearer') ||
    normalized.includes('secret') ||
    normalized.includes('@') ||
    normalized.includes('http://') ||
    normalized.includes('https://') ||
    normalized.includes('file://') ||
    normalized.includes('photo://') ||
    normalized.includes(':\\') ||
    normalized.includes('/data/') ||
    containsPhoneNumber(normalized);
}

function containsPhoneNumber(value: string): boolean {
  let digitRunLength: number = 0;
  let digitRunStartsWithOne: boolean = false;
  for (let index: number = 0; index < value.length; index++) {
    const code = value.charCodeAt(index);
    const isDigit = code >= 48 && code <= 57;
    if (!isDigit) {
      digitRunLength = 0;
      digitRunStartsWithOne = false;
      continue;
    }
    if (digitRunLength === 0) {
      digitRunStartsWithOne = code === 49;
    }
    digitRunLength++;
    if (digitRunStartsWithOne && digitRunLength >= 11) {
      return true;
    }
  }
  return false;
}

function isSafeRequiredText(value: string): boolean {
  return value.trim().length > 0 && !containsSensitiveMarker(value);
}

function isSafeOptionalText(value: string | undefined): boolean {
  return value === undefined || isSafeRequiredText(value);
}

function isAllowedMetadata(item: LogMetadataItem): boolean {
  if (typeof item.value === 'string' && containsSensitiveMarker(item.value)) {
    return false;
  }
  switch (item.key) {
    case LogMetadataKey.RULE_VERSION:
    case LogMetadataKey.TEXT_LENGTH_RANGE:
    case LogMetadataKey.PAGE_NAME:
    case LogMetadataKey.RESOURCE_NAME:
    case LogMetadataKey.STAGE:
      return typeof item.value === 'string' && item.value.trim().length > 0;
    case LogMetadataKey.RECORD_COUNT:
      return typeof item.value === 'number' && Number.isFinite(item.value) && item.value >= 0;
    case LogMetadataKey.CAPABILITY_AVAILABLE:
      return typeof item.value === 'boolean';
    default:
      return false;
  }
}

/** Filters and copies metadata so only safe whitelisted values can reach a sink. */
export function filterLogMetadata(metadata: Array<LogMetadataItem>): Array<LogMetadataItem> {
  const filtered: Array<LogMetadataItem> = [];
  for (let index: number = 0; index < metadata.length; index++) {
    const item = metadata[index];
    if (isAllowedMetadata(item)) {
      filtered.push({
        key: item.key,
        value: item.value
      });
    }
  }
  return filtered;
}

/** Pure structured-record builder used before crossing the platform logging boundary. */
export function createLogRecord(
  level: LogLevel,
  context: LogContext,
  timestamp: number
): LogRecord | undefined {
  if (!Number.isFinite(timestamp) || timestamp < 0 ||
    !isSafeRequiredText(context.domain) || !isSafeRequiredText(context.event) ||
    !isSafeOptionalText(context.correlationId) || !isSafeOptionalText(context.result) ||
    !isSafeOptionalText(context.errorCode) ||
    (context.durationMs !== undefined && (!Number.isFinite(context.durationMs) || context.durationMs < 0))) {
    return undefined;
  }

  const record: LogRecord = {
    timestamp: timestamp,
    level: level,
    domain: context.domain,
    event: context.event,
    metadata: context.metadata === undefined ? [] : filterLogMetadata(context.metadata)
  };
  if (context.correlationId !== undefined) {
    record.correlationId = context.correlationId;
  }
  if (context.result !== undefined) {
    record.result = context.result;
  }
  if (context.durationMs !== undefined) {
    record.durationMs = context.durationMs;
  }
  if (context.errorCode !== undefined) {
    record.errorCode = context.errorCode;
  }
  return record;
}

/** Business-independent logging facade. It never accepts free-form message bodies. */
export class HiLogService {
  private sink: LogSink;

  constructor(sink: LogSink) {
    this.sink = sink;
  }

  log(level: LogLevel, context: LogContext): boolean {
    const record = createLogRecord(level, context, Date.now());
    if (record === undefined) {
      return false;
    }
    this.sink.write(record);
    return true;
  }
}
