import { describe, expect, it } from '@ohos/hypium';
import { ErrorCode } from '../../main/ets/constants/ErrorCodes';
import { SourceType } from '../../main/ets/model/DiagnosisModels';
import { createFailureResult, createSuccessResult, OperationStatus } from '../../main/ets/model/ResultModels';
import { AppRouter } from '../../main/ets/router/AppRouter';
import { RouteName } from '../../main/ets/router/RouteNames';
import { DiagnosisSessionStore } from '../../main/ets/store/DiagnosisSessionStore';
import { HomeViewModel } from '../../main/ets/viewmodel/home/HomeViewModel';
import { ReportViewModel } from '../../main/ets/viewmodel/report/ReportViewModel';
import { FakeTimeProvider, SequenceIdGenerator } from '../fakes/DiagnosisSessionFakes';
import { FakeNavigationStack } from '../fakes/FakeNavigationStack';
import { DeferredSingleReportResult, FakeReportRepository } from '../fakes/FakeReportRepository';
import { createReportFixture } from '../fixtures/ReportFixtures';

function createStore(withReport: boolean = true): DiagnosisSessionStore {
  const store = new DiagnosisSessionStore(
    new SequenceIdGenerator(['session-report']),
    new FakeTimeProvider(1000)
  );
  store.startNewSession(SourceType.TEXT);
  store.updateRawText('original editable text');
  if (withReport) {
    store.setPendingReport(createReportFixture('pending-report', 1));
  }
  return store;
}

export default function reportViewModelTest() {
  describe('ReportViewModel', () => {
    it('loads an unsaved report from the exact current memory session', 0, () => {
      const store = createStore();
      const viewModel = new ReportViewModel(
        store,
        new FakeReportRepository(),
        new AppRouter(new FakeNavigationStack()),
        { sessionId: 'session-report', origin: RouteName.DIAGNOSIS }
      );

      expect(viewModel.reportOperation.status).assertEqual(OperationStatus.SUCCESS);
      expect(viewModel.report?.id).assertEqual('pending-report');
      expect(viewModel.report?.savedAt).assertUndefined();
    });

    it('fails safely for a missing session or a session without a report', 0, () => {
      const missingSession = new ReportViewModel(
        createStore(),
        new FakeReportRepository(),
        new AppRouter(new FakeNavigationStack()),
        { sessionId: 'missing', origin: RouteName.DIAGNOSIS }
      );
      const noReport = new ReportViewModel(
        createStore(false),
        new FakeReportRepository(),
        new AppRouter(new FakeNavigationStack()),
        { sessionId: 'session-report', origin: RouteName.DIAGNOSIS }
      );

      expect(missingSession.reportOperation.status).assertEqual(OperationStatus.ERROR);
      expect(missingSession.reportError?.code).assertEqual(ErrorCode.ROUTE_PARAM_INVALID);
      expect(noReport.reportOperation.status).assertEqual(OperationStatus.ERROR);
      expect(noReport.reportError?.code).assertEqual(ErrorCode.REPORT_NOT_FOUND);
    });

    it('loads a persisted report by reportId without requiring a memory session', 0, async () => {
      const repository = new FakeReportRepository();
      repository.getByIdResult = createSuccessResult(createReportFixture('history-report', 1, 2));
      const viewModel = new ReportViewModel(
        createStore(false),
        repository,
        new AppRouter(new FakeNavigationStack()),
        { reportId: 'history-report', origin: RouteName.HOME }
      );

      expect(viewModel.reportOperation.status).assertEqual(OperationStatus.LOADING);
      expect(await viewModel.loadReport()).assertTrue();
      expect(repository.requestedReportId).assertEqual('history-report');
      expect(viewModel.report?.id).assertEqual('history-report');
      expect(viewModel.reportOperation.status).assertEqual(OperationStatus.SUCCESS);
    });

    it('returns isolated report arrays', 0, () => {
      const store = createStore();
      const viewModel = new ReportViewModel(
        store,
        new FakeReportRepository(),
        new AppRouter(new FakeNavigationStack()),
        { sessionId: 'session-report', origin: RouteName.DIAGNOSIS }
      );
      viewModel.report?.steps.push('MUTATED');

      expect(viewModel.report?.steps.includes('MUTATED')).assertFalse();
      expect(store.currentSession?.pendingReport?.steps.includes('MUTATED')).assertFalse();
    });

    it('returns to edit without changing raw text source or session identity', 0, () => {
      const store = createStore();
      const stack = new FakeNavigationStack();
      const router = new AppRouter(stack);
      router.openDiagnosis({ sourceType: SourceType.TEXT, origin: RouteName.HOME });
      router.openReport({ sessionId: 'session-report', origin: RouteName.DIAGNOSIS });
      const viewModel = new ReportViewModel(
        store,
        new FakeReportRepository(),
        router,
        { sessionId: 'session-report', origin: RouteName.DIAGNOSIS }
      );

      expect(viewModel.editInput()).assertTrue();

      expect(stack.paths.length).assertEqual(1);
      expect(store.currentSession?.sessionId).assertEqual('session-report');
      expect(store.currentSession?.sourceType).assertEqual(SourceType.TEXT);
      expect(store.currentSession?.rawText).assertEqual('original editable text');
    });

    it('re-diagnose returns to the same editable session', 0, () => {
      const store = createStore();
      const stack = new FakeNavigationStack();
      stack.paths.push({ name: RouteName.DIAGNOSIS });
      stack.paths.push({ name: RouteName.REPORT });
      const viewModel = new ReportViewModel(
        store,
        new FakeReportRepository(),
        new AppRouter(stack),
        { sessionId: 'session-report', origin: RouteName.DIAGNOSIS }
      );

      expect(viewModel.rediagnose()).assertTrue();
      expect(stack.paths.length).assertEqual(1);
      expect(store.currentSession?.sessionId).assertEqual('session-report');
    });

    it('saves the current report once and refreshes recent records', 0, async () => {
      const repository = new FakeReportRepository();
      const saved = createReportFixture('pending-report', 1, 2000);
      repository.saveResult = createSuccessResult(saved);
      let refreshCount: number = 0;
      const viewModel = new ReportViewModel(
        createStore(),
        repository,
        new AppRouter(new FakeNavigationStack()),
        { sessionId: 'session-report', origin: RouteName.DIAGNOSIS },
        async (): Promise<boolean> => {
          refreshCount++;
          return true;
        }
      );

      expect(await viewModel.saveReport()).assertTrue();
      expect(viewModel.saveOperation.status).assertEqual(OperationStatus.SUCCESS);
      expect(viewModel.report?.savedAt).assertEqual(2000);
      expect(repository.saveCallCount).assertEqual(1);
      expect(refreshCount).assertEqual(1);

      expect(await viewModel.saveReport()).assertTrue();
      expect(repository.saveCallCount).assertEqual(1);
      expect(refreshCount).assertEqual(1);
    });

    it('publishes the saved report to the home recent list through the refresh callback', 0, async () => {
      const repository = new FakeReportRepository();
      const saved = createReportFixture('pending-report', 1, 2000);
      repository.saveResult = createSuccessResult(saved);
      repository.recentResult = createSuccessResult([saved]);
      const homeViewModel = new HomeViewModel(repository);
      const viewModel = new ReportViewModel(
        createStore(),
        repository,
        new AppRouter(new FakeNavigationStack()),
        { sessionId: 'session-report', origin: RouteName.DIAGNOSIS },
        (): Promise<boolean> => homeViewModel.loadRecent()
      );

      expect(await viewModel.saveReport()).assertTrue();
      expect(homeViewModel.recentReports.length).assertEqual(1);
      expect(homeViewModel.recentReports[0].reportId).assertEqual('pending-report');
      expect(repository.recentLimit).assertEqual(3);
    });

    it('blocks a repeated save while the first request is still loading', 0, async () => {
      const repository = new FakeReportRepository();
      const deferred = new DeferredSingleReportResult();
      repository.deferredSave = deferred;
      const viewModel = new ReportViewModel(
        createStore(),
        repository,
        new AppRouter(new FakeNavigationStack()),
        { sessionId: 'session-report', origin: RouteName.DIAGNOSIS }
      );

      const first = viewModel.saveReport();
      expect(viewModel.saveOperation.status).assertEqual(OperationStatus.LOADING);
      expect(await viewModel.saveReport()).assertFalse();
      expect(repository.saveCallCount).assertEqual(1);
      deferred.resolve(createSuccessResult(createReportFixture('pending-report', 1, 2000)));
      expect(await first).assertTrue();
    });

    it('retains the report after save failure and allows retry', 0, async () => {
      const repository = new FakeReportRepository();
      repository.saveResult = createFailureResult({
        code: ErrorCode.STORAGE_WRITE_FAILED,
        message: 'Synthetic storage failure',
        retryable: true
      });
      const viewModel = new ReportViewModel(
        createStore(),
        repository,
        new AppRouter(new FakeNavigationStack()),
        { sessionId: 'session-report', origin: RouteName.DIAGNOSIS }
      );

      expect(await viewModel.saveReport()).assertFalse();
      expect(viewModel.saveOperation.status).assertEqual(OperationStatus.ERROR);
      expect(viewModel.report?.id).assertEqual('pending-report');

      repository.saveResult = createSuccessResult(createReportFixture('pending-report', 1, 3000));
      expect(await viewModel.saveReport()).assertTrue();
      expect(repository.saveCallCount).assertEqual(2);
      expect(viewModel.report?.savedAt).assertEqual(3000);
    });

    it('keeps a loaded historical report when repository reading fails and can retry', 0, async () => {
      const repository = new FakeReportRepository();
      repository.getByIdResult = createFailureResult({
        code: ErrorCode.STORAGE_READ_FAILED,
        message: 'Synthetic read failure',
        retryable: true
      });
      const viewModel = new ReportViewModel(
        createStore(false),
        repository,
        new AppRouter(new FakeNavigationStack()),
        { reportId: 'history-retry', origin: RouteName.HISTORY_SETTINGS }
      );

      expect(await viewModel.loadReport()).assertFalse();
      expect(viewModel.reportOperation.status).assertEqual(OperationStatus.ERROR);
      repository.getByIdResult = createSuccessResult(createReportFixture('history-retry', 1, 2));
      expect(await viewModel.loadReport()).assertTrue();
      expect(viewModel.report?.id).assertEqual('history-retry');
    });
  });
}
