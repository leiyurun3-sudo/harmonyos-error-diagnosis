/**
 * Synthetic, privacy-safe example used by the diagnosis input flow.
 * It contains no real user, absolute path, account, token or project data.
 */
export interface DiagnosisExample {
  title: string;
  description: string;
  text: string;
}

export const DIAGNOSIS_EXAMPLES: Array<DiagnosisExample> = [
  {
    title: '类型错误',
    description: 'ArkTS 变量类型不匹配',
    text: "ArkTS:ERROR Example.ets:12:5\nType 'string' is not assignable to type 'number'."
  },
  {
    title: '依赖缺失',
    description: 'ohpm 无法找到指定包',
    text: "ohpm ERROR: NOTFOUND package '@ohos/hamock@1.0.1-rc2' not found from registry."
  },
  {
    title: 'JSON 语法',
    description: '配置文件缺少分隔符',
    text: "JSON parse error in module.json5: Expected ',' or '}' at line 18 column 7."
  },
  {
    title: '网络超时',
    description: '接口连接与读取超时',
    text: 'Request failed: connect timeout after 5000ms, HTTP endpoint is unreachable.'
  },
  {
    title: '权限失败',
    description: '系统能力权限未授权',
    text: 'Permission denied: ohos.permission.INTERNET is not declared in module.json5.'
  }
];

export const DIAGNOSIS_EXAMPLE_TEXT: string = DIAGNOSIS_EXAMPLES[0].text;
