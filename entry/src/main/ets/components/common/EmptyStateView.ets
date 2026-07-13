import { AppStateStore } from '../../store/AppStateStore';
import {
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
    return getThemePalette(this.appState.effectiveTheme);
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
          .fontColor(this.palette().accent)
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
