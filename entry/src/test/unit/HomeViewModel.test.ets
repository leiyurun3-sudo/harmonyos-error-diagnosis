import { describe, expect, it } from '@ohos/hypium';
import { ErrorCode } from '../../main/ets/constants/ErrorCodes';
import { OperationStatus, createFailureResult, createSuccessResult } from '../../main/ets/model/ResultModels';
import { HomeViewModel } from '../../main/ets/viewmodel/home/HomeViewModel';
import { HomeReportItem } from '../../main/ets/viewmodel/home/HomeModels';
import { DeferredReportResult, FakeReportRepository } from '../fakes/FakeReportRepository';
import { createReportFixture } from '../fixtures/ReportFixtures';

export default function homeViewModelTest() {
  describe('HomeViewModel', () => {
    it('starts idle without reports error or a successful result', 0, () => {
      const viewModel = new HomeViewModel(new FakeReportRepository());

      expect(viewModel.recentStatus).assertEqual(OperationStatus.IDLE);
      expect(viewModel.recentReports.length).assertEqual(0);
      expect(viewModel.recentError === undefined).assertTrue();
      expect(viewModel.hasSuccessfulLoad).assertFalse();
    });

    it('publishes loading immediately before recent reports resolve', 0, async () => {
      const repository = new FakeReportRepository();
      repository.deferredRecent = new DeferredReportResult();
      const viewModel = new HomeViewModel(repository);

      const loading = viewModel.loadRecent();

      expect(viewModel.recentStatus).assertEqual(OperationStatus.LOADING);
      expect(repository.recentLimit).assertEqual(3);
      repository.deferredRecent.resolve(createSuccessResult([]));
      await loading;
    });

    it('publishes at most three recent reports after a successful read', 0, async () => {
      const repository = new FakeReportRepository();
      repository.recentResult = createSuccessResult([
        createReportFixture('synthetic-recent-1', 1, 4),
        createReportFixture('synthetic-recent-2', 1, 3),
        createReportFixture('synthetic-recent-3', 1, 2)
      ]);
      const viewModel = new HomeViewModel(repository);

      const loaded = await viewModel.loadRecent();

      expect(loaded).assertTrue();
      expect(viewModel.recentStatus).assertEqual(OperationStatus.SUCCESS);
      expect(viewModel.recentReports.length).assertEqual(3);
      expect(viewModel.recentError === undefined).assertTrue();
    });

    it('sorts an oversized repository result by savedAt and exposes only three items', 0, async () => {
      const repository = new FakeReportRepository();
      repository.recentResult = createSuccessResult([
        createReportFixture('synthetic-oldest', 1, 1),
        createReportFixture('synthetic-newest', 1, 5),
        createReportFixture('synthetic-middle-1', 1, 3),
        createReportFixture('synthetic-middle-2', 1, 4),
        createReportFixture('synthetic-middle-3', 1, 2)
      ]);
      const viewModel = new HomeViewModel(repository);

      await viewModel.loadRecent();

      expect(viewModel.recentReports.map((item: HomeReportItem): string => item.reportId).join(','))
        .assertEqual('synthetic-newest,synthetic-middle-2,synthetic-middle-1');
    });

    it('publishes an empty successful state when history has no reports', 0, async () => {
      const viewModel = new HomeViewModel(new FakeReportRepository());

      await viewModel.loadRecent();

      expect(viewModel.recentStatus).assertEqual(OperationStatus.SUCCESS);
      expect(viewModel.recentReports.length).assertEqual(0);
      expect(viewModel.isRecentEmpty).assertTrue();
    });

    it('publishes a retryable local error without clearing last valid reports', 0, async () => {
      const repository = new FakeReportRepository();
      repository.recentResult = createSuccessResult([createReportFixture('synthetic-retained', 1, 2)]);
      const viewModel = new HomeViewModel(repository);
      await viewModel.loadRecent();
      repository.recentResult = createFailureResult({
        code: ErrorCode.STORAGE_READ_FAILED,
        message: 'Synthetic history read failed',
        retryable: true
      });

      const loaded = await viewModel.loadRecent();

      expect(loaded).assertFalse();
      expect(viewModel.recentStatus).assertEqual(OperationStatus.ERROR);
      expect(viewModel.recentReports.length).assertEqual(1);
      expect(viewModel.recentError?.code).assertEqual(ErrorCode.STORAGE_READ_FAILED);
      expect(viewModel.recentError?.message.includes('Synthetic')).assertFalse();
    });

    it('returns isolated page items that cannot mutate repository or view model state', 0, async () => {
      const repository = new FakeReportRepository();
      const report = createReportFixture('synthetic-isolated-home', 1, 2);
      repository.recentResult = createSuccessResult([report]);
      const viewModel = new HomeViewModel(repository);
      await viewModel.loadRecent();

      const first = viewModel.recentReports;
      first[0].summary = 'MUTATED_PAGE_SUMMARY';
      first.push(first[0]);

      expect(viewModel.recentReports.length).assertEqual(1);
      expect(viewModel.recentReports[0].summary).assertEqual('Synthetic report summary');
      expect(report.summary).assertEqual('Synthetic report summary');
    });

    it('converts a thrown repository error and succeeds when retried', 0, async () => {
      const repository = new FakeReportRepository();
      repository.throwOnRecent = true;
      const viewModel = new HomeViewModel(repository);

      expect(await viewModel.loadRecent()).assertFalse();
      repository.throwOnRecent = false;
      repository.recentResult = createSuccessResult([createReportFixture('synthetic-retry', 1, 2)]);

      expect(await viewModel.retryRecent()).assertTrue();
      expect(repository.recentCallCount).assertEqual(2);
      expect(viewModel.recentStatus).assertEqual(OperationStatus.SUCCESS);
    });

    it('ignores a duplicate load while the current read is pending', 0, async () => {
      const repository = new FakeReportRepository();
      repository.deferredRecent = new DeferredReportResult();
      const viewModel = new HomeViewModel(repository);
      const first = viewModel.loadRecent();

      const second = await viewModel.loadRecent();

      expect(second).assertFalse();
      expect(repository.recentCallCount).assertEqual(1);
      repository.deferredRecent.resolve(createSuccessResult([]));
      await first;
    });

    it('does not publish a pending result after disposal', 0, async () => {
      const repository = new FakeReportRepository();
      repository.deferredRecent = new DeferredReportResult();
      const viewModel = new HomeViewModel(repository);
      const loading = viewModel.loadRecent();
      viewModel.dispose();

      repository.deferredRecent.resolve(createSuccessResult([
        createReportFixture('synthetic-stale', 1, 2)
      ]));
      await loading;

      expect(viewModel.recentStatus).assertEqual(OperationStatus.CANCELLED);
      expect(viewModel.recentReports.length).assertEqual(0);
    });
  });
}
