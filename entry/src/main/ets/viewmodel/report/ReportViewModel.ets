import { ErrorCode } from '../../constants/ErrorCodes';
import { DiagnosisReport } from '../../model/DiagnosisModels';
import {
  AppError,
  AppResult,
  createErrorOperationState,
  OperationState,
  OperationStatus
} from '../../model/ResultModels';
import { ReportRepository } from '../../repository/report/ReportRepository';
import { AppRouter } from '../../router/AppRouter';
import { ReportRouteParams } from '../../router/RouteModels';
import { DiagnosisSessionStore } from '../../store/DiagnosisSessionStore';

function copyError(error: AppError | undefined): AppError | undefined {
  if (error === undefined) {
    return undefined;
  }
  const copied: AppError = {
    code: error.code,
    message: error.message,
    retryable: error.retryable
  };
  if (error.causeType !== undefined) {
    copied.causeType = error.causeType;
  }
  if (error.correlationId !== undefined) {
    copied.correlationId = error.correlationId;
  }
  return copied;
}

function copyOperation(state: OperationState): OperationState {
  const copied: OperationState = {
    status: state.status
  };
  if (state.error !== undefined) {
    copied.error = copyError(state.error);
  }
  if (state.correlationId !== undefined) {
    copied.correlationId = state.correlationId;
  }
  return copied;
}

function copyReport(report: DiagnosisReport): DiagnosisReport {
  const copied: DiagnosisReport = {
    id: report.id,
    errorType: report.errorType,
    summary: report.summary,
    evidence: report.evidence.slice(),
    possibleCauses: report.possibleCauses.slice(),
    steps: report.steps.slice(),
    rawText: report.rawText,
    sourceType: report.sourceType,
    createdAt: report.createdAt,
    isFavorite: report.isFavorite,
    engineVersion: report.engineVersion
  };
  if (report.secondaryTags !== undefined) {
    copied.secondaryTags = report.secondaryTags.slice();
  }
  if (report.suggestions !== undefined) {
    copied.suggestions = report.suggestions.slice();
  }
  if (report.riskNotice !== undefined) {
    copied.riskNotice = report.riskNotice;
  }
  if (report.savedAt !== undefined) {
    copied.savedAt = report.savedAt;
  }
  return copied;
}

function routeError(): AppError {
  return {
    code: ErrorCode.ROUTE_PARAM_INVALID,
    message: '当前诊断会话已失效，请返回后重新诊断。',
    retryable: false,
    causeType: 'REPORT_SESSION_INVALID'
  };
}

function missingReportError(): AppError {
  return {
    code: ErrorCode.REPORT_NOT_FOUND,
    message: '当前会话还没有可展示的诊断报告。',
    retryable: false,
    causeType: 'PENDING_REPORT_MISSING'
  };
}

function historicalReadError(error: AppError | undefined): AppError {
  return {
    code: error?.code ?? ErrorCode.STORAGE_READ_FAILED,
    message: error?.code === ErrorCode.REPORT_NOT_FOUND ? '这份历史报告不存在或已被移除。' :
      '暂时无法读取这份历史报告，请重试。',
    retryable: error?.code !== ErrorCode.REPORT_NOT_FOUND,
    causeType: 'HISTORICAL_REPORT_READ'
  };
}

function saveError(error: AppError | undefined): AppError {
  return {
    code: error?.code ?? ErrorCode.STORAGE_WRITE_FAILED,
    message: '保存失败，当前报告已保留，请重试。',
    retryable: true,
    causeType: 'REPORT_SAVE'
  };
}

/** Owns report loading and saving without exposing Repository operations to the page. */
@Observed
export class ReportViewModel {
  private store: DiagnosisSessionStore;
  private repository: ReportRepository;
  private router: AppRouter;
  private onReportSaved?: () => Promise<boolean>;
  private sessionId?: string;
  private reportId?: string;
  private currentReport?: DiagnosisReport;
  private operationState: OperationState;
  private saveOperationState: OperationState = { status: OperationStatus.IDLE };
  private disposed: boolean = false;
  private lifecycleGeneration: number = 0;

  constructor(
    store: DiagnosisSessionStore,
    repository: ReportRepository,
    router: AppRouter,
    routeParams: ReportRouteParams,
    onReportSaved?: () => Promise<boolean>
  ) {
    this.store = store;
    this.repository = repository;
    this.router = router;
    this.onReportSaved = onReportSaved;
    this.operationState = {
      status: OperationStatus.IDLE
    };
    if (routeParams.reportId !== undefined && routeParams.sessionId !== undefined) {
      this.operationState = createErrorOperationState(routeError());
      return;
    }
    if (routeParams.reportId !== undefined) {
      this.reportId = routeParams.reportId;
      this.operationState = { status: OperationStatus.LOADING };
      return;
    }
    if (routeParams.sessionId === undefined) {
      this.operationState = createErrorOperationState(routeError());
      return;
    }
    const session = store.findCurrentSession(routeParams.sessionId);
    if (session === undefined) {
      this.operationState = createErrorOperationState(routeError());
      return;
    }
    this.sessionId = session.sessionId;
    if (session.pendingReport === undefined) {
      this.operationState = createErrorOperationState(missingReportError());
      return;
    }
    this.currentReport = copyReport(session.pendingReport);
    if (this.currentReport.savedAt !== undefined) {
      this.saveOperationState = { status: OperationStatus.SUCCESS };
    }
    this.operationState = {
      status: OperationStatus.SUCCESS
    };
  }

  get reportOperation(): OperationState {
    return copyOperation(this.operationState);
  }

  get reportError(): AppError | undefined {
    return copyError(this.operationState.error);
  }

  get report(): DiagnosisReport | undefined {
    return this.currentReport === undefined ? undefined : copyReport(this.currentReport);
  }

  get saveOperation(): OperationState {
    return copyOperation(this.saveOperationState);
  }

  get saveError(): AppError | undefined {
    return copyError(this.saveOperationState.error);
  }

  get isSaved(): boolean {
    return this.currentReport?.savedAt !== undefined;
  }

  get hasEditableSession(): boolean {
    return this.hasActiveSession();
  }

  async loadReport(): Promise<boolean> {
    if (this.disposed || this.reportId === undefined) {
      return this.currentReport !== undefined;
    }
    if (this.operationState.status === OperationStatus.LOADING && this.currentReport !== undefined) {
      return false;
    }
    const generation = this.lifecycleGeneration;
    this.operationState = { status: OperationStatus.LOADING };
    let result: AppResult<DiagnosisReport>;
    try {
      result = await this.repository.getById(this.reportId);
    } catch (_) {
      result = { success: false, error: historicalReadError(undefined) };
    }
    if (this.disposed || generation !== this.lifecycleGeneration) {
      return false;
    }
    if (!result.success || result.data === undefined) {
      this.operationState = createErrorOperationState(historicalReadError(result.error));
      return false;
    }
    this.currentReport = copyReport(result.data);
    this.operationState = { status: OperationStatus.SUCCESS };
    this.saveOperationState = { status: OperationStatus.SUCCESS };
    return true;
  }

  async saveReport(): Promise<boolean> {
    if (this.disposed || this.currentReport === undefined) {
      return false;
    }
    if (this.isSaved) {
      this.saveOperationState = { status: OperationStatus.SUCCESS };
      return true;
    }
    if (this.saveOperationState.status === OperationStatus.LOADING) {
      return false;
    }
    const generation = this.lifecycleGeneration;
    this.saveOperationState = { status: OperationStatus.LOADING };
    let result: AppResult<DiagnosisReport>;
    try {
      result = await this.repository.save(copyReport(this.currentReport));
    } catch (_) {
      result = { success: false, error: saveError(undefined) };
    }
    if (this.disposed || generation !== this.lifecycleGeneration) {
      return false;
    }
    if (!result.success || result.data === undefined) {
      this.saveOperationState = createErrorOperationState(saveError(result.error));
      return false;
    }
    this.currentReport = copyReport(result.data);
    this.saveOperationState = { status: OperationStatus.SUCCESS };
    if (this.onReportSaved !== undefined) {
      try {
        await this.onReportSaved();
      } catch (_) {
      }
    }
    return true;
  }

  editInput(): boolean {
    if (!this.hasActiveSession()) {
      return false;
    }
    this.router.back();
    return true;
  }

  rediagnose(): boolean {
    return this.editInput();
  }

  backToOrigin(): void {
    if (!this.disposed) {
      this.router.back();
    }
  }

  dispose(): void {
    this.disposed = true;
    this.lifecycleGeneration++;
    if (this.operationState.status === OperationStatus.LOADING) {
      this.operationState = { status: OperationStatus.CANCELLED };
    }
    if (this.saveOperationState.status === OperationStatus.LOADING) {
      this.saveOperationState = { status: OperationStatus.CANCELLED };
    }
  }

  private hasActiveSession(): boolean {
    return !this.disposed && this.sessionId !== undefined &&
      this.store.findCurrentSession(this.sessionId) !== undefined;
  }
}
