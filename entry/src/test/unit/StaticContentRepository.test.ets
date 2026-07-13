import { describe, expect, it } from '@ohos/hypium';
import {
  DIAGNOSIS_RULE_RESOURCE_NAME,
  HTTP_STATUS_RESOURCE_NAME,
  PRIVACY_NOTICE_RESOURCE_NAME
} from '../../main/ets/constants/StaticResources';
import { ErrorCode } from '../../main/ets/constants/ErrorCodes';
import { DiagnosisRuleResourceLoader } from '../../main/ets/repository/static/DiagnosisRuleResourceLoader';
import { HttpStatusResourceLoader } from '../../main/ets/repository/static/HttpStatusResourceLoader';
import { LocalStaticContentRepository } from '../../main/ets/repository/static/StaticContentRepository';
import { HiLogService } from '../../main/ets/service/platform/HiLogService';
import { CapturingLogSink } from '../fakes/CapturingLogSink';
import { InMemoryRawResourceReader } from '../fakes/InMemoryRawResourceReader';
import {
  createPrivacyTextFixture,
  createValidDiagnosisResourceText,
  createValidHttpStatusResourceText
} from '../fixtures/RuntimeResourceFixtures';

function createRepository(reader: InMemoryRawResourceReader): LocalStaticContentRepository {
  const logger = new HiLogService(new CapturingLogSink());
  return new LocalStaticContentRepository(
    new DiagnosisRuleResourceLoader(reader, logger),
    new HttpStatusResourceLoader(reader, logger),
    reader,
    logger
  );
}

function createCompleteReader(): InMemoryRawResourceReader {
  return new InMemoryRawResourceReader([
    { resourceName: DIAGNOSIS_RULE_RESOURCE_NAME, content: createValidDiagnosisResourceText() },
    { resourceName: HTTP_STATUS_RESOURCE_NAME, content: createValidHttpStatusResourceText() },
    { resourceName: PRIVACY_NOTICE_RESOURCE_NAME, content: createPrivacyTextFixture() }
  ]);
}

export default function staticContentRepositoryTest() {
  describe('StaticContentRepository', () => {
    it('returns a known HTTP status entry', 0, async (): Promise<void> => {
      const result = await createRepository(createCompleteReader()).getHttpStatus(404);

      expect(result.success).assertTrue();
      expect(result.data?.name).assertEqual('Not Found');
    });

    it('returns a cautious category fallback for an unlisted valid status', 0, async (): Promise<void> => {
      const result = await createRepository(createCompleteReader()).getHttpStatus(418);

      expect(result.success).assertTrue();
      expect(result.data?.code).assertEqual(418);
      expect(result.data?.category).assertEqual('Client Error');
      expect(result.data?.name).assertEqual('暂无详细解释');
    });

    it('rejects a status code outside the documented input range', 0, async (): Promise<void> => {
      const result = await createRepository(createCompleteReader()).getHttpStatus(99);

      expect(result.success).assertFalse();
      expect(result.error?.code).assertEqual(ErrorCode.VAL_FORMAT_INVALID);
      expect(result.error?.causeType).assertEqual('HTTP_STATUS_RANGE');
    });

    it('loads and caches the built-in privacy text', 0, async (): Promise<void> => {
      const reader = createCompleteReader();
      const repository = createRepository(reader);
      const first = await repository.getPrivacyText();
      const second = await repository.getPrivacyText();

      expect(first.data).assertEqual(createPrivacyTextFixture());
      expect(second.data).assertEqual(createPrivacyTextFixture());
      expect(reader.getReadCount(PRIVACY_NOTICE_RESOURCE_NAME)).assertEqual(1);
    });

    it('maps missing privacy text to the existing resource error', 0, async (): Promise<void> => {
      const reader = new InMemoryRawResourceReader([
        { resourceName: DIAGNOSIS_RULE_RESOURCE_NAME, content: createValidDiagnosisResourceText() },
        { resourceName: HTTP_STATUS_RESOURCE_NAME, content: createValidHttpStatusResourceText() }
      ]);
      const result = await createRepository(reader).getPrivacyText();

      expect(result.success).assertFalse();
      expect(result.error?.code).assertEqual(ErrorCode.RULE_RESOURCE_FAILED);
    });
  });
}
