import { ErrorCode } from '../../main/ets/constants/ErrorCodes';
import { DiagnosisReport } from '../../main/ets/model/DiagnosisModels';
import {
  AppResult,
  createFailureResult,
  createSuccessResult
} from '../../main/ets/model/ResultModels';
import { ReportRepository } from '../../main/ets/repository/report/ReportRepository';

export class DeferredReportResult {
  promise: Promise<AppResult<Array<DiagnosisReport>>>;
  private resolver?: (result: AppResult<Array<DiagnosisReport>>) => void;

  constructor() {
    this.promise = new Promise<AppResult<Array<DiagnosisReport>>>(
      (resolve: (result: AppResult<Array<DiagnosisReport>>) => void): void => {
        this.resolver = resolve;
      }
    );
  }

  resolve(result: AppResult<Array<DiagnosisReport>>): void {
    this.resolver?.(result);
  }
}

export class DeferredSingleReportResult {
  promise: Promise<AppResult<DiagnosisReport>>;
  private resolver?: (result: AppResult<DiagnosisReport>) => void;

  constructor() {
    this.promise = new Promise<AppResult<DiagnosisReport>>(
      (resolve: (result: AppResult<DiagnosisReport>) => void): void => {
        this.resolver = resolve;
      }
    );
  }

  resolve(result: AppResult<DiagnosisReport>): void {
    this.resolver?.(result);
  }
}

export class FakeReportRepository implements ReportRepository {
  recentResult: AppResult<Array<DiagnosisReport>> = createSuccessResult<Array<DiagnosisReport>>([]);
  recentLimit: number = 0;
  recentCallCount: number = 0;
  deferredRecent?: DeferredReportResult;
  throwOnRecent: boolean = false;
  saveResult?: AppResult<DiagnosisReport>;
  saveCallCount: number = 0;
  savedInput?: DiagnosisReport;
  deferredSave?: DeferredSingleReportResult;
  throwOnSave: boolean = false;
  getByIdResult?: AppResult<DiagnosisReport>;
  getByIdCallCount: number = 0;
  requestedReportId?: string;
  throwOnGetById: boolean = false;
  listResult: AppResult<Array<DiagnosisReport>> = createSuccessResult<Array<DiagnosisReport>>([]);
  listCallCount: number = 0;
  listOffset: number = -1;
  listLimit: number = 0;
  deferredList?: DeferredReportResult;
  throwOnList: boolean = false;

  async getRecent(limit: number): Promise<AppResult<Array<DiagnosisReport>>> {
    this.recentLimit = limit;
    this.recentCallCount++;
    if (this.throwOnRecent) {
      throw new Error('SYNTHETIC_RECENT_FAILURE');
    }
    if (this.deferredRecent !== undefined) {
      return this.deferredRecent.promise;
    }
    return this.recentResult;
  }

  async save(report: DiagnosisReport): Promise<AppResult<DiagnosisReport>> {
    this.saveCallCount++;
    this.savedInput = report;
    if (this.throwOnSave) {
      throw new Error('SYNTHETIC_SAVE_FAILURE');
    }
    if (this.deferredSave !== undefined) {
      return this.deferredSave.promise;
    }
    return this.saveResult ?? createSuccessResult<DiagnosisReport>(report);
  }

  async getById(reportId: string): Promise<AppResult<DiagnosisReport>> {
    this.getByIdCallCount++;
    this.requestedReportId = reportId;
    if (this.throwOnGetById) {
      throw new Error('SYNTHETIC_GET_FAILURE');
    }
    if (this.getByIdResult !== undefined) {
      return this.getByIdResult;
    }
    return createFailureResult<DiagnosisReport>({
      code: ErrorCode.REPORT_NOT_FOUND,
      message: `Synthetic missing report: ${reportId}`,
      retryable: false
    });
  }

  async list(offset: number, limit: number): Promise<AppResult<Array<DiagnosisReport>>> {
    this.listCallCount++;
    this.listOffset = offset;
    this.listLimit = limit;
    if (this.throwOnList) {
      throw new Error('SYNTHETIC_LIST_FAILURE');
    }
    if (this.deferredList !== undefined) {
      return this.deferredList.promise;
    }
    return this.listResult;
  }

  async deleteById(reportId: string): Promise<AppResult<boolean>> {
    return createSuccessResult<boolean>(false);
  }

  async clearAll(): Promise<AppResult<number>> {
    return createSuccessResult<number>(0);
  }

  async enforceHistoryLimit(limit: number): Promise<AppResult<number>> {
    return createSuccessResult<number>(0);
  }
}
