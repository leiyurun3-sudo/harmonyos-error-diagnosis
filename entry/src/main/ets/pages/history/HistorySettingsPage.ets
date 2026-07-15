import { AsyncStatePanel } from '../../components/common/AsyncStatePanel';
import { EmptyStateView } from '../../components/common/EmptyStateView';
import { InlineErrorNotice } from '../../components/common/InlineErrorNotice';
import { HistoryReportCard } from '../../components/history/HistoryReportCard';
import { OperationStatus } from '../../model/ResultModels';
import { AppRouter } from '../../router/AppRouter';
import { RouteName } from '../../router/RouteNames';
import { createHistoryViewModel } from '../../service/platform/AppRuntime';
import { AppStateStore } from '../../store/AppStateStore';
import { getThemePalette, ThemePalette, themeStatusText } from '../../theme/ThemeModels';
import { HomeReportItem } from '../../viewmodel/home/HomeModels';
import { HistoryViewModel } from '../../viewmodel/history/HistoryViewModel';

@Component
export struct HistorySettingsPage {
  @Consume('appRouter')
  router: AppRouter;
  @Consume('appState')
  appState: AppStateStore;
  @State
  private viewModel: HistoryViewModel | undefined = undefined;

  aboutToAppear(): void {
    if (this.viewModel === undefined) {
      this.viewModel = createHistoryViewModel(this.router);
    }
    this.viewModel.loadHistory();
  }

  aboutToDisappear(): void {
    this.viewModel?.dispose();
  }

  private palette(): ThemePalette {
    return getThemePalette(this.appState.effectiveTheme, this.appState.accentTheme);
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 14 }) {
          Text($r('app.string.route_history_settings_title'))
            .width('100%')
            .fontSize(28 * this.appState.contentFontMultiplier)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.palette().primaryText)
          Text($r('app.string.history_description'))
            .width('100%')
            .fontColor(this.palette().secondaryText)
          Text(themeStatusText(this.appState.selectedThemeMode, this.appState.effectiveTheme))
            .width('100%')
            .fontColor(this.palette().accent)

          if (this.viewModel === undefined ||
            this.viewModel.historyStatus === OperationStatus.LOADING) {
            AsyncStatePanel({
              status: OperationStatus.LOADING,
              message: '正在加载历史记录',
              showContent: false
            })
          } else {
            if (this.viewModel.historyStatus === OperationStatus.ERROR) {
              InlineErrorNotice({
                message: this.viewModel.historyError?.message ??
                  '暂时无法读取历史记录，请稍后重试。',
                actionLabel: '重新加载',
                onAction: (): void => { this.viewModel?.retryHistory(); }
              })
            }
            if (this.viewModel.isHistoryEmpty) {
              EmptyStateView({
                title: '还没有诊断记录',
                description: '完成诊断并主动保存后，记录会显示在这里。'
              })
            } else {
              ForEach(this.viewModel.historyReports, (item: HomeReportItem) => {
                HistoryReportCard({
                  item: item,
                  compact: false,
                  idPrefix: 'history_report',
                  onOpen: (): void => { this.viewModel?.openReport(item.reportId); }
                })
              }, (item: HomeReportItem): string => item.reportId)
            }
          }

          Button($r('app.string.route_open_privacy'))
            .width('100%')
            .constraintSize({ minHeight: 48 })
            .onClick(() => this.router.openPrivacy({
              origin: RouteName.HISTORY_SETTINGS
            }))
          Button($r('app.string.route_back_home'))
            .width('100%')
            .constraintSize({ minHeight: 48 })
            .onClick(() => this.router.back())
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 20, bottom: 32 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.palette().pageBackground)
    }
    .title($r('app.string.route_history_settings_title'))
    .backgroundColor(this.palette().navigationBackground)
  }
}
