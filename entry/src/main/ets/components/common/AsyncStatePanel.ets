import {
  AppError,
  OperationStatus
} from '../../model/ResultModels';
import { AppStateStore } from '../../store/AppStateStore';
import {
  getThemePalette,
  ThemePalette
} from '../../theme/ThemeModels';
import {
  AsyncStatePresentation,
  ComponentAction,
  createAsyncStatePresentation
} from './CommonComponentModels';

@Component
export struct AsyncStatePanel {
  @Consume('appState')
  appState: AppStateStore;
  @Prop
  status: OperationStatus = OperationStatus.IDLE;
  @Prop
  message: string = '';
  @Prop
  showContent: boolean = false;
  @Prop
  error: AppError | undefined = undefined;
  onRetry?: ComponentAction;
  @BuilderParam
  contentBuilder: () => void = this.emptyContent;

  @Builder
  private emptyContent() {
  }

  private palette(): ThemePalette {
    return getThemePalette(this.appState.effectiveTheme);
  }

  private presentation(): AsyncStatePresentation {
    return createAsyncStatePresentation(
      this.status,
      this.message,
      this.showContent,
      this.error,
      this.onRetry !== undefined
    );
  }

  private retry(): void {
    this.onRetry?.();
  }

  build() {
    Column({ space: 12 }) {
      if (this.status === OperationStatus.IDLE) {
        Text($r('app.string.common_async_idle'))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.palette().primaryText)
          .accessibilityText($r('app.string.common_async_idle_accessibility'))
      } else if (this.status === OperationStatus.LOADING) {
        Row({ space: 10 }) {
          LoadingProgress()
            .width(24)
            .height(24)
            .color(this.palette().accent)
          Text($r('app.string.common_async_loading'))
            .fontWeight(FontWeight.Medium)
            .fontColor(this.palette().primaryText)
        }
        .accessibilityText($r('app.string.common_async_loading_accessibility'))
      } else if (this.status === OperationStatus.SUCCESS) {
        Text($r('app.string.common_async_success'))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.palette().primaryText)
          .accessibilityText($r('app.string.common_async_success_accessibility'))
      } else if (this.status === OperationStatus.ERROR) {
        Text($r('app.string.common_async_error'))
          .fontWeight(FontWeight.Bold)
          .fontColor(this.palette().error)
          .accessibilityText($r('app.string.common_async_error_accessibility'))
      } else {
        Text($r('app.string.common_async_cancelled'))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.palette().secondaryText)
          .accessibilityText($r('app.string.common_async_cancelled_accessibility'))
      }

      if (this.presentation().message.length > 0) {
        Text(this.presentation().message)
          .width('100%')
          .fontColor(this.presentation().showError ? this.palette().error : this.palette().secondaryText)
          .accessibilityText(this.presentation().message)
      } else if (this.status === OperationStatus.LOADING) {
        Text($r('app.string.common_async_loading_default'))
          .width('100%')
          .fontColor(this.palette().secondaryText)
      } else if (this.status === OperationStatus.ERROR) {
        Text($r('app.string.common_async_error_default'))
          .width('100%')
          .fontColor(this.palette().error)
      } else if (this.status === OperationStatus.CANCELLED) {
        Text($r('app.string.common_async_cancelled_default'))
          .width('100%')
          .fontColor(this.palette().secondaryText)
      }

      if (this.presentation().showContent) {
        this.contentBuilder()
      }

      if (this.presentation().showRetry) {
        Button($r('app.string.common_action_retry'))
          .constraintSize({ minHeight: 44 })
          .fontColor(this.palette().accent)
          .accessibilityText($r('app.string.common_action_retry_accessibility'))
          .onClick(() => this.retry())
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .borderRadius(12)
    .backgroundColor(this.palette().surfaceBackground)
  }
}
