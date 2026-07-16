import {
  AccentTheme,
  ContentFontScale,
  ThemeMode,
  VisualEffectMode
} from '../../model/SettingsModels';
import { AppRouter } from '../../router/AppRouter';
import { RouteName } from '../../router/RouteNames';
import {
  switchApplicationTheme,
  updateApplicationVisualPreferences
} from '../../service/platform/AppRuntime';
import { AppStateStore } from '../../store/AppStateStore';
import {
  getThemePalette,
  resolveChoiceVisualState,
  ThemePalette
} from '../../theme/ThemeModels';

@Component
export struct SettingsRootView {
  @Consume('appRouter')
  router: AppRouter;
  @ObjectLink
  appState: AppStateStore;
  @State private autoSaveReports: boolean = true;
  @State private clipboardDetection: boolean = false;
  @State private privacyMask: boolean = true;
  @State private hapticFeedback: boolean = true;
  @State private diagnosticNotifications: boolean = true;
  @State private apiProvider: string = 'Groq';
  @State private requestTimeout: number = 30;
  @State private historyCapacity: number = 50;

  private palette(): ThemePalette {
    return getThemePalette(this.appState.effectiveTheme, this.appState.accentTheme);
  }

  private fontScale(): number {
    if (this.appState.contentFontScale === ContentFontScale.COMPACT) {
      return 0.9;
    }
    if (this.appState.contentFontScale === ContentFontScale.LARGE) {
      return 1.15;
    }
    return 1;
  }

  private updateAccent(accentTheme: AccentTheme): void {
    updateApplicationVisualPreferences(
      accentTheme,
      this.appState.contentFontScale,
      this.appState.visualEffectMode
    );
  }

  private updateFont(contentFontScale: ContentFontScale): void {
    updateApplicationVisualPreferences(
      this.appState.accentTheme,
      contentFontScale,
      this.appState.visualEffectMode
    );
  }

  private updateEffects(visualEffectMode: VisualEffectMode): void {
    updateApplicationVisualPreferences(
      this.appState.accentTheme,
      this.appState.contentFontScale,
      visualEffectMode
    );
  }

  @Builder
  private choiceButton(label: string, isSelected: () => boolean, action: () => void) {
    Button(label)
      .constraintSize({ minHeight: 44 })
      .stateEffect(false)
      .focusable(false)
      .focusOnTouch(false)
      .fontSize(14 * this.fontScale())
      .fontWeight(isSelected() ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(resolveChoiceVisualState(this.palette(), isSelected()).foreground)
      .backgroundColor(resolveChoiceVisualState(this.palette(), isSelected()).background)
      .border({
        width: resolveChoiceVisualState(this.palette(), isSelected()).borderWidth,
        color: resolveChoiceVisualState(this.palette(), isSelected()).borderColor
      })
      .borderRadius(14)
      .onClick(action)
  }

  @Builder
  private sectionTitle(title: string, description: string) {
    Column({ space: 4 }) {
      Text(title)
        .width('100%')
        .fontSize(18 * this.fontScale())
        .fontWeight(FontWeight.Bold)
        .fontColor(this.palette().primaryText)
      Text(description)
        .width('100%')
        .fontSize(13 * this.fontScale())
        .fontColor(this.palette().secondaryText)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private toggleRow(title: string, description: string, checked: boolean, action: (value: boolean) => void) {
    Row({ space: 12 }) {
      Column({ space: 3 }) {
        Text(title).width('100%').fontSize(15 * this.fontScale()).fontWeight(FontWeight.Medium)
          .fontColor(this.palette().primaryText)
        Text(description).width('100%').fontSize(12 * this.fontScale()).lineHeight(18)
          .fontColor(this.palette().secondaryText)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Toggle({ type: ToggleType.Switch, isOn: checked })
        .selectedColor('#087F5B')
        .onChange(action)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.palette().surfaceBackground)
    .border({ width: 1, color: this.palette().secondaryActionBorder })
    .borderRadius(16)
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Text('设置')
          .width('100%')
          .fontSize(30 * this.fontScale())
          .fontWeight(FontWeight.Bold)
          .fontColor(this.palette().primaryText)

        this.sectionTitle('外观模式', '跟随系统，或固定使用浅色、深色')
        Row({ space: 8 }) {
          this.choiceButton('跟随系统', (): boolean => this.appState.selectedThemeMode === ThemeMode.SYSTEM,
            (): void => { switchApplicationTheme(ThemeMode.SYSTEM); })
          this.choiceButton('浅色', (): boolean => this.appState.selectedThemeMode === ThemeMode.LIGHT,
            (): void => { switchApplicationTheme(ThemeMode.LIGHT); })
          this.choiceButton('深色', (): boolean => this.appState.selectedThemeMode === ThemeMode.DARK,
            (): void => { switchApplicationTheme(ThemeMode.DARK); })
        }
        .width('100%')

        this.sectionTitle('主题色', '用于按钮、选中状态和玻璃光晕')
        Row({ space: 8 }) {
          this.choiceButton('蓝色', (): boolean => this.appState.accentTheme === AccentTheme.BLUE,
            (): void => this.updateAccent(AccentTheme.BLUE))
          this.choiceButton('青色', (): boolean => this.appState.accentTheme === AccentTheme.CYAN,
            (): void => this.updateAccent(AccentTheme.CYAN))
          this.choiceButton('紫色', (): boolean => this.appState.accentTheme === AccentTheme.PURPLE,
            (): void => this.updateAccent(AccentTheme.PURPLE))
          this.choiceButton('绿色', (): boolean => this.appState.accentTheme === AccentTheme.GREEN,
            (): void => this.updateAccent(AccentTheme.GREEN))
        }
        .width('100%')

        this.sectionTitle('字体大小', '调整应用主要内容的显示大小')
        Row({ space: 8 }) {
          this.choiceButton('紧凑', (): boolean => this.appState.contentFontScale === ContentFontScale.COMPACT,
            (): void => this.updateFont(ContentFontScale.COMPACT))
          this.choiceButton('标准', (): boolean => this.appState.contentFontScale === ContentFontScale.STANDARD,
            (): void => this.updateFont(ContentFontScale.STANDARD))
          this.choiceButton('较大', (): boolean => this.appState.contentFontScale === ContentFontScale.LARGE,
            (): void => this.updateFont(ContentFontScale.LARGE))
        }
        .width('100%')

        this.sectionTitle('视觉效果', '发光玻璃可降低或关闭，导航功能保持可用')
        Row({ space: 8 }) {
          this.choiceButton('完整', (): boolean => this.appState.visualEffectMode === VisualEffectMode.FULL,
            (): void => this.updateEffects(VisualEffectMode.FULL))
          this.choiceButton('降低', (): boolean => this.appState.visualEffectMode === VisualEffectMode.REDUCED,
            (): void => this.updateEffects(VisualEffectMode.REDUCED))
          this.choiceButton('关闭', (): boolean => this.appState.visualEffectMode === VisualEffectMode.OFF,
            (): void => this.updateEffects(VisualEffectMode.OFF))
        }
        .width('100%')

        this.sectionTitle('诊断偏好', '控制输入、报告保存和诊断完成后的反馈')
        this.toggleRow('自动保存诊断报告', '完成诊断后自动加入本地记录，可随时删除。',
          this.autoSaveReports, (value: boolean): void => { this.autoSaveReports = value; })
        this.toggleRow('检测剪贴板错误文本', '回到应用时提示是否导入剪贴板中的构建错误。',
          this.clipboardDetection, (value: boolean): void => { this.clipboardDetection = value; })
        this.toggleRow('诊断完成提醒', '长时间诊断完成后显示应用内状态提醒。',
          this.diagnosticNotifications, (value: boolean): void => { this.diagnosticNotifications = value; })

        this.sectionTitle('AI 与网络', '真实模型需要 API Key；密钥只保存在当前运行内')
        Row({ space: 8 }) {
          this.choiceButton('Groq', (): boolean => this.apiProvider === 'Groq',
            (): void => { this.apiProvider = 'Groq'; })
          this.choiceButton('OpenAI 兼容', (): boolean => this.apiProvider === 'OpenAI 兼容',
            (): void => { this.apiProvider = 'OpenAI 兼容'; })
          this.choiceButton('本地后端', (): boolean => this.apiProvider === '本地后端',
            (): void => { this.apiProvider = '本地后端'; })
        }.width('100%')
        Text(`当前服务：${this.apiProvider} · 请求超时 ${this.requestTimeout} 秒`)
          .width('100%').fontSize(13 * this.fontScale()).fontColor(this.palette().secondaryText)
        Row({ space: 8 }) {
          this.choiceButton('15 秒', (): boolean => this.requestTimeout === 15,
            (): void => { this.requestTimeout = 15; })
          this.choiceButton('30 秒', (): boolean => this.requestTimeout === 30,
            (): void => { this.requestTimeout = 30; })
          this.choiceButton('60 秒', (): boolean => this.requestTimeout === 60,
            (): void => { this.requestTimeout = 60; })
        }.width('100%')

        this.sectionTitle('记录与隐私', '所有诊断默认仅在设备本地处理和保存')
        this.toggleRow('隐私遮罩', '分享或投屏时隐藏 API Key、文件路径和设备标识。',
          this.privacyMask, (value: boolean): void => { this.privacyMask = value; })
        this.toggleRow('触感反馈', '重要按钮和诊断完成时提供轻触反馈。',
          this.hapticFeedback, (value: boolean): void => { this.hapticFeedback = value; })
        Text(`历史记录容量：${this.historyCapacity} 条`)
          .width('100%').fontSize(15 * this.fontScale()).fontWeight(FontWeight.Medium)
          .fontColor(this.palette().primaryText)
        Row({ space: 8 }) {
          this.choiceButton('20 条', (): boolean => this.historyCapacity === 20,
            (): void => { this.historyCapacity = 20; })
          this.choiceButton('50 条', (): boolean => this.historyCapacity === 50,
            (): void => { this.historyCapacity = 50; })
          this.choiceButton('100 条', (): boolean => this.historyCapacity === 100,
            (): void => { this.historyCapacity = 100; })
        }.width('100%')

        Column({ space: 6 }) {
          Text('应用与诊断引擎').width('100%').fontSize(17 * this.fontScale()).fontWeight(FontWeight.Bold)
            .fontColor(this.palette().primaryText)
          Text('应用版本 1.0.0 · 规则引擎 2.1 · HarmonyOS API 26')
            .width('100%').fontSize(13 * this.fontScale()).fontColor(this.palette().secondaryText)
          Text('本地优先 · 支持真实 OpenAI 兼容模型 API · 支持视觉文字识别')
            .width('100%').fontSize(13 * this.fontScale()).lineHeight(20)
            .fontColor(this.palette().secondaryText)
        }
        .width('100%').padding(16).backgroundColor(this.palette().surfaceBackground)
        .borderRadius(18)

        Button('隐私与本地数据说明')
          .width('100%')
          .constraintSize({ minHeight: 50 })
          .fontColor(this.palette().accent)
          .backgroundColor(this.palette().surfaceBackground)
          .borderRadius(16)
          .onClick((): void => {
            this.router.openPrivacy({ origin: RouteName.HISTORY_SETTINGS });
          })

        if (this.appState.isThemeSessionOnly) {
          Text('设置保存失败，本次修改仅在当前会话生效。')
            .width('100%')
            .fontSize(14)
            .fontColor(this.palette().error)
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 24, bottom: 190 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.palette().pageBackground)
  }
}
