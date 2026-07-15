import { AsyncStatePanel } from '../../components/common/AsyncStatePanel';
import { EmptyStateView } from '../../components/common/EmptyStateView';
import { InlineErrorNotice } from '../../components/common/InlineErrorNotice';
import { HistoryReportCard } from '../../components/history/HistoryReportCard';
import { OperationStatus } from '../../model/ResultModels';
import { AppRouter } from '../../router/AppRouter';
import { createHistoryViewModel } from '../../service/platform/AppRuntime';
import { AppStateStore } from '../../store/AppStateStore';
import { getThemePalette, ThemePalette } from '../../theme/ThemeModels';
import { HomeReportItem } from '../../viewmodel/home/HomeModels';
import { HistoryViewModel } from '../../viewmodel/history/HistoryViewModel';

@Component
export struct RecordsRootView {
  @Consume('appRouter')
  router: AppRouter;
  @Consume('appState')
  appState: AppStateStore;
  @State
  private viewModel: HistoryViewModel | undefined = undefined;

  private palette(): ThemePalette {
    return getThemePalette(this.appState.effectiveTheme, this.appState.accentTheme);
  }

  aboutToAppear(): void {
    if (this.viewModel === undefined) {
      this.viewModel = createHistoryViewModel(this.router);
    }
    this.viewModel.loadHistory();
  }

  aboutToDisappear(): void {
    this.viewModel?.dispose();
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Text('诊断记录')
          .width('100%')
          .fontSize(30 * this.appState.contentFontMultiplier)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.palette().primaryText)
        Text('最近保存的本地诊断报告')
          .width('100%')
          .fontSize(15 * this.appState.contentFontMultiplier)
          .fontColor(this.palette().secondaryText)
        if (this.viewModel === undefined || this.viewModel.historyStatus === OperationStatus.LOADING) {
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
