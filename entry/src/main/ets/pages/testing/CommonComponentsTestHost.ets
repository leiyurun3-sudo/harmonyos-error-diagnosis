import { AsyncStatePanel } from '../../components/common/AsyncStatePanel';
import { ConfirmActionDialog } from '../../components/common/ConfirmActionDialog';
import { EmptyStateView } from '../../components/common/EmptyStateView';
import { InlineErrorNotice } from '../../components/common/InlineErrorNotice';
import { NoticeSeverity } from '../../components/common/CommonComponentModels';
import {
  AppError,
  OperationStatus
} from '../../model/ResultModels';
import { ThemeMode } from '../../model/SettingsModels';
import {
  appStateStore as globalAppStateStore,
  switchApplicationTheme
} from '../../service/platform/AppRuntime';
import { AppStateStore } from '../../store/AppStateStore';
import {
  getThemePalette,
  ThemePalette
} from '../../theme/ThemeModels';

/** Device-test host only. It is registered for loadContent but has no router or user-visible entry. */
@Entry
@Component
struct CommonComponentsTestHost {
  @Provide('appState')
  private appState: AppStateStore = globalAppStateStore;
  @State
  private asyncStatus: OperationStatus = OperationStatus.LOADING;
  @State
  private eventText: string = '事件：无';
  @State
  private showNotice: boolean = true;

  private dialogController: CustomDialogController = new CustomDialogController({
    builder: ConfirmActionDialog({
      title: '删除测试记录',
      message: '删除后无法恢复，请确认是否继续。',
      dangerous: true,
      onConfirm: (): void => {
        this.eventText = '事件：确认';
      },
      onCancel: (): void => {
        this.eventText = '事件：取消';
      }
    }),
    autoCancel: true,
    customStyle: true,
    alignment: DialogAlignment.Center
  });

  private palette(): ThemePalette {
    return getThemePalette(this.appState.effectiveTheme);
  }

  private error(): AppError {
    return {
      code: 'SYNTHETIC_SAFE_ERROR',
      message: '安全错误信息，可再次尝试',
      retryable: true,
      causeType: 'PRIVATE_PLATFORM_DETAIL',
      correlationId: 'PRIVATE_CORRELATION_ID'
    };
  }

  @Builder
  private lastContent() {
    Text('最后一份有效内容')
      .width('100%')
      .fontColor(this.palette().primaryText)
      .accessibilityText('最后一份有效内容')
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Text('公共组件测试宿主')
          .width('100%')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.palette().primaryText)
          .textAlign(TextAlign.Center)
        Text(`组件主题：${this.appState.selectedThemeMode}`)
          .width('100%')
          .fontColor(this.palette().accent)
          .textAlign(TextAlign.Center)
        Column({ space: 8 }) {
          Button('组件浅色主题')
            .width('100%')
            .constraintSize({ minHeight: 44 })
            .onClick(() => switchApplicationTheme(ThemeMode.LIGHT))
          Button('组件深色主题')
            .width('100%')
            .constraintSize({ minHeight: 44 })
            .onClick(() => switchApplicationTheme(ThemeMode.DARK))
          Button('组件跟随系统')
            .width('100%')
            .constraintSize({ minHeight: 44 })
            .onClick(() => switchApplicationTheme(ThemeMode.SYSTEM))
        }
        .width('100%')

        AsyncStatePanel({
          status: this.asyncStatus,
          message: this.asyncStatus === OperationStatus.LOADING ? '正在加载组件数据' : '',
          error: this.asyncStatus === OperationStatus.ERROR ? this.error() : undefined,
          showContent: true,
          onRetry: (): void => {
            this.eventText = '事件：重试';
          },
          contentBuilder: this.lastContent
        })
        Button('显示错误状态')
          .constraintSize({ minHeight: 44 })
          .onClick(() => {
            this.asyncStatus = OperationStatus.ERROR;
          })

        EmptyStateView({
          title: '暂无历史记录',
          description: '当前没有历史记录，完成诊断后会显示在这里。',
          actionLabel: '开始诊断',
          onAction: (): void => {
            this.eventText = '事件：空状态操作';
          }
        })

        if (this.showNotice) {
          InlineErrorNotice({
            message: '输入内容存在问题，请检查后重试。',
            actionLabel: '查看处理方法',
            severity: NoticeSeverity.WARNING,
            onAction: (): void => {
              this.eventText = '事件：错误操作';
            },
            onDismiss: (): void => {
              this.eventText = '事件：关闭错误';
              this.showNotice = false;
            }
          })
        }

        Button('打开危险确认')
          .constraintSize({ minHeight: 44 })
          .onClick(() => {
            this.dialogController.open();
          })
        Text(this.eventText)
          .width('100%')
          .fontColor(this.palette().primaryText)
          .textAlign(TextAlign.Center)
          .accessibilityText(this.eventText)
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .id('common_components_scroll')
    .scrollBar(BarState.Auto)
    .backgroundColor(this.palette().pageBackground)
  }
}
