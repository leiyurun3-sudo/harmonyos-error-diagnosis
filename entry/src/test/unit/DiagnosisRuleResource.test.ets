import { describe, expect, it } from '@ohos/hypium';
import diagnosisRuleResource from '../../main/resources/rawfile/diagnosis_rules_v1.json';
import { DiagnosisRule } from '../../main/ets/model/DiagnosisModels';
import {
  createRequiredRuleIdsFixture,
  createRuleTraceFixtures,
  RuleTraceFixture,
  STATIC_RESOURCE_SCHEMA_VERSION,
  STATIC_RESOURCE_VERSION
} from '../fixtures/StaticResourceFixtures';

interface DiagnosisRuleResource {
  schemaName: string;
  schemaVersion: number;
  resourceVersion: string;
  rules: Array<DiagnosisRule>;
}

function findRule(rules: Array<DiagnosisRule>, ruleId: string): DiagnosisRule | undefined {
  for (let index: number = 0; index < rules.length; index++) {
    if (rules[index].ruleId === ruleId) {
      return rules[index];
    }
  }
  return undefined;
}

export default function diagnosisRuleResourceTest() {
  describe('DiagnosisRuleResource', () => {
    const resource: DiagnosisRuleResource = diagnosisRuleResource;

    it('uses the documented schema and resource versions', 0, () => {
      expect(resource.schemaName).assertEqual('diagnosis-rules');
      expect(resource.schemaVersion).assertEqual(STATIC_RESOURCE_SCHEMA_VERSION);
      expect(resource.resourceVersion).assertEqual(STATIC_RESOURCE_VERSION);
      expect(resource.rules.length >= 12).assertTrue();
    });

    it('contains every required P0 rule category', 0, () => {
      const requiredRuleIds = createRequiredRuleIdsFixture();

      for (let index: number = 0; index < requiredRuleIds.length; index++) {
        expect(findRule(resource.rules, requiredRuleIds[index]) !== undefined).assertTrue();
      }
    });

    it('keeps rule identifiers unique', 0, () => {
      let duplicateCount: number = 0;
      for (let left: number = 0; left < resource.rules.length; left++) {
        for (let right: number = left + 1; right < resource.rules.length; right++) {
          if (resource.rules[left].ruleId === resource.rules[right].ruleId) {
            duplicateCount++;
          }
        }
      }

      expect(duplicateCount).assertEqual(0);
    });

    it('provides complete report material for every rule', 0, () => {
      for (let index: number = 0; index < resource.rules.length; index++) {
        const rule = resource.rules[index];
        expect(rule.ruleId.trim().length > 0).assertTrue();
        expect(rule.errorType.trim().length > 0).assertTrue();
        expect(rule.summaryTemplate.trim().length > 0).assertTrue();
        expect(rule.causes.length >= 2).assertTrue();
        expect(rule.steps.length >= 3).assertTrue();
        expect(Number.isFinite(rule.priority) && rule.priority >= 0).assertTrue();
        expect(rule.version).assertEqual(STATIC_RESOURCE_VERSION);
      }
    });

    it('contains only compilable regular-expression patterns', 0, () => {
      for (let ruleIndex: number = 0; ruleIndex < resource.rules.length; ruleIndex++) {
        const patterns = resource.rules[ruleIndex].patterns;
        for (let patternIndex: number = 0; patternIndex < patterns.length; patternIndex++) {
          const expression = new RegExp(patterns[patternIndex], 'i');
          expect(expression.source.length > 0).assertTrue();
        }
      }
    });

    it('traces ArkTS Hvigor and OHPM rules to sanitized T0 samples', 0, () => {
      const traces: Array<RuleTraceFixture> = createRuleTraceFixtures();

      for (let index: number = 0; index < traces.length; index++) {
        const rule = findRule(resource.rules, traces[index].ruleId);
        expect(rule !== undefined).assertTrue();
        expect(JSON.stringify(rule).includes(traces[index].sampleMarker)).assertTrue();
        expect(traces[index].sourceSection.startsWith('T0-错误样例说明/')).assertTrue();
      }
    });

    it('uses one cautious lowest-priority generic fallback', 0, () => {
      const fallback = findRule(resource.rules, 'generic_unclassified');
      expect(fallback !== undefined).assertTrue();
      expect(fallback?.keywords.length).assertEqual(0);
      expect(fallback?.patterns.length).assertEqual(0);
      expect(fallback?.priority).assertEqual(0);
      expect(fallback?.summaryTemplate.includes('未分类')).assertTrue();
    });

    it('does not share mutable collections between rules', 0, () => {
      expect(resource.rules[0].keywords === resource.rules[1].keywords).assertFalse();
      expect(resource.rules[0].patterns === resource.rules[1].patterns).assertFalse();
      expect(resource.rules[0].causes === resource.rules[1].causes).assertFalse();
      expect(resource.rules[0].steps === resource.rules[1].steps).assertFalse();
    });
  });
}
