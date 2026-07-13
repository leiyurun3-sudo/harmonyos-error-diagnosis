import { describe, expect, it } from '@ohos/hypium';
import { HTTP_STATUS_RESOURCE_NAME } from '../../main/ets/constants/StaticResources';
import { ErrorCode } from '../../main/ets/constants/ErrorCodes';
import { HttpStatusResourceLoader } from '../../main/ets/repository/static/HttpStatusResourceLoader';
import { HiLogService } from '../../main/ets/service/platform/HiLogService';
import { CapturingLogSink } from '../fakes/CapturingLogSink';
import { InMemoryRawResourceReader } from '../fakes/InMemoryRawResourceReader';
import {
  createHttpTextWithDuplicateCode,
  createHttpTextWithMissingField,
  createHttpTextWithOutOfRangeCode,
  createInvalidHttpStatusJsonText,
  createUnsupportedHttpSchemaText,
  createValidHttpStatusResourceText
} from '../fixtures/RuntimeResourceFixtures';

function createLoader(text: string): HttpStatusResourceLoader {
  return new HttpStatusResourceLoader(
    new InMemoryRawResourceReader([
      { resourceName: HTTP_STATUS_RESOURCE_NAME, content: text }
    ]),
    new HiLogService(new CapturingLogSink())
  );
}

export default function httpStatusResourceLoaderTest() {
  describe('HttpStatusResourceLoader', () => {
    it('loads the T5 statuses as T3 domain models', 0, async (): Promise<void> => {
      const result = await createLoader(createValidHttpStatusResourceText()).load();

      expect(result.success).assertTrue();
      expect(result.data?.length).assertEqual(14);
      expect(result.data?.[0].name).assertEqual('OK');
    });

    it('maps malformed JSON to a resource parse failure', 0, async (): Promise<void> => {
      const result = await createLoader(createInvalidHttpStatusJsonText()).load();

      expect(result.success).assertFalse();
      expect(result.error?.code).assertEqual(ErrorCode.RULE_RESOURCE_FAILED);
      expect(result.error?.causeType).assertEqual('JSON_PARSE');
    });

    it('rejects an unsupported schema version', 0, async (): Promise<void> => {
      const result = await createLoader(createUnsupportedHttpSchemaText()).load();

      expect(result.success).assertFalse();
      expect(result.error?.causeType).assertEqual('SCHEMA_UNSUPPORTED');
    });

    it('rejects an entry with a missing required field', 0, async (): Promise<void> => {
      const result = await createLoader(createHttpTextWithMissingField()).load();

      expect(result.success).assertFalse();
      expect(result.error?.causeType).assertEqual('RESOURCE_VALIDATION');
    });

    it('rejects duplicate HTTP status codes', 0, async (): Promise<void> => {
      const result = await createLoader(createHttpTextWithDuplicateCode()).load();

      expect(result.success).assertFalse();
      expect(result.error?.causeType).assertEqual('DUPLICATE_IDENTIFIER');
    });

    it('rejects an HTTP status code outside the T3 boundaries', 0, async (): Promise<void> => {
      const result = await createLoader(createHttpTextWithOutOfRangeCode()).load();

      expect(result.success).assertFalse();
      expect(result.error?.causeType).assertEqual('RESOURCE_VALIDATION');
    });

    it('returns isolated status objects from its cache', 0, async (): Promise<void> => {
      const reader = new InMemoryRawResourceReader([
        { resourceName: HTTP_STATUS_RESOURCE_NAME, content: createValidHttpStatusResourceText() }
      ]);
      const loader = new HttpStatusResourceLoader(reader, new HiLogService(new CapturingLogSink()));
      const first = await loader.load();
      if (first.data !== undefined) {
        first.data[0].causes[0] = 'changed by caller';
      }

      const second = await loader.load();

      expect(second.data?.[0].causes[0]).assertEqual('服务器已正常接收、理解并处理请求。');
      expect(reader.getReadCount(HTTP_STATUS_RESOURCE_NAME)).assertEqual(1);
    });
  });
}
