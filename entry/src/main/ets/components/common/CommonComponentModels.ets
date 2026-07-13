import {
  AppError,
  OperationStatus
} from '../../model/ResultModels';

export enum NoticeSeverity {
  INFO = 'INFO',
  WARNING = 'WARNING',
  ERROR = 'ERROR'
}

export interface AsyncStatePresentation {
  status: OperationStatus;
  message: string;
  showLoading: boolean;
  showError: boolean;
  showRetry: boolean;
  showContent: boolean;
}

export interface EmptyStatePresentation {
  title: string;
  description: string;
  actionLabel: string;
  showAction: boolean;
}

export interface InlineNoticePresentation {
  message: string;
  severity: NoticeSeverity;
  actionLabel: string;
  showAction: boolean;
  showDismiss: boolean;
}

export interface ConfirmPresentation {
  title: string;
  message: string;
  dangerous: boolean;
  dangerLabel: string;
  confirmLabel: string;
  cancelLabel: string;
}

export type ComponentAction = () => void;

function normalizedText(value: string | undefined, fallback: string): string {
  if (value === undefined || value.trim().length === 0) {
    return fallback;
  }
  return value.trim();
}

function safeAsyncMessage(message: string, error: AppError | undefined): string {
  if (error !== undefined && error.message.trim().length > 0) {
    return error.message.trim();
  }
  return message.trim();
}

/** Maps OperationState data to presentation flags without serializing AppError metadata. */
export function createAsyncStatePresentation(
  status: OperationStatus,
  message: string,
  showContent: boolean,
  error: AppError | undefined,
  retryAvailable: boolean
): AsyncStatePresentation {
  return {
    status: status,
    message: safeAsyncMessage(message, status === OperationStatus.ERROR ? error : undefined),
    showLoading: status === OperationStatus.LOADING,
    showError: status === OperationStatus.ERROR,
    showRetry: status === OperationStatus.ERROR && retryAvailable,
    showContent: showContent
  };
}

export function createEmptyStatePresentation(
  title: string,
  description: string,
  actionLabel: string | undefined,
  actionAvailable: boolean
): EmptyStatePresentation {
  const normalizedAction = actionLabel === undefined ? '' : actionLabel.trim();
  return {
    title: normalizedText(title, '暂无内容'),
    description: normalizedText(description, '当前没有可展示的内容。'),
    actionLabel: normalizedAction,
    showAction: normalizedAction.length > 0 && actionAvailable
  };
}

export function createInlineNoticePresentation(
  message: string,
  severity: NoticeSeverity,
  actionLabel: string | undefined,
  actionAvailable: boolean,
  dismissAvailable: boolean
): InlineNoticePresentation {
  const normalizedAction = actionLabel === undefined ? '' : actionLabel.trim();
  return {
    message: normalizedText(message, '操作遇到问题，请稍后重试。'),
    severity: severity,
    actionLabel: normalizedAction,
    showAction: normalizedAction.length > 0 && actionAvailable,
    showDismiss: dismissAvailable
  };
}

export function createConfirmPresentation(
  title: string,
  message: string,
  dangerous: boolean
): ConfirmPresentation {
  return {
    title: normalizedText(title, '请确认操作'),
    message: normalizedText(message, '请确认是否继续。'),
    dangerous: dangerous,
    dangerLabel: dangerous ? '危险操作，确认后无法自动恢复' : '请确认后继续',
    confirmLabel: dangerous ? '确认危险操作' : '确认',
    cancelLabel: '取消'
  };
}

/** Prevents confirm/cancel callbacks from firing more than once for one dialog opening. */
export class ConfirmEventGate {
  private handled: boolean = false;

  confirm(action: ComponentAction): boolean {
    return this.handle(action);
  }

  cancel(action: ComponentAction): boolean {
    return this.handle(action);
  }

  reset(): void {
    this.handled = false;
  }

  private handle(action: ComponentAction): boolean {
    if (this.handled) {
      return false;
    }
    this.handled = true;
    action();
    return true;
  }
}
