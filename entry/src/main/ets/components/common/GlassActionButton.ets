import { uiMaterial } from '@kit.ArkUI';
import { AppStateStore } from '../../store/AppStateStore';
import { getThemePalette, ThemePalette } from '../../theme/ThemeModels';
import {
  canDispatchGlassAction,
  createGlassActionVisualState,
  GlassActionVisualState
} from './GlassActionButtonModels';

@Component
export struct GlassActionButton {
  private readonly lightFocusMaterial: uiMaterial.ImmersiveMaterial = new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.THIN,
    materialColor: '#33FFFFFF',
    colorInvert: false,
    applyShadow: true,
    interactive: true,
    lightEffect: { color: Color.White }
  });
  @Consume('appState')
  appState: AppStateStore;
  @Prop
  label: ResourceStr = '';
  @Prop
  buttonId: string = '';
  @Prop
  actionEnabled: boolean = true;
  @Prop
  loading: boolean = false;
  @State
  private pressed: boolean = false;
  onAction: () => void = (): void => {};

  private palette(): ThemePalette {
    return getThemePalette(this.appState.effectiveTheme, this.appState.accentTheme);
  }

  private visualState(): GlassActionVisualState {
    return createGlassActionVisualState(
      this.palette(),
      this.appState.effectiveTheme,
      this.appState.visualEffectMode,
      canDispatchGlassAction(this.actionEnabled, this.loading),
      this.pressed
    );
  }

  build() {
    Button(this.label)
      .id(this.buttonId)
      .width('100%')
      .constraintSize({ minHeight: 52 })
      .fontSize(16 * this.appState.contentFontMultiplier)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.visualState().foregroundColor)
      .backgroundColor(this.visualState().backgroundColor)
      .backgroundBlurStyle(this.visualState().useDarkBlur ? BlurStyle.Thin : BlurStyle.NONE)
      .systemMaterial(this.visualState().useLightMaterial ? this.lightFocusMaterial : undefined)
      .border({ width: this.visualState().borderWidth, color: this.visualState().borderColor })
      .borderRadius(14)
      .opacity(this.visualState().opacity)
      .shadow({
        radius: this.visualState().shadowRadius,
        color: this.visualState().shadowColor,
        offsetX: 0,
        offsetY: this.visualState().shadowOffsetY
      })
      .scale({ x: this.visualState().scale, y: this.visualState().scale })
      .animation({
        duration: this.visualState().animationEnabled ? (this.pressed ? 100 : 180) : 0,
        curve: this.pressed ? Curve.EaseOut : Curve.Friction
      })
      .enabled(canDispatchGlassAction(this.actionEnabled, this.loading))
      .onTouch((event: TouchEvent): void => {
        if (!canDispatchGlassAction(this.actionEnabled, this.loading)) {
          this.pressed = false;
        } else if (event.type === TouchType.Down) {
          this.pressed = true;
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.pressed = false;
        }
      })
      .onClick((): void => {
        if (canDispatchGlassAction(this.actionEnabled, this.loading)) {
          this.onAction();
        }
      })
  }
}
