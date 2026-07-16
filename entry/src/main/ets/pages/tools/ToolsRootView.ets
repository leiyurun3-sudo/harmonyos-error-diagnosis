import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { uiMaterial } from '@kit.ArkUI';
import { InteractiveDiagnosticCard } from '../../components/experience/InteractiveDiagnosticCard';
import {
  aiBackendService,
  AiModelMode,
  AiReply
} from '../../service/ai/AiBackendService';
import { HarmonyAgentAdapter } from '../../service/ai/HarmonyAgentAdapter';
import { VisionAiAdapter } from '../../service/ai/VisionAiAdapter';
import {
  closeFlashControlWindow,
  openFlashControlWindow
} from '../../service/window/WindowRuntime';
import { AppStateStore } from '../../store/AppStateStore';
import { EffectiveTheme, getThemePalette, ThemePalette } from '../../theme/ThemeModels';

@Component
export struct ToolsRootView {
  @Consume('appState')
  appState: AppStateStore;
  @State private activeTab: number = 0;
  @State private modelMode: AiModelMode = AiModelMode.BACKEND_API;
  @State private prompt: string = 'HarmonyOS 工程出现 ohpm package not found，应该怎样排查？';
  @State private answer: string = '填写 API Key 后，发送内容会由真实在线模型生成。';
  @State private provider: string = 'ONLINE API · WAITING FOR KEY';
  @State private steps: Array<string> = [];
  @State private busy: boolean = false;
  @State private apiEndpoint: string = 'https://api.groq.com/openai/v1';
  @State private apiKey: string = '';
  @State private apiModel: string = 'openai/gpt-oss-20b';
  @State private apiStatus: string = '等待填写 API Key 并检测真实模型连接';
  @State private agentId: string = '';
  @State private agentSupport: string = '输入平台注册的 Agent ID 后可检测系统能力';
  @State private skillResult: string = '选择一个 Skill 执行';
  @State private visionResult: string = '选择报错截图后，使用 Core Vision Kit 在设备端提取文字。';
  @State private jsonInput: string = '{"platform":"HarmonyOS","api":26}';
  @State private jsonOutput: string = '';
  @State private httpCode: string = '404';
  @State private httpResult: string = '404 Not Found · 资源不存在';
  @State private windowStatus: string = '尚未创建子窗';
  private readonly vision: VisionAiAdapter = new VisionAiAdapter();
  private readonly agent: HarmonyAgentAdapter = new HarmonyAgentAdapter();

  aboutToAppear(): void {
    this.apiEndpoint = aiBackendService.getEndpoint();
    this.apiModel = aiBackendService.getModel();
    this.checkApi();
  }

  private palette(): ThemePalette {
    return getThemePalette(this.appState.effectiveTheme, this.appState.accentTheme);
  }

  private isDark(): boolean {
    return this.appState.effectiveTheme === EffectiveTheme.DARK;
  }

  private glass(): string {
    return this.isDark() ? '#C20B1628' : '#F2FFFFFF';
  }

  private line(): string {
    return this.isDark() ? '#32FFFFFF' : '#1A0F2B55';
  }

  private immersiveMaterial(color: string): uiMaterial.ImmersiveMaterial {
    return new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.THIN,
      materialColor: this.isDark() ? '#24152B45' : '#22FFFFFF',
      colorInvert: false,
      applyShadow: true,
      interactive: true,
      lightEffect: { color: color }
    });
  }

  private async ask(agentMode: boolean): Promise<void> {
    if (this.busy || this.prompt.trim().length === 0) {
      return;
    }
    if (this.modelMode === AiModelMode.BACKEND_API && this.apiKey.trim().length === 0) {
      this.provider = 'ONLINE API · NEED KEY';
      this.answer = '请先填写真实模型的 API Key。未填写 Key 时不会伪装成在线模型，也不会返回本地固定回复。';
      this.steps = ['选择 OpenAI 兼容服务', '填写 API 地址、API Key 和模型名', '检测连接后重新发送'];
      return;
    }
    aiBackendService.setEndpoint(this.apiEndpoint);
    aiBackendService.setApiKey(this.apiKey);
    aiBackendService.setModel(this.apiModel);
    this.busy = true;
    this.answer = agentMode ? 'Agent 正在规划与调用 Skill…' : '模型正在分析…';
    const reply: AiReply = agentMode ?
      await aiBackendService.runAgent(this.prompt, this.modelMode) :
      await aiBackendService.chat(this.prompt, this.modelMode);
    this.answer = reply.text;
    this.provider = reply.provider;
    this.steps = reply.steps;
    this.busy = false;
  }

  private selectOnlineApi(): void {
    this.modelMode = AiModelMode.BACKEND_API;
    if (this.apiEndpoint.startsWith('http://127.0.0.1')) {
      this.apiEndpoint = 'https://api.groq.com/openai/v1';
      this.apiModel = 'openai/gpt-oss-20b';
    }
    this.provider = 'ONLINE API · WAITING FOR KEY';
    this.answer = '填写 API Key 后，发送内容会由所选真实在线模型生成。';
    this.apiStatus = '等待填写 API Key 并检测真实模型连接';
    this.steps = [];
  }

  private async checkApi(): Promise<void> {
    aiBackendService.setEndpoint(this.apiEndpoint);
    aiBackendService.setApiKey(this.apiKey);
    aiBackendService.setModel(this.apiModel);
    this.apiStatus = '检测中…';
    this.apiStatus = await aiBackendService.healthCheck() ?
      (this.apiKey.trim().length > 0 ? '在线模型已连接，可发送真实请求' : '本地 API 在线，可正常调用') :
      'API 不可达：请启动本地后端或检查 API 地址、密钥和网络';
  }

  private async checkAgentSupport(): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;
    this.agentSupport = '正在检测 Agent Framework Kit…';
    const supported = await this.agent.isSupported(context, this.agentId);
    this.agentSupport = supported ? '系统支持该 Agent，可接入小艺入口' :
      '当前 Agent ID 未注册或设备暂不支持；本地 Agent 仍可演示';
  }

  private async runSkill(name: string): Promise<void> {
    if (name === 'JSON Formatter') {
      try {
        this.skillResult = `JSON Formatter 执行成功\n${JSON.stringify(JSON.parse(this.jsonInput) as object, null, 2)}`;
      } catch (_) {
        this.skillResult = 'JSON Formatter：输入格式错误，请检查引号、逗号和括号。';
      }
    } else if (name === 'Error Triage') {
      const reply = await aiBackendService.chat(this.prompt, AiModelMode.LOCAL_FREE);
      this.skillResult = `Error Triage 执行成功\n${reply.text}\n${reply.steps.join('\n')}`;
    } else if (name === 'Report Writer') {
      const reply = await aiBackendService.chat(this.prompt, AiModelMode.LOCAL_FREE);
      this.skillResult = `诊断报告\n现象：${this.prompt.trim()}\n分析：${reply.text}\n处理步骤：${reply.steps.join('；')}\n验证：重新执行失败操作并确认首个错误消失。`;
    } else {
      const redacted = this.prompt
        .replace(/[A-Za-z]:\\[^\s]+/g, '[本地路径]')
        .replace(/[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}/g, '[邮箱]')
        .replace(/(token|api[_-]?key|password)\s*[:=]\s*\S+/gi, '$1=[已隐藏]');
      this.skillResult = `Privacy Redactor 执行成功\n${redacted}`;
    }
  }

  private formatJson(): void {
    try {
      this.jsonOutput = JSON.stringify(JSON.parse(this.jsonInput) as object, null, 2);
    } catch (_) {
      this.jsonOutput = 'JSON 格式错误，请检查引号、逗号和括号。';
    }
  }

  private lookupHttp(): void {
    const code = this.httpCode.trim();
    if (code === '200') this.httpResult = '200 OK · 请求成功';
    else if (code === '201') this.httpResult = '201 Created · 资源创建成功';
    else if (code === '204') this.httpResult = '204 No Content · 成功但没有响应正文';
    else if (code === '400') this.httpResult = '400 Bad Request · 请求参数错误';
    else if (code === '401') this.httpResult = '401 Unauthorized · 缺少有效凭证';
    else if (code === '403') this.httpResult = '403 Forbidden · 权限不足';
    else if (code === '404') this.httpResult = '404 Not Found · 资源或路由不存在';
    else if (code === '408') this.httpResult = '408 Request Timeout · 请求超时';
    else if (code === '429') this.httpResult = '429 Too Many Requests · 请求频率过高';
    else if (code === '500') this.httpResult = '500 Internal Server Error · 服务端异常';
    else if (code === '502') this.httpResult = '502 Bad Gateway · 上游服务响应异常';
    else if (code === '503') this.httpResult = '503 Service Unavailable · 服务暂不可用';
    else this.httpResult = `${code} · 未收录状态码，请核对 HTTP 标准定义`;
  }

  private async chooseImage(): Promise<void> {
    this.visionResult = '正在打开系统图片选择器…';
    try {
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const selected = await new photoAccessHelper.PhotoViewPicker().select(options);
      if (selected.photoUris.length === 0) {
        this.visionResult = '没有选择图片。';
        return;
      }
      this.visionResult = '正在调用 Core Vision Kit OCR…';
      const source = image.createImageSource(selected.photoUris[0]);
      const pixelMap = await source.createPixelMap();
      this.visionResult = await this.vision.recognize(pixelMap);
      pixelMap.release();
      source.release();
    } catch (_) {
      this.visionResult = '图片选择或视觉服务不可用；请先向模拟器导入一张报错截图。';
    }
  }

  private async openWindow(): Promise<void> {
    this.windowStatus = '正在创建应用子窗…';
    this.windowStatus = await openFlashControlWindow();
  }

  private async closeWindow(): Promise<void> {
    this.windowStatus = '正在关闭闪控子窗…';
    this.windowStatus = await closeFlashControlWindow();
  }

  @Builder
  private tab(label: string, index: number) {
    Button(label)
      .height(42).fontSize(11).fontWeight(FontWeight.Bold)
      .fontColor(this.activeTab === index ? '#FFFFFF' : this.palette().secondaryText)
      .backgroundColor(this.activeTab === index ? '#5B8CFF' : this.glass())
      .border({ width: 1, color: this.activeTab === index ? '#8AB4FF' : this.line() })
      .borderRadius(12)
      .onClick(() => this.activeTab = index)
  }

  @Builder
  private titleBlock() {
    Column({ space: 5 }) {
      Text('智能开发中枢').width('100%').fontSize(30 * this.appState.contentFontMultiplier)
        .fontWeight(FontWeight.Bold).fontColor(this.palette().primaryText)
        .fontVariations([{ axis: 'wght', value: 790 }])
      Text('AI · Agent · Skill · Vision · Multi-window')
        .width('100%').fontSize(13).fontColor(this.palette().secondaryText)
      Row({ space: 7 }) {
        Text('API 26').fontSize(10).fontWeight(FontWeight.Bold).fontColor('#5CE1D0')
        Text('LOCAL FIRST').fontSize(10).fontWeight(FontWeight.Bold).fontColor('#8AB4FF')
        Text('REAL MODEL API').fontSize(10).fontWeight(FontWeight.Bold).fontColor('#FFB36B')
      }.width('100%')
    }.width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  private responseCard() {
    Column({ space: 10 }) {
      Row() {
        Text(this.provider).fontSize(10).fontWeight(FontWeight.Bold).fontColor('#5CE1D0')
        Blank()
        if (this.busy) {
          LoadingProgress().width(22).height(22).color('#5B8CFF')
        }
      }.width('100%')
      Text(this.answer).width('100%').fontSize(14).lineHeight(23).fontColor(this.palette().primaryText)
      ForEach(this.steps, (step: string, index: number) => {
        Row({ space: 10 }) {
          Text(`${index + 1}`).width(24).height(24).textAlign(TextAlign.Center).fontSize(11)
            .fontColor('#FFFFFF').backgroundColor('#5B8CFF').borderRadius(8)
          Text(step).layoutWeight(1).fontSize(13).fontColor(this.palette().secondaryText)
        }.width('100%')
      }, (step: string, index: number): string => `${index}-${step}`)
    }
    .width('100%').padding(16).backgroundColor(this.glass())
    .systemMaterial(this.immersiveMaterial('#8AB4FF'))
    .border({ width: 1, color: this.line() }).borderRadius(20)
  }

  @Builder
  private aiPanel(agentMode: boolean) {
    Column({ space: 13 }) {
      Row({ space: 8 }) {
        Button('离线规则诊断').layoutWeight(1).height(44)
          .fontColor('#FFFFFFFF')
          .backgroundColor(this.modelMode === AiModelMode.LOCAL_FREE ? '#12A69A' : '#24364E')
          .onClick(() => {
            this.modelMode = AiModelMode.LOCAL_FREE;
            this.provider = 'LOCAL RULE ENGINE · NOT GENERATIVE AI';
            this.answer = '这是离线规则诊断，不是生成式 AI。它只识别内置错误类型；通用问答请选择在线 API 并填写 Key。';
            this.steps = [];
          })
        Button('在线 API').layoutWeight(1).height(44)
          .fontColor('#FFFFFFFF')
          .backgroundColor(this.modelMode === AiModelMode.BACKEND_API ? '#5B8CFF' : '#24364E')
          .onClick(() => this.selectOnlineApi())
      }.width('100%')
      if (this.modelMode === AiModelMode.BACKEND_API) {
        TextInput({ text: this.apiEndpoint, placeholder: 'API 地址，例如 https://api.groq.com/openai/v1' })
          .height(46).fontColor(this.palette().primaryText)
          .onChange((value: string) => this.apiEndpoint = value)
        TextInput({ text: this.apiKey, placeholder: 'API Key：输入后调用真实在线模型' })
          .height(46).fontColor(this.palette().primaryText)
          .onChange((value: string) => this.apiKey = value)
        TextInput({ text: this.apiModel, placeholder: '模型名，例如 openai/gpt-oss-20b' })
          .height(46).fontColor(this.palette().primaryText)
          .onChange((value: string) => this.apiModel = value)
        Button('检测真实模型连接').width('100%').height(42).fontColor('#FFFFFFFF')
          .backgroundColor('#087F5B').onClick(() => this.checkApi())
        Text(this.apiStatus).width('100%').fontSize(12)
          .fontColor(this.apiStatus.includes('已连接') ? '#087F5B' : '#B42318')
        Text('兼容 OpenAI Chat Completions。Key 只保存在本次运行内，不写入本地文件。')
          .width('100%').fontSize(11).lineHeight(18).fontColor(this.palette().secondaryText)
      }
      TextArea({ text: this.prompt, placeholder: '输入技术问题或 Agent 任务' })
        .height(140).fontSize(14).fontColor(this.palette().primaryText)
        .backgroundColor(this.isDark() ? '#A607111F' : '#F7FFFFFF')
        .border({ width: 1, color: this.line() }).borderRadius(16).padding(12)
        .onChange((value: string) => this.prompt = value)
      Button(agentMode ? '运行 Agent' : '发送给 AI').width('100%').height(50)
        .backgroundColor(agentMode ? '#12A69A' : '#5B8CFF').borderRadius(14)
        .enabled(!this.busy).onClick(() => this.ask(agentMode))
      if (agentMode) {
        TextInput({ text: this.agentId, placeholder: '可选：填写小艺平台 Agent ID' })
          .height(46).onChange((value: string) => this.agentId = value)
        Button('检测系统 Agent 能力').width('100%').height(44).backgroundColor('#24364E')
          .onClick(() => this.checkAgentSupport())
        Text(this.agentSupport).width('100%').fontSize(12).fontColor(this.palette().secondaryText)
      }
    }
    .width('100%').padding(17).backgroundColor(this.glass())
    .systemMaterial(this.immersiveMaterial(agentMode ? '#5CE1D0' : '#8AB4FF'))
    .border({ width: 1, color: this.line() }).borderRadius(22)
    this.responseCard()
  }

  @Builder
  private skillPanel() {
    Column({ space: 12 }) {
      Text('可执行 Skill 中心').width('100%').fontSize(21).fontWeight(FontWeight.Bold)
        .fontColor(this.palette().primaryText)
      Text('Skill 使用统一输入输出协议，可被本地 Agent 编排；正式注册后可由系统智能入口分发。')
        .width('100%').fontSize(13).lineHeight(21).fontColor(this.palette().secondaryText)
      Button('JSON Formatter').width('100%').height(46).backgroundColor('#5B8CFF')
        .onClick(() => this.runSkill('JSON Formatter'))
      Button('Error Triage').width('100%').height(46).backgroundColor('#12A69A')
        .onClick(() => this.runSkill('Error Triage'))
      Button('Report Writer').width('100%').height(46).backgroundColor('#F79009')
        .onClick(() => this.runSkill('Report Writer'))
      Button('Privacy Redactor').width('100%').height(46).backgroundColor('#7A5AF8')
        .onClick(() => this.runSkill('Privacy Redactor'))
      Text(this.skillResult).width('100%').fontSize(13).lineHeight(21).fontFamily('monospace')
        .fontColor(this.palette().primaryText).copyOption(CopyOptions.LocalDevice)
        .padding(14).backgroundColor(this.isDark() ? '#07111F' : '#EEF3FA').borderRadius(14)
    }
    .width('100%').padding(17).backgroundColor(this.glass())
    .systemMaterial(this.immersiveMaterial('#FFB36B')).borderRadius(22)
  }

  @Builder
  private visionPanel() {
    Column({ space: 14 }) {
      Text('视觉 AI 工作台').width('100%').fontSize(21).fontWeight(FontWeight.Bold)
        .fontColor(this.palette().primaryText)
      Text('系统安全图片选择器 + Core Vision Kit OCR，可提取截图日志并继续本地诊断。')
        .width('100%').fontSize(13).lineHeight(22).fontColor(this.palette().secondaryText)
      Button('选择报错截图并识别').width('100%').height(52).backgroundColor('#F79009').borderRadius(14)
        .onClick(() => this.chooseImage())
      Text(this.visionResult).width('100%').constraintSize({ minHeight: 150 }).fontSize(14).lineHeight(22)
        .fontColor(this.palette().primaryText).copyOption(CopyOptions.LocalDevice)
        .padding(15).backgroundColor(this.isDark() ? '#07111F' : '#EEF3FA').borderRadius(16)
      Text('隐私：图片由系统选择器授权，OCR 默认在设备端完成，不上传代码和日志。')
        .fontSize(11).fontColor('#5CE1D0')
    }
    .width('100%').padding(17).backgroundColor(this.glass())
    .systemMaterial(this.immersiveMaterial('#FFB36B')).borderRadius(22)
  }

  @Builder
  private windowPanel() {
    Column({ space: 16 }) {
      Text('多窗与互动体验').width('100%').fontSize(21).fontWeight(FontWeight.Bold)
        .fontColor(this.palette().primaryText)
      InteractiveDiagnosticCard()
      Divider().color(this.line())
      Text('闪控窗').width('100%').fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.palette().primaryText)
      Text('使用 WindowStage 创建真实应用子窗，展示持续诊断进度；支持窗口拖动和独立内容。')
        .width('100%').fontSize(13).lineHeight(21).fontColor(this.palette().secondaryText)
      Row({ space: 12 }) {
        Button('打开独立诊断窗口').layoutWeight(1).height(50).fontColor('#FFFFFFFF')
          .backgroundColor('#5B8CFF').borderRadius(14)
          .linearGradient({ angle: 90, colors: [['#3977F6', 0], ['#7658E8', 1]] })
          .onClick(() => this.openWindow())
        Button('关闭独立诊断窗口').layoutWeight(1).height(50).fontColor('#FFFFFFFF')
          .backgroundColor('#B42318').borderRadius(14)
          .linearGradient({ angle: 90, colors: [['#C53030', 0], ['#F06A3C', 1]] })
          .onClick(() => this.closeWindow())
      }.width('100%')
      Text(this.windowStatus).width('100%').fontSize(12).fontColor('#5CE1D0')
      Text('说明：系统级闪控球/全局悬浮窗需要华为平台能力开通；本项目实现了可编译、可运行的应用子窗适配层。')
        .width('100%').fontSize(11).lineHeight(19).fontColor(this.palette().secondaryText)
    }
    .width('100%').padding(17).backgroundColor(this.glass())
    .systemMaterial(this.immersiveMaterial('#5CE1D0')).borderRadius(22)
  }

  @Builder
  private apiToolsPanel() {
    Column({ space: 14 }) {
      Text('真实模型 API 配置').width('100%').fontSize(19).fontWeight(FontWeight.Bold)
        .fontColor(this.palette().primaryText)
      Text('这里配置模型服务地址、API Key 和模型 ID。只有“AI”与“Agent”页会把问题发送给真实生成式模型。')
        .width('100%').fontSize(13).lineHeight(20).fontColor(this.palette().secondaryText)
      TextInput({ text: this.apiEndpoint, placeholder: 'http://127.0.0.1:8787' })
        .height(48).onChange((value: string) => this.apiEndpoint = value)
      if (this.modelMode === AiModelMode.BACKEND_API) {
        TextInput({ text: this.apiKey, placeholder: 'API Key（仅保存在本次运行内）' })
          .height(48).onChange((value: string) => this.apiKey = value)
        TextInput({ text: this.apiModel, placeholder: '模型名，例如 openai/gpt-oss-20b' })
          .height(48).onChange((value: string) => this.apiModel = value)
        Row({ space: 8 }) {
          Button('本地后端').layoutWeight(1).height(40).backgroundColor('#24364E')
            .onClick(() => {
              this.apiEndpoint = 'http://127.0.0.1:8787';
              this.apiKey = '';
              this.checkApi();
            })
          Button('Groq 兼容').layoutWeight(1).height(40).backgroundColor('#24364E')
            .onClick(() => {
              this.apiEndpoint = 'https://api.groq.com/openai/v1';
              this.apiModel = 'openai/gpt-oss-20b';
            })
        }.width('100%')
        Text('支持 OpenAI 兼容接口：Groq、SiliconFlow、OpenRouter 等。密钥只放在设备内存中。')
          .width('100%').fontSize(11).lineHeight(18).fontColor(this.palette().secondaryText)
      }
      Button('检测模型服务连接').width('100%').height(46).fontColor('#FFFFFFFF').backgroundColor('#087F5B')
        .linearGradient({ angle: 90, colors: [['#087F5B', 0], ['#19A97B', 0.55], ['#3977F6', 1]] })
        .onClick(() => this.checkApi())
      Text(this.apiStatus).width('100%').fontSize(12).fontColor('#5CE1D0')
      Divider().color(this.line())
      Text('确定性开发工具').width('100%').fontSize(19).fontWeight(FontWeight.Bold)
        .fontColor(this.palette().primaryText)
      Text('以下 JSON 格式化和 HTTP 状态码查询是本地工具，不是 AI，也不会根据文本生成答案。')
        .width('100%').fontSize(13).lineHeight(20).fontColor(this.palette().secondaryText)
      Text('JSON 格式化').width('100%').fontSize(18).fontWeight(FontWeight.Bold)
        .fontColor(this.palette().primaryText)
      TextArea({ text: this.jsonInput, placeholder: '输入 JSON' }).height(110).fontFamily('monospace')
        .onChange((value: string) => this.jsonInput = value)
      Button('格式化并校验').width('100%').height(46).fontColor('#FFFFFFFF').backgroundColor('#3157A4')
        .linearGradient({ angle: 90, colors: [['#3157A4', 0], ['#6A3DE8', 1]] })
        .onClick(() => this.formatJson())
      Text(this.jsonOutput).width('100%').fontSize(12).fontFamily('monospace')
        .fontColor(this.palette().primaryText).copyOption(CopyOptions.LocalDevice)
      Divider().color(this.line())
      Text('HTTP 状态码速查').width('100%').fontSize(19).fontWeight(FontWeight.Bold)
        .fontColor(this.palette().primaryText)
      Row({ space: 10 }) {
        TextInput({ text: this.httpCode, placeholder: '404' }).layoutWeight(1).height(48)
          .onChange((value: string) => this.httpCode = value)
        Button('查询').height(48).backgroundColor('#12A69A').onClick(() => this.lookupHttp())
      }.width('100%')
      Text(this.httpResult).width('100%').fontSize(14).fontColor(this.palette().primaryText)
    }
    .width('100%').padding(17).backgroundColor(this.glass())
    .systemMaterial(this.immersiveMaterial('#8AB4FF')).borderRadius(22)
  }

  build() {
    Scroll() {
      Column({ space: 15 }) {
        this.titleBlock()
        Row({ space: 6 }) {
          this.tab('AI', 0); this.tab('Agent', 1); this.tab('Skill', 2)
        }.width('100%')
        Row({ space: 6 }) {
          this.tab('视觉', 3); this.tab('多窗', 4); this.tab('API/工具', 5)
        }.width('100%')

        if (this.activeTab === 0) this.aiPanel(false)
        else if (this.activeTab === 1) this.aiPanel(true)
        else if (this.activeTab === 2) this.skillPanel()
        else if (this.activeTab === 3) this.visionPanel()
        else if (this.activeTab === 4) this.windowPanel()
        else this.apiToolsPanel()
      }
      .width('100%').padding({ left: 18, right: 18, top: 24, bottom: 190 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%').height('100%').backgroundColor(this.palette().pageBackground)
  }
}
