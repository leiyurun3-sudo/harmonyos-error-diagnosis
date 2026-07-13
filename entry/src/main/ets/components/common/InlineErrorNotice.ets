import { AppStateStore } from '../../store/AppStateStore';
import {
  getThemePalette,
  ThemePalette
} from '../../theme/ThemeModels';
import {
  ComponentAction,
  createInlineNoticePresentation,
  InlineNoticePresentation,
  NoticeSeverity
} from './CommonComponentModels';

@Component
export struct InlineErrorNotice {
  @Consume('appState')
  appState: AppStateStore;
  @Prop
  message: string = '';
  @Prop
  actionLabel: string | undefined = undefined;
  @Prop
  severity: NoticeSeverity = NoticeSeverity.ERROR;
  onAction?: ComponentAction;
  onDismiss?: ComponentAction;

  private palette(): ThemePalette {
    return getThemePalette(this.appState.effectiveTheme);
  }

  private presentation(): InlineNoticePresentation {
    return createInlineNoticePresentation(
      this.message,
      this.severity,
      this.actionLabel,
      this.onAction !== undefined,
      this.onDismiss !== undefined
    );
  }

  private severityColor(): string {
    return this.severity === NoticeSeverity.INFO ? this.palette().accent : this.palette().error;
  }

  private action(): void {
    this.onAction?.();
  }

  private dismiss(): void {
    this.onDismiss?.();
  }

  build() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        if (this.severity === NoticeSeverity.INFO) {
          Text($r('app.string.common_notice_info'))
            .fontWeight(FontWeight.Bold)
            .fontColor(this.severityColor())
        } else if (this.severity === NoticeSeverity.WARNING) {
          Text($r('app.string.common_notice_warning'))
            .fontWeight(FontWeight.Bold)
            .fontColor(this.severityColor())
        } else {
          Text($r('app.string.common_notice_error'))
            .fontWeight(FontWeight.Bold)
            .fontColor(this.severityColor())
        }
      }
      .width('100%')
      .accessibilityDescription($r('app.string.common_notice_severity_accessibility'))

      Text(this.presentation().message)
        .width('100%')
        .fontColor(this.palette().primaryText)
        .accessibilityText(this.presentation().message)

      Row({ space: 12 }) {
        if (this.presentation().showDismiss) {
          Button($r('app.string.common_notice_dismiss'))
            .constraintSize({ minHeight: 44 })
            .fontColor(this.palette().secondaryText)
            .accessibilityText($r('app.string.common_notice_dismiss_accessibility'))
            .onClick(() => this.dismiss())
        }
        if (this.presentation().showAction) {
          Button(this.presentation().actionLabel)
            .constraintSize({ minHeight: 44 })
            .fontColor(this.palette().accent)
            .accessibilityText(this.presentation().actionLabel)
            .onClick(() => this.action())
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .border({ width: 1, color: this.severityColor() })
    .borderRadius(12)
    .backgroundColor(this.palette().surfaceBackground)
  }
}
