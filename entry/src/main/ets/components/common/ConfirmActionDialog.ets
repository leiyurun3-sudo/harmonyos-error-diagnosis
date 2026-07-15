import { AppStateStore } from '../../store/AppStateStore';
import {
  getThemePalette,
  ThemePalette
} from '../../theme/ThemeModels';
import {
  ComponentAction,
  ConfirmEventGate,
  ConfirmPresentation,
  createConfirmPresentation
} from './CommonComponentModels';

@CustomDialog
export struct ConfirmActionDialog {
  @Consume('appState')
  appState: AppStateStore;
  controller: CustomDialogController;
  @Prop
  title: string = '';
  @Prop
  message: string = '';
  @Prop
  dangerous: boolean = false;
  onConfirm: ComponentAction = (): void => {};
  onCancel: ComponentAction = (): void => {};
  private gate: ConfirmEventGate = new ConfirmEventGate();

  aboutToAppear(): void {
    this.gate.reset();
  }

  aboutToDisappear(): void {
    this.gate.cancel(this.onCancel);
  }

  private palette(): ThemePalette {
    return getThemePalette(this.appState.effectiveTheme, this.appState.accentTheme);
  }

  private presentation(): ConfirmPresentation {
    return createConfirmPresentation(this.title, this.message, this.dangerous);
  }

  private confirm(): void {
    if (this.gate.confirm(this.onConfirm)) {
      this.controller.close();
    }
  }

  private cancel(): void {
    if (this.gate.cancel(this.onCancel)) {
      this.controller.close();
    }
  }

  build() {
    Column({ space: 16 }) {
      Text(this.presentation().title)
        .width('100%')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.palette().primaryText)
        .accessibilityText(this.presentation().title)
      Text(this.presentation().message)
        .width('100%')
        .fontColor(this.palette().secondaryText)
        .accessibilityText(this.presentation().message)
      Text(this.presentation().dangerLabel)
        .width('100%')
        .fontWeight(FontWeight.Bold)
        .fontColor(this.dangerous ? this.palette().error : this.palette().accent)
        .accessibilityText(this.presentation().dangerLabel)
      Row({ space: 12 }) {
        Button(this.presentation().cancelLabel)
          .layoutWeight(1)
          .constraintSize({ minHeight: 44 })
          .fontColor(this.palette().primaryText)
          .accessibilityText($r('app.string.common_confirm_cancel_accessibility'))
          .onClick(() => this.cancel())
        Button(this.presentation().confirmLabel)
          .layoutWeight(1)
          .constraintSize({ minHeight: 44 })
          .fontColor(this.dangerous ? this.palette().error : this.palette().accent)
          .accessibilityText(this.presentation().confirmLabel)
          .onClick(() => this.confirm())
      }
      .width('100%')
    }
    .width('90%')
    .padding(20)
    .borderRadius(16)
    .backgroundColor(this.palette().surfaceBackground)
  }
}
