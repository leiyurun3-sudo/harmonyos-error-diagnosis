import { describe, expect, it } from '@ohos/hypium';
import { HISTORY_RECORD_LIMIT } from '../../main/ets/constants/AppLimits';
import { ErrorCode } from '../../main/ets/constants/ErrorCodes';
import { createFailureResult, createSuccessResult, OperationStatus } from '../../main/ets/model/ResultModels';
import { AppRouter } from '../../main/ets/router/AppRouter';
import { RouteName } from '../../main/ets/router/RouteNames';
import { ReportRouteParams } from '../../main/ets/router/RouteModels';
import { HomeReportItem } from '../../main/ets/viewmodel/home/HomeModels';
import { HistoryViewModel } from '../../main/ets/viewmodel/history/HistoryViewModel';
import { DeferredReportResult, FakeReportRepository } from '../fakes/FakeReportRepository';
import { FakeNavigationStack } from '../fakes/FakeNavigationStack';
import { createReportFixture } from '../fixtures/ReportFixtures';

export default function historyViewModelTest() {
  describe('HistoryViewModel', () => {
    it('publishes loading then a saved-time-descending history list', 0, async () => {
      const repository = new FakeReportRepository();
      const deferred = new DeferredReportResult();
      repository.deferredList = deferred;
      const viewModel = new HistoryViewModel(
        repository,
        new AppRouter(new FakeNavigationStack())
      );

      const loading = viewModel.loadHistory();
      expect(viewModel.historyStatus).assertEqual(OperationStatus.LOADING);
      expect(repository.listOffset).assertEqual(0);
      expect(repository.listLimit).assertEqual(HISTORY_RECORD_LIMIT);
      deferred.resolve(createSuccessResult([
        createReportFixture('history-old', 1, 100),
        createReportFixture('history-new', 2, 300),
        createReportFixture('history-middle', 3, 200)
      ]));

      expect(await loading).assertTrue();
      expect(viewModel.historyReports.map((item: HomeReportItem): string => item.reportId).join(','))
        .assertEqual('history-new,history-middle,history-old');
      expect(viewModel.historyStatus).assertEqual(OperationStatus.SUCCESS);
    });

    it('distinguishes a successfully loaded empty history', 0, async () => {
      const viewModel = new HistoryViewModel(
        new FakeReportRepository(),
        new AppRouter(new FakeNavigationStack())
      );

      expect(viewModel.isHistoryEmpty).assertFalse();
      expect(await viewModel.loadHistory()).assertTrue();
      expect(viewModel.isHistoryEmpty).assertTrue();
      expect(viewModel.historyReports.length).assertEqual(0);
    });

    it('retains the current list on read failure and allows retry', 0, async () => {
      const repository = new FakeReportRepository();
      repository.listResult = createSuccessResult([createReportFixture('history-retained', 1, 2)]);
      const viewModel = new HistoryViewModel(
        repository,
        new AppRouter(new FakeNavigationStack())
      );
      await viewModel.loadHistory();
      repository.listResult = createFailureResult({
        code: ErrorCode.STORAGE_READ_FAILED,
        message: 'Synthetic storage detail',
        retryable: true
      });

      expect(await viewModel.loadHistory()).assertFalse();
      expect(viewModel.historyStatus).assertEqual(OperationStatus.ERROR);
      expect(viewModel.historyError?.message.includes('Synthetic')).assertFalse();
      expect(viewModel.historyReports[0].reportId).assertEqual('history-retained');

      repository.listResult = createSuccessResult([createReportFixture('history-retry', 1, 3)]);
      expect(await viewModel.retryHistory()).assertTrue();
      expect(viewModel.historyReports[0].reportId).assertEqual('history-retry');
    });

    it('opens a historical report with reportId only', 0, () => {
      const stack = new FakeNavigationStack();
      const viewModel = new HistoryViewModel(
        new FakeReportRepository(),
        new AppRouter(stack)
      );

      expect(viewModel.openReport('history-route')).assertTrue();
      const params = stack.paths[0].param as ReportRouteParams;
      expect(params.reportId).assertEqual('history-route');
      expect(params.sessionId).assertUndefined();
      expect(params.origin).assertEqual(RouteName.HISTORY_SETTINGS);
    });

    it('ignores stale load completion after disposal', 0, async () => {
      const repository = new FakeReportRepository();
      const deferred = new DeferredReportResult();
      repository.deferredList = deferred;
      const viewModel = new HistoryViewModel(
        repository,
        new AppRouter(new FakeNavigationStack())
      );

      const loading = viewModel.loadHistory();
      viewModel.dispose();
      deferred.resolve(createSuccessResult([createReportFixture('history-stale', 1, 2)]));

      expect(await loading).assertFalse();
      expect(viewModel.historyStatus).assertEqual(OperationStatus.CANCELLED);
      expect(viewModel.historyReports.length).assertEqual(0);
    });
  });
}
