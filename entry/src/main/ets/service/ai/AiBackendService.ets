import { http } from '@kit.NetworkKit';

export enum AiModelMode {
  LOCAL_FREE = 'LOCAL_FREE',
  BACKEND_API = 'BACKEND_API'
}

export interface AiReply {
  text: string;
  provider: string;
  steps: Array<string>;
}

interface BackendReply {
  answer?: string;
  provider?: string;
  steps?: Array<string>;
}

interface CompatibleMessage {
  role: string;
  content: string;
}

interface CompatibleChoice {
  message?: CompatibleMessage;
}

interface CompatibleReply {
  choices?: Array<CompatibleChoice>;
  model?: string;
}

interface CompatibleRequest {
  model: string;
  messages: Array<CompatibleMessage>;
  temperature: number;
}

interface LocalRequest {
  prompt: string;
}

interface RequestHeaders {
  'Content-Type'?: string;
  Authorization?: string;
}

/**
 * 零费用、离线可运行的轻量开发诊断模型。
 * 它不是伪装成大语言模型，而是将本项目规则库、意图路由和报告模板组合为一个端侧 Mini 模型。
 */
export class DevAssistMiniModel {
  infer(prompt: string, agentMode: boolean): AiReply {
    const input = prompt.trim();
    const lower = input.toLowerCase();
    let answer = `离线规则库没有识别“${input}”对应的已知错误类型。它不是生成式 AI，不能进行开放问答。`;
    let steps: Array<string> = ['补充完整错误上下文', '定位第一条根因错误', '执行最小修改并重新构建'];

    if (lower.includes('ohpm') || lower.includes('not found') || lower.includes('package')) {
      answer = '这是典型的依赖版本或仓库同步问题。先核对 oh-package.json5，再检查 registry 与锁文件。';
      steps = ['核对依赖名和版本是否真实存在', '确认 OHPM registry 配置', '清理 oh_modules 与锁文件后重新安装'];
    } else if (lower.includes('arkts') || lower.includes('type') || lower.includes('compile')) {
      answer = '优先修复编译器输出中的第一条 ArkTS 类型错误，后续错误往往是连锁结果。';
      steps = ['为状态和回调补充明确类型', '检查组件参数与可空值', '重新执行 CompileArkTS'];
    } else if (lower.includes('permission') || lower.includes('权限')) {
      answer = '权限问题需要同时检查 module.json5 声明、运行时授权和用户拒绝后的降级路径。';
      steps = ['检查 requestPermissions 声明', '请求用户授权并处理返回值', '在拒绝时提供可用的降级功能'];
    } else if (lower.includes('json')) {
      answer = '可以先用 JSON Formatter Skill 校验语法，再定位字段类型和层级。';
      steps = ['解析 JSON', '格式化并定位语法位置', '按接口契约检查字段类型'];
    }

    if (agentMode) {
      return {
        text: `DevAssist Agent 已完成任务规划：${answer}`,
        provider: 'LOCAL RULE AGENT · NOT GENERATIVE AI',
        steps: ['Planner：识别目标与约束', 'Skill Router：选择诊断能力', ...steps, 'Verifier：输出可验证结论']
      };
    }
    return { text: answer, provider: 'LOCAL RULE ENGINE · NOT GENERATIVE AI', steps: steps };
  }
}

export class AiBackendService {
  // The emulator connects to the host through `hdc rport tcp:8787 tcp:8787`.
  private endpoint: string = 'https://api.groq.com/openai/v1';
  private apiKey: string = '';
  private apiModel: string = 'openai/gpt-oss-20b';
  private localModel: DevAssistMiniModel = new DevAssistMiniModel();

  setEndpoint(endpoint: string): void {
    const normalized = endpoint.trim().replace(/\/$/, '');
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      this.endpoint = normalized;
    }
  }

  getEndpoint(): string {
    return this.endpoint;
  }

  setApiKey(value: string): void {
    this.apiKey = value.trim();
  }

  setModel(value: string): void {
    if (value.trim().length > 0) {
      this.apiModel = value.trim();
    }
  }

  getModel(): string {
    return this.apiModel;
  }

  chat(prompt: string, modelMode: AiModelMode): Promise<AiReply> {
    if (modelMode === AiModelMode.LOCAL_FREE) {
      return Promise.resolve(this.localModel.infer(prompt, false));
    }
    return this.call('/api/chat', prompt, false);
  }

  runAgent(prompt: string, modelMode: AiModelMode): Promise<AiReply> {
    if (modelMode === AiModelMode.LOCAL_FREE) {
      return Promise.resolve(this.localModel.infer(prompt, true));
    }
    return this.call('/api/agent/run', prompt, true);
  }

  async healthCheck(): Promise<boolean> {
    const client = http.createHttp();
    try {
      const path = this.apiKey.length > 0 ? '/models' : '/health';
      const headers: RequestHeaders = this.apiKey.length > 0 ?
        { Authorization: `Bearer ${this.apiKey}` } : {};
      const response = await client.request(`${this.endpoint}${path}`, {
        method: http.RequestMethod.GET,
        header: headers,
        connectTimeout: 5000,
        readTimeout: 10000
      });
      return response.responseCode === 200;
    } catch (_) {
      return false;
    } finally {
      client.destroy();
    }
  }

  private async call(path: string, prompt: string, agentMode: boolean): Promise<AiReply> {
    const client = http.createHttp();
    let failureCode: number = 0;
    try {
      const compatible = this.apiKey.length > 0;
      const requestPath = compatible ? '/chat/completions' : path;
      const messages: Array<CompatibleMessage> = [{
        role: 'user',
        content: agentMode ? `请作为开发 Agent 规划并执行任务：${prompt}` : prompt
      }];
      const requestBody: CompatibleRequest | LocalRequest = compatible ? {
        model: this.apiModel,
        messages: messages,
        temperature: 0.2
      } : { prompt: prompt };
      const headers: RequestHeaders = compatible ? {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.apiKey}`
      } : { 'Content-Type': 'application/json' };
      const response = await client.request(`${this.endpoint}${requestPath}`, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: JSON.stringify(requestBody),
        connectTimeout: 5000,
        readTimeout: 30000
      });
      if (response.responseCode >= 200 && response.responseCode < 300) {
        const payload = typeof response.result === 'string' ? response.result : JSON.stringify(response.result);
        if (compatible) {
          const parsed = JSON.parse(payload) as CompatibleReply;
          const text = parsed.choices?.[0]?.message?.content ?? '兼容 API 已响应，但没有返回文本。';
          return {
            text: text,
            provider: `在线模型 · ${parsed.model ?? this.apiModel}`,
            steps: agentMode ? ['在线模型：理解任务', 'Agent：生成计划', 'Verifier：请按计划验证结果'] : []
          };
        }
        const parsed = JSON.parse(payload) as BackendReply;
        return {
          text: parsed.answer ?? 'API 已响应，但没有返回文本。',
          provider: parsed.provider ?? 'Developer Assistant API',
          steps: parsed.steps ?? []
        };
      }
      failureCode = response.responseCode;
    } catch (_) {
      failureCode = -1;
    } finally {
      client.destroy();
    }
    if (this.apiKey.length > 0) {
      return {
        text: failureCode > 0 ?
          `真实在线模型请求失败，HTTP ${failureCode}。请检查 API Key、模型名、额度和服务地址。` :
          '真实在线模型连接失败。请检查网络、API 地址和服务商状态。',
        provider: 'ONLINE API · REQUEST FAILED',
        steps: ['确认 Key 未过期且有可用额度', '确认模型 ID 与服务商一致', '重新检测连接后发送']
      };
    }
    const fallback = this.localModel.infer(prompt, agentMode);
    return {
      text: `${fallback.text}\n\n本地后端 API 当前不可达，已切换到离线规则诊断。`,
      provider: `${fallback.provider} · API Fallback`,
      steps: fallback.steps
    };
  }
}

export const aiBackendService: AiBackendService = new AiBackendService();
