import { HISTORY_RECORD_LIMIT } from '../../constants/AppLimits';
import { ErrorCode } from '../../constants/ErrorCodes';
import { DiagnosisReport } from '../../model/DiagnosisModels';
import { AppError, AppResult, OperationState, OperationStatus } from '../../model/ResultModels';
import { ReportRepository } from '../../repository/report/ReportRepository';
import { AppRouter } from '../../router/AppRouter';
import { RouteName } from '../../router/RouteNames';
import { copyHomeReportItems, createHomeReportItem, HomeReportItem } from '../home/HomeModels';

function safeHistoryError(error: AppError | undefined): AppError {
  return {
    code: error?.code ?? ErrorCode.STORAGE_READ_FAILED,
    message: '暂时无法读取历史记录，请稍后重试。',
    retryable: true,
    causeType: 'HISTORY_READ'
  };
}

function copyError(error: AppError | undefined): AppError | undefined {
  if (error === undefined) {
    return undefined;
  }
  return {
    code: error.code,
    message: error.message,
    retryable: error.retryable,
    causeType: error.causeType,
    correlationId: error.correlationId
  };
}

@Observed
export class HistoryViewModel {
  private repository: ReportRepository;
  private router: AppRouter;
  private items: Array<HomeReportItem> = [];
  private operationState: OperationState = { status: OperationStatus.IDLE };
  private hasSuccessfulLoadValue: boolean = false;
  private lifecycleGeneration: number = 0;

  constructor(repository: ReportRepository, router: AppRouter) {
    this.repository = repository;
    this.router = router;
  }

  get historyReports(): Array<HomeReportItem> {
    return copyHomeReportItems(this.items);
  }

  get historyStatus(): OperationStatus {
    return this.operationState.status;
  }

  get historyError(): AppError | undefined {
    return copyError(this.operationState.error);
  }

  get isHistoryEmpty(): boolean {
    return this.hasSuccessfulLoadValue && this.items.length === 0;
  }

  async loadHistory(): Promise<boolean> {
    if (this.operationState.status === OperationStatus.LOADING) {
      return false;
    }
    const generation = this.lifecycleGeneration;
    this.operationState = { status: OperationStatus.LOADING };
    let result: AppResult<Array<DiagnosisReport>>;
    try {
      result = await this.repository.list(0, HISTORY_RECORD_LIMIT);
    } catch (_) {
      result = { success: false, error: safeHistoryError(undefined) };
    }
    if (generation !== this.lifecycleGeneration) {
      return false;
    }
    if (!result.success || result.data === undefined) {
      this.operationState = {
        status: OperationStatus.ERROR,
        error: safeHistoryError(result.error)
      };
      return false;
    }
    const sorted = result.data.slice().sort((left: DiagnosisReport, right: DiagnosisReport): number =>
      (right.savedAt ?? 0) - (left.savedAt ?? 0));
    this.items = sorted.map((report: DiagnosisReport): HomeReportItem => createHomeReportItem(report));
    this.hasSuccessfulLoadValue = true;
    this.operationState = { status: OperationStatus.SUCCESS };
    return true;
  }

  retryHistory(): Promise<boolean> {
    return this.loadHistory();
  }

  openReport(reportId: string): boolean {
    return this.router.openReport({
      reportId: reportId,
      origin: RouteName.HISTORY_SETTINGS
    }).success;
  }

  dispose(): void {
    this.lifecycleGeneration++;
    if (this.operationState.status === OperationStatus.LOADING) {
      this.operationState = { status: OperationStatus.CANCELLED };
    }
  }
}
