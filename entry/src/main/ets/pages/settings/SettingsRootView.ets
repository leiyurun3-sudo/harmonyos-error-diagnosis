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
      .padding({ left: 20, right: 20, top: 24, bottom: 112 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.palette().pageBackground)
  }
}
