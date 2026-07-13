import diagnosisRuleResource from '../../main/resources/rawfile/diagnosis_rules_v1.json';
import httpStatusResource from '../../main/resources/rawfile/http_status_v1.json';

export function createValidDiagnosisResourceText(): string {
  return JSON.stringify(diagnosisRuleResource);
}

export function createInvalidDiagnosisJsonText(): string {
  return '{"schemaName":"diagnosis-rules"';
}

export function createUnsupportedDiagnosisSchemaText(): string {
  return createValidDiagnosisResourceText()
    .replace('"schemaName":"diagnosis-rules"', '"schemaName":"unsupported-rules"');
}

export function createUnsupportedDiagnosisVersionText(): string {
  return createValidDiagnosisResourceText()
    .replace('"resourceVersion":"1.0.0"', '"resourceVersion":"2.0.0"');
}

export function createDiagnosisTextWithOneMissingField(): string {
  return createValidDiagnosisResourceText()
    .replace('"summaryTemplate":"JSON格式或响应内容可能不符合标准JSON语法。",', '');
}

export function createDiagnosisTextWithDuplicateRuleId(): string {
  return createValidDiagnosisResourceText()
    .replace('"ruleId":"http_401_authentication"', '"ruleId":"json_parse_error"');
}

export function createDiagnosisTextWithInvalidPattern(): string {
  return createValidDiagnosisResourceText()
    .replace('"patterns":["SyntaxError:\\\\s*Unexpected token","JSON\\\\.parse"]', '"patterns":["["]');
}

export function createDiagnosisTextWithTwoInvalidRules(): string {
  return createDiagnosisTextWithOneMissingField()
    .replace('"errorType":"HTTP认证错误"', '"errorType":""');
}

export function createValidHttpStatusResourceText(): string {
  return JSON.stringify(httpStatusResource);
}

export function createInvalidHttpStatusJsonText(): string {
  return '{"schemaName":"http-status"';
}

export function createUnsupportedHttpSchemaText(): string {
  return createValidHttpStatusResourceText()
    .replace('"schemaVersion":1', '"schemaVersion":2');
}

export function createHttpTextWithMissingField(): string {
  return createValidHttpStatusResourceText()
    .replace('"description":"请求已成功完成；具体结果取决于所使用的HTTP方法。",', '');
}

export function createHttpTextWithDuplicateCode(): string {
  return createValidHttpStatusResourceText().replace('"code":201', '"code":200');
}

export function createHttpTextWithOutOfRangeCode(): string {
  return createValidHttpStatusResourceText().replace('"code":200', '"code":99');
}

export function createPrivacyTextFixture(): string {
  return 'Synthetic privacy notice: local processing only.';
}
