import { describe, expect, it } from '@ohos/hypium';
import {
  DIAGNOSIS_RULE_RESOURCE_NAME
} from '../../main/ets/constants/StaticResources';
import { ErrorCode } from '../../main/ets/constants/ErrorCodes';
import { DiagnosisRuleResourceLoader } from '../../main/ets/repository/static/DiagnosisRuleResourceLoader';
import { HiLogService } from '../../main/ets/service/platform/HiLogService';
import { CapturingLogSink } from '../fakes/CapturingLogSink';
import { InMemoryRawResourceReader } from '../fakes/InMemoryRawResourceReader';
import {
  createDiagnosisTextWithDuplicateRuleId,
  createDiagnosisTextWithInvalidPattern,
  createDiagnosisTextWithOneMissingField,
  createDiagnosisTextWithTwoInvalidRules,
  createInvalidDiagnosisJsonText,
  createUnsupportedDiagnosisSchemaText,
  createUnsupportedDiagnosisVersionText,
  createValidDiagnosisResourceText
} from '../fixtures/RuntimeResourceFixtures';

function createLoader(text: string, sink: CapturingLogSink): DiagnosisRuleResourceLoader {
  return new DiagnosisRuleResourceLoader(
    new InMemoryRawResourceReader([
      { resourceName: DIAGNOSIS_RULE_RESOURCE_NAME, content: text }
    ]),
    new HiLogService(sink)
  );
}

export default function diagnosisRuleResourceLoaderTest() {
  describe('DiagnosisRuleResourceLoader', () => {
    it('loads the T5 rules as T3 domain models', 0, async (): Promise<void> => {
      const result = await createLoader(createValidDiagnosisResourceText(), new CapturingLogSink()).load();

      expect(result.success).assertTrue();
      expect(result.data?.length).assertEqual(12);
      expect(result.data?.[0].ruleId).assertEqual('json_parse_error');
    });

    it('maps malformed JSON to a resource parse failure', 0, async (): Promise<void> => {
      const result = await createLoader(createInvalidDiagnosisJsonText(), new CapturingLogSink()).load();

      expect(result.success).assertFalse();
      expect(result.error?.code).assertEqual(ErrorCode.RULE_RESOURCE_FAILED);
      expect(result.error?.causeType).assertEqual('JSON_PARSE');
    });

    it('rejects unsupported schema name and resource version', 0, async (): Promise<void> => {
      const schemaResult = await createLoader(
        createUnsupportedDiagnosisSchemaText(),
        new CapturingLogSink()
      ).load();
      const versionResult = await createLoader(
        createUnsupportedDiagnosisVersionText(),
        new CapturingLogSink()
      ).load();

      expect(schemaResult.error?.causeType).assertEqual('SCHEMA_UNSUPPORTED');
      expect(versionResult.error?.causeType).assertEqual('RESOURCE_VERSION_UNSUPPORTED');
    });

    it('isolates one rule with a missing required field', 0, async (): Promise<void> => {
      const sink = new CapturingLogSink();
      const result = await createLoader(createDiagnosisTextWithOneMissingField(), sink).load();

      expect(result.success).assertTrue();
      expect(result.data?.length).assertEqual(11);
      expect(sink.records.length).assertEqual(1);
      expect(JSON.stringify(sink.records[0]).includes('summaryTemplate')).assertFalse();
    });

    it('isolates one rule with an invalid regular expression', 0, async (): Promise<void> => {
      const result = await createLoader(
        createDiagnosisTextWithInvalidPattern(),
        new CapturingLogSink()
      ).load();

      expect(result.success).assertTrue();
      expect(result.data?.length).assertEqual(11);
    });

    it('rejects duplicate rule identifiers as an ambiguous resource', 0, async (): Promise<void> => {
      const result = await createLoader(
        createDiagnosisTextWithDuplicateRuleId(),
        new CapturingLogSink()
      ).load();

      expect(result.success).assertFalse();
      expect(result.error?.causeType).assertEqual('DUPLICATE_IDENTIFIER');
    });

    it('rejects a resource containing more than one invalid rule', 0, async (): Promise<void> => {
      const result = await createLoader(
        createDiagnosisTextWithTwoInvalidRules(),
        new CapturingLogSink()
      ).load();

      expect(result.success).assertFalse();
      expect(result.error?.causeType).assertEqual('RESOURCE_VALIDATION');
    });

    it('returns isolated rule objects from its cache', 0, async (): Promise<void> => {
      const reader = new InMemoryRawResourceReader([
        { resourceName: DIAGNOSIS_RULE_RESOURCE_NAME, content: createValidDiagnosisResourceText() }
      ]);
      const loader = new DiagnosisRuleResourceLoader(reader, new HiLogService(new CapturingLogSink()));
      const first = await loader.load();
      if (first.data !== undefined) {
        first.data[0].keywords[0] = 'changed by caller';
      }

      const second = await loader.load();

      expect(second.data?.[0].keywords[0]).assertEqual('JSON.parse');
      expect(reader.getReadCount(DIAGNOSIS_RULE_RESOURCE_NAME)).assertEqual(1);
    });
  });
}
