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

export class FakeReportRepository implements ReportRepository {
  recentResult: AppResult<Array<DiagnosisReport>> = createSuccessResult<Array<DiagnosisReport>>([]);
  recentLimit: number = 0;
  recentCallCount: number = 0;
  deferredRecent?: DeferredReportResult;
  throwOnRecent: boolean = false;

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
    return createSuccessResult<DiagnosisReport>(report);
  }

  async getById(reportId: string): Promise<AppResult<DiagnosisReport>> {
    return createFailureResult<DiagnosisReport>({
      code: ErrorCode.REPORT_NOT_FOUND,
      message: `Synthetic missing report: ${reportId}`,
      retryable: false
    });
  }

  async list(offset: number, limit: number): Promise<AppResult<Array<DiagnosisReport>>> {
    return createSuccessResult<Array<DiagnosisReport>>([]);
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
