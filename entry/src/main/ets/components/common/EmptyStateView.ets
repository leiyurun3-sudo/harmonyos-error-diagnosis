import { uiMaterial } from '@kit.ArkUI';
import { AppStateStore } from '../../store/AppStateStore';
import {
  EffectiveTheme,
  getThemePalette,
  ThemePalette
} from '../../theme/ThemeModels';
import {
  ComponentAction,
  createEmptyStatePresentation,
  EmptyStatePresentation
} from './CommonComponentModels';

@Component
export struct EmptyStateView {
  private readonly lightSecondaryMaterial: uiMaterial.ImmersiveMaterial = new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.THIN,
    materialColor: '#33D7ECFF',
    colorInvert: false,
    applyShadow: true,
    interactive: true,
    lightEffect: { color: '#C8F1FF' }
  });
  @Consume('appState')
  appState: AppStateStore;
  @Prop
  title: string = '';
  @Prop
  description: string = '';
  @Prop
  actionLabel: string | undefined = undefined;
  onAction?: ComponentAction;

  private palette(): ThemePalette {
    return getThemePalette(this.appState.effectiveTheme, this.appState.accentTheme);
  }

  private presentation(): EmptyStatePresentation {
    return createEmptyStatePresentation(
      this.title,
      this.description,
      this.actionLabel,
      this.onAction !== undefined
    );
  }

  private action(): void {
    this.onAction?.();
  }

  build() {
    Column({ space: 12 }) {
      Text(this.presentation().title)
        .width('100%')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.palette().primaryText)
        .textAlign(TextAlign.Center)
        .accessibilityText(this.presentation().title)
      Text(this.presentation().description)
        .width('100%')
        .fontColor(this.palette().secondaryText)
        .textAlign(TextAlign.Center)
        .accessibilityText(this.presentation().description)
      if (this.presentation().showAction) {
        Button(this.presentation().actionLabel)
          .constraintSize({ minHeight: 44 })
          .fontColor(this.appState.effectiveTheme === EffectiveTheme.LIGHT ?
            this.palette().secondaryActionText : this.palette().accent)
          .backgroundColor(this.appState.effectiveTheme === EffectiveTheme.LIGHT ?
            this.palette().secondaryActionSurface : undefined)
          .systemMaterial(this.appState.effectiveTheme === EffectiveTheme.LIGHT ?
            this.lightSecondaryMaterial : undefined)
          .border({
            width: this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 1 : 0,
            color: this.palette().secondaryActionBorder
          })
          .borderRadius(this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 14 : undefined)
          .shadow({
            radius: this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 12 : 0,
            color: this.palette().secondaryActionGlow,
            offsetX: 0,
            offsetY: this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 3 : 0
          })
          .accessibilityText(this.presentation().actionLabel)
          .onClick(() => this.action())
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor(this.palette().surfaceBackground)
  }
}
