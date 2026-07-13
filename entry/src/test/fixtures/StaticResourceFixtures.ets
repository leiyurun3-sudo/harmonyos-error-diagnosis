export interface RuleTraceFixture {
  ruleId: string;
  sampleMarker: string;
  sourceSection: string;
}

export interface HttpStatusNameFixture {
  code: number;
  name: string;
}

export const STATIC_RESOURCE_SCHEMA_VERSION: number = 1;
export const STATIC_RESOURCE_VERSION: string = '1.0.0';

export function createRequiredRuleIdsFixture(): Array<string> {
  return [
    'json_parse_error',
    'http_401_authentication',
    'http_403_authorization',
    'http_404_resource',
    'http_5xx_service',
    'network_timeout',
    'permission_denied',
    'null_reference',
    'arkts_compile',
    'hvigor_build',
    'ohpm_dependency',
    'generic_unclassified'
  ];
}

export function createRuleTraceFixtures(): Array<RuleTraceFixture> {
  return [
    {
      ruleId: 'arkts_compile',
      sampleMarker: 'arkts-no-type-query',
      sourceSection: 'T0-错误样例说明/样例A'
    },
    {
      ruleId: 'hvigor_build',
      sampleMarker: '00303217',
      sourceSection: 'T0-错误样例说明/样例B'
    },
    {
      ruleId: 'ohpm_dependency',
      sampleMarker: '00608005',
      sourceSection: 'T0-错误样例说明/样例C'
    }
  ];
}

export function createRequiredHttpStatusCodesFixture(): Array<number> {
  return [200, 201, 204, 400, 401, 403, 404, 408, 409, 429, 500, 502, 503, 504];
}

export function createHttpStatusNameFixtures(): Array<HttpStatusNameFixture> {
  return [
    { code: 200, name: 'OK' },
    { code: 201, name: 'Created' },
    { code: 204, name: 'No Content' },
    { code: 400, name: 'Bad Request' },
    { code: 401, name: 'Unauthorized' },
    { code: 403, name: 'Forbidden' },
    { code: 404, name: 'Not Found' },
    { code: 408, name: 'Request Timeout' },
    { code: 409, name: 'Conflict' },
    { code: 429, name: 'Too Many Requests' },
    { code: 500, name: 'Internal Server Error' },
    { code: 502, name: 'Bad Gateway' },
    { code: 503, name: 'Service Unavailable' },
    { code: 504, name: 'Gateway Timeout' }
  ];
}
