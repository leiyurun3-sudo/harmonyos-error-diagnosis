import { ErrorCode } from '../../constants/ErrorCodes';
import { DiagnosisReport } from '../../model/DiagnosisModels';
import {
  AppResult,
  createFailureResult
} from '../../model/ResultModels';
import { ReportDataStore } from '../../repository/report/ReportRepository';
import {
  DatabaseManager,
  DatabaseStore
} from './DatabaseManager';
import { ReportStore } from './ReportStore';
import { HiLogService } from '../../service/platform/HiLogService';

/** Lazily initializes the real relationalStore so first render never waits for database setup. */
export class LazyReportDataStore implements ReportDataStore {
  private manager: DatabaseManager;
  private logger: HiLogService;
  private store?: ReportStore;
  private initialization?: Promise<AppResult<DatabaseStore>>;

  constructor(manager: DatabaseManager, logger: HiLogService) {
    this.manager = manager;
    this.logger = logger;
  }

  async insert(report: DiagnosisReport): Promise<AppResult<number>> {
    const store = await this.resolveStore<number>(ErrorCode.STORAGE_WRITE_FAILED);
    return store instanceof ReportStore ? store.insert(report) : store;
  }

  async getById(reportId: string): Promise<AppResult<DiagnosisReport>> {
    const store = await this.resolveStore<DiagnosisReport>(ErrorCode.STORAGE_READ_FAILED);
    return store instanceof ReportStore ? store.getById(reportId) : store;
  }

  async list(offset: number, limit: number): Promise<AppResult<Array<DiagnosisReport>>> {
    const store = await this.resolveStore<Array<DiagnosisReport>>(ErrorCode.STORAGE_READ_FAILED);
    return store instanceof ReportStore ? store.list(offset, limit) : store;
  }

  async deleteById(reportId: string): Promise<AppResult<boolean>> {
    const store = await this.resolveStore<boolean>(ErrorCode.STORAGE_DELETE_FAILED);
    return store instanceof ReportStore ? store.deleteById(reportId) : store;
  }

  async clearAll(): Promise<AppResult<number>> {
    const store = await this.resolveStore<number>(ErrorCode.STORAGE_DELETE_FAILED);
    return store instanceof ReportStore ? store.clearAll() : store;
  }

  close(): Promise<AppResult<void>> {
    this.store = undefined;
    this.initialization = undefined;
    return this.manager.close();
  }

  private async resolveStore<T>(code: ErrorCode): Promise<ReportStore | AppResult<T>> {
    if (this.store !== undefined) {
      return this.store;
    }
    if (this.initialization === undefined) {
      this.initialization = this.manager.initialize();
    }
    const initialized = await this.initialization;
    if (!initialized.success || initialized.data === undefined) {
      this.initialization = undefined;
      return createFailureResult<T>({
        code: initialized.error?.code ?? code,
        message: '本地报告暂时不可用，请稍后重试。',
        retryable: true,
        causeType: 'REPORT_DATABASE_INITIALIZATION'
      });
    }
    this.store = new ReportStore(initialized.data, this.logger);
    return this.store;
  }
}
