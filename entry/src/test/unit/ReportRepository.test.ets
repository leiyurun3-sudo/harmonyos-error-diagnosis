import { describe, expect, it } from '@ohos/hypium';
import { HISTORY_RECORD_LIMIT } from '../../main/ets/constants/AppLimits';
import { ErrorCode } from '../../main/ets/constants/ErrorCodes';
import { DiagnosisReport } from '../../main/ets/model/DiagnosisModels';
import { LocalReportRepository } from '../../main/ets/repository/report/LocalReportRepository';
import { HiLogService } from '../../main/ets/service/platform/HiLogService';
import { CapturingLogSink } from '../fakes/CapturingLogSink';
import {
  FakeReportStore,
  FixedTimeSource,
  ReportStoreFailureStage
} from '../fakes/FakeReportStore';
import { createReportFixture } from '../fixtures/ReportFixtures';

const SAVED_AT: number = 1700000009000;

function repository(
  store: FakeReportStore,
  sink: CapturingLogSink = new CapturingLogSink()
): LocalReportRepository {
  return new LocalReportRepository(store, new FixedTimeSource(SAVED_AT), new HiLogService(sink));
}

function seedReports(store: FakeReportStore, count: number, favorite: boolean = false): void {
  for (let index: number = 0; index < count; index++) {
    store.seed(createReportFixture(
      `synthetic-seed-${index}`,
      1700000000000 + index,
      1700000000000 + index,
      favorite
    ));
  }
}

export default function reportRepositoryTest() {
  describe('LocalReportRepository', () => {
    it('sets savedAt on first save without changing createdAt', 0, async () => {
      const store = new FakeReportStore();
      const input = createReportFixture('synthetic-first', 1700000000123);

      const result = await repository(store).save(input);

      expect(result.success).assertTrue();
      expect(result.data?.savedAt).assertEqual(SAVED_AT);
      expect(result.data?.createdAt).assertEqual(1700000000123);
      expect(input.savedAt === undefined).assertTrue();
      expect(input.createdAt).assertEqual(1700000000123);
    });

    it('does not insert a duplicate id and returns the existing saved report', 0, async () => {
      const store = new FakeReportStore();
      store.seed(createReportFixture('synthetic-duplicate', 1, 1234));

      const result = await repository(store).save(createReportFixture('synthetic-duplicate', 2));

      expect(result.success).assertTrue();
      expect(result.data?.createdAt).assertEqual(1);
      expect(result.data?.savedAt).assertEqual(1234);
      expect(store.insertCount).assertEqual(0);
      expect(store.reports.length).assertEqual(1);
    });

    it('isolates saved input returned data and persisted arrays', 0, async () => {
      const store = new FakeReportStore();
      const input = createReportFixture('synthetic-isolation');
      const first = await repository(store).save(input);
      input.evidence.push('caller mutation');
      first.data?.steps.push('result mutation');

      const restored = await repository(store).getById('synthetic-isolation');

      expect(restored.data?.evidence.length).assertEqual(1);
      expect(restored.data?.steps.length).assertEqual(1);
      expect(restored.data === input).assertFalse();
    });

    it('gets an existing report and preserves REPORT_NOT_FOUND', 0, async () => {
      const store = new FakeReportStore();
      store.seed(createReportFixture('synthetic-existing', 1, 2));

      expect((await repository(store).getById('synthetic-existing')).success).assertTrue();
      expect((await repository(store).getById('synthetic-missing')).error?.code)
        .assertEqual(ErrorCode.REPORT_NOT_FOUND);
    });

    it('reads a saved report after rebuilding the repository over the same store', 0, async () => {
      const store = new FakeReportStore();
      await repository(store).save(createReportFixture('synthetic-rebuilt-repository'));

      const rebuilt = repository(store);
      const restored = await rebuilt.getById('synthetic-rebuilt-repository');

      expect(restored.success).assertTrue();
      expect(restored.data?.id).assertEqual('synthetic-rebuilt-repository');
      expect(restored.data?.savedAt).assertEqual(SAVED_AT);
    });

    it('validates list pagination and returns the requested descending page', 0, async () => {
      const store = new FakeReportStore();
      seedReports(store, 4);
      const repo = repository(store);

      const page = await repo.list(1, 2);

      expect(page.data?.map((item: DiagnosisReport) => item.id).join(','))
        .assertEqual('synthetic-seed-2,synthetic-seed-1');
      expect((await repo.list(-1, 1)).error?.code).assertEqual(ErrorCode.VAL_FORMAT_INVALID);
      expect((await repo.list(0, 0)).error?.code).assertEqual(ErrorCode.VAL_FORMAT_INVALID);
      expect((await repo.list(0, HISTORY_RECORD_LIMIT + 1)).error?.code)
        .assertEqual(ErrorCode.VAL_FORMAT_INVALID);
    });

    it('returns the latest three reports from getRecent', 0, async () => {
      const store = new FakeReportStore();
      seedReports(store, 5);

      const result = await repository(store).getRecent(3);

      expect(result.data?.map((item: DiagnosisReport) => item.id).join(','))
        .assertEqual('synthetic-seed-4,synthetic-seed-3,synthetic-seed-2');
    });

    it('returns an empty successful list for empty history', 0, async () => {
      const result = await repository(new FakeReportStore()).list(0, 10);

      expect(result.success).assertTrue();
      expect(result.data?.length).assertEqual(0);
    });

    it('returns true for an existing delete and false for a missing delete', 0, async () => {
      const store = new FakeReportStore();
      store.seed(createReportFixture('synthetic-delete', 1, 2));
      const repo = repository(store);

      expect((await repo.deleteById('synthetic-delete')).data).assertTrue();
      expect((await repo.deleteById('synthetic-delete')).data).assertFalse();
    });

    it('clears history and returns the actual deleted count', 0, async () => {
      const store = new FakeReportStore();
      seedReports(store, 3);

      const result = await repository(store).clearAll();

      expect(result.data).assertEqual(3);
      expect(store.reports.length).assertEqual(0);
    });

    it('does not evict when history is at the limit', 0, async () => {
      const store = new FakeReportStore();
      seedReports(store, HISTORY_RECORD_LIMIT);

      const result = await repository(store).enforceHistoryLimit(HISTORY_RECORD_LIMIT);

      expect(result.data).assertEqual(0);
      expect(store.deleteCount).assertEqual(0);
    });

    it('evicts the oldest unfavorited report after the 201st save', 0, async () => {
      const store = new FakeReportStore();
      seedReports(store, HISTORY_RECORD_LIMIT);

      const result = await repository(store).save(createReportFixture('synthetic-newest'));

      expect(result.success).assertTrue();
      expect(store.reports.length).assertEqual(HISTORY_RECORD_LIMIT);
      expect(store.reports.some((item: DiagnosisReport) => item.id === 'synthetic-seed-0')).assertFalse();
      expect(store.reports.some((item: DiagnosisReport) => item.id === 'synthetic-newest')).assertTrue();
    });

    it('retains an older favorite and removes the oldest eligible report', 0, async () => {
      const store = new FakeReportStore();
      seedReports(store, HISTORY_RECORD_LIMIT);
      store.reports[0].isFavorite = true;

      const result = await repository(store).save(createReportFixture('synthetic-newest'));

      expect(result.success).assertTrue();
      expect(store.reports.some((item: DiagnosisReport) => item.id === 'synthetic-seed-0')).assertTrue();
      expect(store.reports.some((item: DiagnosisReport) => item.id === 'synthetic-seed-1')).assertFalse();
    });

    it('does not delete favorites or the just-saved report when all previous reports are favorites', 0,
      async () => {
        const store = new FakeReportStore();
        seedReports(store, HISTORY_RECORD_LIMIT, true);

        const result = await repository(store).save(createReportFixture('synthetic-protected-new'));

        expect(result.error?.code).assertEqual(ErrorCode.STORAGE_WRITE_FAILED);
        expect(store.deleteCount).assertEqual(0);
        expect(store.reports.length).assertEqual(HISTORY_RECORD_LIMIT + 1);
        expect(store.reports.some((item: DiagnosisReport) => item.id === 'synthetic-protected-new')).assertTrue();
      });

    it('validates report identifiers recent limit and history limit', 0, async () => {
      const repo = repository(new FakeReportStore());
      const invalid = createReportFixture('   ');

      expect((await repo.save(invalid)).error?.code).assertEqual(ErrorCode.VAL_FORMAT_INVALID);
      expect((await repo.getById('')).error?.code).assertEqual(ErrorCode.VAL_FORMAT_INVALID);
      expect((await repo.deleteById(' ')).error?.code).assertEqual(ErrorCode.VAL_FORMAT_INVALID);
      expect((await repo.getRecent(0)).error?.code).assertEqual(ErrorCode.VAL_FORMAT_INVALID);
      expect((await repo.enforceHistoryLimit(0)).error?.code).assertEqual(ErrorCode.VAL_FORMAT_INVALID);
      expect((await repo.enforceHistoryLimit(HISTORY_RECORD_LIMIT + 1)).success).assertTrue();
    });

    it('propagates read insert list delete and clear store failures', 0, async () => {
      const store = new FakeReportStore();
      const repo = repository(store);
      store.failureStage = ReportStoreFailureStage.GET;
      expect((await repo.save(createReportFixture('synthetic-fail-get'))).error?.code)
        .assertEqual(ErrorCode.STORAGE_READ_FAILED);
      store.failureStage = ReportStoreFailureStage.INSERT;
      store.seed(createReportFixture('synthetic-other', 1, 2));
      expect((await repo.save(createReportFixture('synthetic-fail-insert'))).error?.code)
        .assertEqual(ErrorCode.STORAGE_WRITE_FAILED);
      store.failureStage = ReportStoreFailureStage.LIST;
      expect((await repo.list(0, 1)).error?.code).assertEqual(ErrorCode.STORAGE_READ_FAILED);
      store.failureStage = ReportStoreFailureStage.DELETE;
      expect((await repo.deleteById('synthetic-other')).error?.code)
        .assertEqual(ErrorCode.STORAGE_DELETE_FAILED);
      store.failureStage = ReportStoreFailureStage.CLEAR;
      expect((await repo.clearAll()).error?.code).assertEqual(ErrorCode.STORAGE_DELETE_FAILED);
    });

    it('returns a deletion error when history eviction fails', 0, async () => {
      const store = new FakeReportStore();
      seedReports(store, HISTORY_RECORD_LIMIT + 1);
      store.failureStage = ReportStoreFailureStage.DELETE;

      const result = await repository(store).enforceHistoryLimit(HISTORY_RECORD_LIMIT);

      expect(result.error?.code).assertEqual(ErrorCode.STORAGE_DELETE_FAILED);
    });

    it('does not expose sensitive report content in duplicate policy or failure logs', 0, async () => {
      const store = new FakeReportStore();
      const sink = new CapturingLogSink();
      const sensitive = createReportFixture('synthetic-log');
      sensitive.rawText = 'PRIVATE_RAW_TEXT_SHOULD_NOT_APPEAR';
      sensitive.summary = 'PRIVATE_SUMMARY_SHOULD_NOT_APPEAR';
      await repository(store, sink).save(sensitive);
      await repository(store, sink).save(sensitive);
      store.failureStage = ReportStoreFailureStage.LIST;
      await repository(store, sink).list(0, 1);

      const logs = JSON.stringify(sink.records);
      expect(logs.includes('PRIVATE_RAW_TEXT_SHOULD_NOT_APPEAR')).assertFalse();
      expect(logs.includes('PRIVATE_SUMMARY_SHOULD_NOT_APPEAR')).assertFalse();
      expect(logs.includes('synthetic-log')).assertFalse();
    });

    it('isolates objects and arrays across repeated reads', 0, async () => {
      const store = new FakeReportStore();
      store.seed(createReportFixture('synthetic-read-copy', 1, 2));
      const repo = repository(store);
      const first = await repo.list(0, 1);
      first.data?.[0].evidence.push('mutation');

      const second = await repo.list(0, 1);

      expect(second.data?.[0].evidence.length).assertEqual(1);
      expect(first.data === second.data).assertFalse();
      expect(first.data?.[0] === second.data?.[0]).assertFalse();
    });
  });
}
