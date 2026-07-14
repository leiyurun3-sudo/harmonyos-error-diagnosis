import { ErrorCode } from '../../constants/ErrorCodes';
import { DiagnosisReport } from '../../model/DiagnosisModels';
import {
  AppError,
  AppResult,
  OperationState,
  OperationStatus
} from '../../model/ResultModels';
import { ReportRepository } from '../../repository/report/ReportRepository';
import {
  copyHomeReportItems,
  createHomeReportItem,
  HomeReportItem
} from './HomeModels';

const RECENT_LIMIT: number = 3;

function safeRecentError(error: AppError | undefined): AppError {
  return {
    code: error?.code ?? ErrorCode.STORAGE_READ_FAILED,
    message: '暂时无法读取最近记录，请稍后重试。',
    retryable: true,
    causeType: 'HOME_RECENT_READ'
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
export class HomeViewModel {
  private repository: ReportRepository;
  private recentItems: Array<HomeReportItem> = [];
  private recentOperationValue: OperationState = { status: OperationStatus.IDLE };
  private hasSuccessfulLoadValue: boolean = false;
  private lifecycleGeneration: number = 0;

  constructor(repository: ReportRepository) {
    this.repository = repository;
  }

  get recentReports(): Array<HomeReportItem> {
    return copyHomeReportItems(this.recentItems);
  }

  get recentOperation(): OperationState {
    return {
      status: this.recentOperationValue.status,
      error: copyError(this.recentOperationValue.error)
    };
  }

  get recentStatus(): OperationStatus {
    return this.recentOperationValue.status;
  }

  get recentError(): AppError | undefined {
    return copyError(this.recentOperationValue.error);
  }

  get hasSuccessfulLoad(): boolean {
    return this.hasSuccessfulLoadValue;
  }

  get isRecentEmpty(): boolean {
    return this.hasSuccessfulLoadValue && this.recentItems.length === 0;
  }

  async loadRecent(): Promise<boolean> {
    if (this.recentOperationValue.status === OperationStatus.LOADING) {
      return false;
    }
    const generation = this.lifecycleGeneration;
    this.recentOperationValue = { status: OperationStatus.LOADING };
    let result: AppResult<Array<DiagnosisReport>>;
    try {
      result = await this.repository.getRecent(RECENT_LIMIT);
    } catch (_) {
      result = { success: false, error: safeRecentError(undefined) };
    }
    if (generation !== this.lifecycleGeneration) {
      return false;
    }
    if (!result.success || result.data === undefined) {
      this.recentOperationValue = {
        status: OperationStatus.ERROR,
        error: safeRecentError(result.error)
      };
      return false;
    }
    const sorted = result.data.slice().sort((left: DiagnosisReport, right: DiagnosisReport): number =>
      (right.savedAt ?? 0) - (left.savedAt ?? 0));
    this.recentItems = sorted.slice(0, RECENT_LIMIT).map(
      (report: DiagnosisReport): HomeReportItem => createHomeReportItem(report)
    );
    this.hasSuccessfulLoadValue = true;
    this.recentOperationValue = { status: OperationStatus.SUCCESS };
    return true;
  }

  retryRecent(): Promise<boolean> {
    return this.loadRecent();
  }

  dispose(): void {
    this.lifecycleGeneration++;
    if (this.recentOperationValue.status === OperationStatus.LOADING) {
      this.recentOperationValue = { status: OperationStatus.CANCELLED };
    }
  }
}
