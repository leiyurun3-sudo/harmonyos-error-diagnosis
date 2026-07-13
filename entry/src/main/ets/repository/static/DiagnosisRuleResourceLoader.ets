import {
  DIAGNOSIS_RULE_RESOURCE_NAME,
  DIAGNOSIS_RULE_SCHEMA_NAME,
  STATIC_RESOURCE_SCHEMA_VERSION,
  STATIC_RESOURCE_VERSION
} from '../../constants/StaticResources';
import { ErrorCode } from '../../constants/ErrorCodes';
import { DiagnosisRule } from '../../model/DiagnosisModels';
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
import { RawResourceReader } from '../../storage/static/RawResourceStore';

interface DiagnosisRuleDocument {
  schemaName: string;
  schemaVersion: number;
  resourceVersion: string;
  rules: Array<DiagnosisRule>;
}

function isNonEmptyText(value: string): boolean {
  return typeof value === 'string' && value.trim().length > 0;
}

function isStringArray(value: Array<string>, mustNotBeEmpty: boolean): boolean {
  if (!Array.isArray(value) || (mustNotBeEmpty && value.length === 0)) {
    return false;
  }
  for (let index: number = 0; index < value.length; index++) {
    if (!isNonEmptyText(value[index])) {
      return false;
    }
  }
  return true;
}

function hasValidPatterns(patterns: Array<string>): boolean {
  if (!isStringArray(patterns, false)) {
    return false;
  }
  for (let index: number = 0; index < patterns.length; index++) {
    try {
      new RegExp(patterns[index]);
    } catch (_) {
      return false;
    }
  }
  return true;
}

function isValidRule(rule: DiagnosisRule): boolean {
  if (!isNonEmptyText(rule.ruleId) || !isNonEmptyText(rule.errorType) ||
    !Number.isFinite(rule.priority) || !Number.isInteger(rule.priority) ||
    !isNonEmptyText(rule.summaryTemplate) || !isNonEmptyText(rule.version) ||
    !isStringArray(rule.keywords, false) || !hasValidPatterns(rule.patterns) ||
    !isStringArray(rule.causes, true) || !isStringArray(rule.steps, true) ||
    (rule.riskNotice !== undefined && !isNonEmptyText(rule.riskNotice))) {
    return false;
  }
  return rule.ruleId === 'generic_unclassified' || rule.keywords.length + rule.patterns.length > 0;
}

function copyRule(rule: DiagnosisRule): DiagnosisRule {
  const copied: DiagnosisRule = {
    ruleId: rule.ruleId,
    errorType: rule.errorType,
    keywords: rule.keywords.slice(),
    patterns: rule.patterns.slice(),
    priority: rule.priority,
    summaryTemplate: rule.summaryTemplate,
    causes: rule.causes.slice(),
    steps: rule.steps.slice(),
    version: rule.version
  };
  if (rule.riskNotice !== undefined) {
    copied.riskNotice = rule.riskNotice;
  }
  return copied;
}

function copyRules(rules: Array<DiagnosisRule>): Array<DiagnosisRule> {
  const copied: Array<DiagnosisRule> = [];
  for (let index: number = 0; index < rules.length; index++) {
    copied.push(copyRule(rules[index]));
  }
  return copied;
}

/** Loads, validates and caches the versioned diagnosis rule resource. */
export class DiagnosisRuleResourceLoader {
  private reader: RawResourceReader;
  private logger: HiLogService;
  private cache?: Array<DiagnosisRule>;

  constructor(reader: RawResourceReader, logger: HiLogService) {
    this.reader = reader;
    this.logger = logger;
  }

  async load(): Promise<AppResult<Array<DiagnosisRule>>> {
    if (this.cache !== undefined) {
      return createSuccessResult<Array<DiagnosisRule>>(copyRules(this.cache));
    }
    const textResult = await this.reader.readText(DIAGNOSIS_RULE_RESOURCE_NAME);
    if (!textResult.success || textResult.data === undefined) {
      if (textResult.error !== undefined) {
        return createFailureResult<Array<DiagnosisRule>>(textResult.error);
      }
      return this.failure('read', 'RAWFILE_READ');
    }

    let document: DiagnosisRuleDocument;
    try {
      document = JSON.parse(textResult.data) as DiagnosisRuleDocument;
    } catch (_) {
      return this.failure('parse', 'JSON_PARSE');
    }
    try {
      if (document.schemaName !== DIAGNOSIS_RULE_SCHEMA_NAME ||
        document.schemaVersion !== STATIC_RESOURCE_SCHEMA_VERSION) {
        return this.failure('schema', 'SCHEMA_UNSUPPORTED');
      }
      if (document.resourceVersion !== STATIC_RESOURCE_VERSION) {
        return this.failure('version', 'RESOURCE_VERSION_UNSUPPORTED');
      }
      if (!Array.isArray(document.rules) || document.rules.length === 0) {
        return this.failure('validate', 'RESOURCE_VALIDATION');
      }

      const validRules: Array<DiagnosisRule> = [];
      const identifiers: Array<string> = [];
      let invalidCount: number = 0;
      for (let index: number = 0; index < document.rules.length; index++) {
        const rule = document.rules[index];
        if (isNonEmptyText(rule.ruleId) && identifiers.includes(rule.ruleId)) {
          return this.failure('validate', 'DUPLICATE_IDENTIFIER');
        }
        if (isNonEmptyText(rule.ruleId)) {
          identifiers.push(rule.ruleId);
        }
        if (!isValidRule(rule)) {
          invalidCount++;
          continue;
        }
        validRules.push(copyRule(rule));
      }
      if (invalidCount > 1 || validRules.length === 0) {
        return this.failure('validate', 'RESOURCE_VALIDATION');
      }
      if (invalidCount === 1) {
        this.logger.log(LogLevel.WARN, {
          domain: 'static_resource',
          event: 'rule_isolated',
          errorCode: ErrorCode.RULE_RESOURCE_FAILED,
          metadata: [
            { key: LogMetadataKey.RESOURCE_NAME, value: DIAGNOSIS_RULE_RESOURCE_NAME },
            { key: LogMetadataKey.STAGE, value: 'validate' },
            { key: LogMetadataKey.RECORD_COUNT, value: 1 }
          ]
        });
      }
      this.cache = copyRules(validRules);
      return createSuccessResult<Array<DiagnosisRule>>(copyRules(this.cache));
    } catch (_) {
      return this.failure('validate', 'RESOURCE_VALIDATION');
    }
  }

  private failure(stage: string, causeType: string): AppResult<Array<DiagnosisRule>> {
    this.logger.log(LogLevel.ERROR, {
      domain: 'static_resource',
      event: 'diagnosis_rules_failed',
      errorCode: ErrorCode.RULE_RESOURCE_FAILED,
      metadata: [
        { key: LogMetadataKey.RESOURCE_NAME, value: DIAGNOSIS_RULE_RESOURCE_NAME },
        { key: LogMetadataKey.STAGE, value: stage }
      ]
    });
    return createFailureResult<Array<DiagnosisRule>>({
      code: ErrorCode.RULE_RESOURCE_FAILED,
      message: '内置诊断规则暂时不可用。',
      retryable: false,
      causeType: causeType
    });
  }
}
