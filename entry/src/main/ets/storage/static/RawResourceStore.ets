import { util } from '@kit.ArkTS';
import { resourceManager } from '@kit.LocalizationKit';
import { ErrorCode } from '../../constants/ErrorCodes';
import {
  AppResult,
  createFailureResult,
  createSuccessResult
} from '../../model/ResultModels';
import {
  HiLogService,
  LogLevel,
  LogMetadataKey
} from '../../service/platform/HiLogService';

export interface RawFileContentSource {
  getRawFileContent(resourceName: string): Promise<Uint8Array>;
}

export interface RawTextDecoder {
  decode(content: Uint8Array): string;
}

export interface RawResourceReader {
  readText(resourceName: string): Promise<AppResult<string>>;
}

/** Platform adapter kept behind an injectable rawfile boundary. */
export class ResourceManagerRawFileContentSource implements RawFileContentSource {
  private manager: resourceManager.ResourceManager;

  constructor(manager: resourceManager.ResourceManager) {
    this.manager = manager;
  }

  getRawFileContent(resourceName: string): Promise<Uint8Array> {
    return this.manager.getRawFileContent(resourceName);
  }
}

/** Strict UTF-8 decoder. Malformed byte sequences fail instead of being replaced. */
export class Utf8RawTextDecoder implements RawTextDecoder {
  decode(content: Uint8Array): string {
    return util.TextDecoder.create('utf-8', { fatal: true }).decodeToString(content);
  }
}

/** Safe read/decode boundary for bundled rawfiles. */
export class RawResourceStore implements RawResourceReader {
  private source: RawFileContentSource;
  private decoder: RawTextDecoder;
  private logger: HiLogService;

  constructor(source: RawFileContentSource, decoder: RawTextDecoder, logger: HiLogService) {
    this.source = source;
    this.decoder = decoder;
    this.logger = logger;
  }

  async readText(resourceName: string): Promise<AppResult<string>> {
    let content: Uint8Array;
    try {
      content = await this.source.getRawFileContent(resourceName);
    } catch (_) {
      return this.failure(resourceName, 'read', 'RAWFILE_READ');
    }

    try {
      const text = this.decoder.decode(content);
      if (text.trim().length === 0) {
        return this.failure(resourceName, 'decode', 'RESOURCE_EMPTY');
      }
      return createSuccessResult<string>(text);
    } catch (_) {
      return this.failure(resourceName, 'decode', 'UTF8_DECODE');
    }
  }

  private failure(resourceName: string, stage: string, causeType: string): AppResult<string> {
    this.logger.log(LogLevel.ERROR, {
      domain: 'static_resource',
      event: 'read_failed',
      errorCode: ErrorCode.RULE_RESOURCE_FAILED,
      metadata: [
        { key: LogMetadataKey.RESOURCE_NAME, value: resourceName },
        { key: LogMetadataKey.STAGE, value: stage }
      ]
    });
    return createFailureResult<string>({
      code: ErrorCode.RULE_RESOURCE_FAILED,
      message: '内置资源暂时无法读取。',
      retryable: true,
      causeType: causeType
    });
  }
}
