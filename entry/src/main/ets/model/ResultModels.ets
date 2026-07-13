/** Read-only HTTP status metadata loaded from a bundled resource. */
export interface HttpStatusEntry {
  code: number;
  name: string;
  category: string;
  description: string;
  causes: Array<string>;
  steps: Array<string>;
}

/** Stable cross-layer error contract. Raw platform exceptions must not escape through it. */
export interface AppError {
  code: string;
  message: string;
  retryable: boolean;
  causeType?: string;
  correlationId?: string;
}

/** Cross-layer result contract used by Repository and Service boundaries. */
export interface AppResult<T> {
  success: boolean;
  data?: T;
  error?: AppError;
}

/** Semantic status for one asynchronous operation. */
export enum OperationStatus {
  IDLE = 'IDLE',
  LOADING = 'LOADING',
  SUCCESS = 'SUCCESS',
  ERROR = 'ERROR',
  CANCELLED = 'CANCELLED'
}

/** Page-independent operation state. Page messages are deliberately excluded. */
export interface OperationState {
  status: OperationStatus;
  error?: AppError;
  correlationId?: string;
}

function copyAppError(error: AppError): AppError {
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

/** Creates the valid success shape. */
export function createSuccessResult<T>(data: T): AppResult<T> {
  return {
    success: true,
    data: data
  };
}

/** Creates the valid failure shape and isolates it from caller mutation. */
export function createFailureResult<T>(error: AppError): AppResult<T> {
  return {
    success: false,
    error: copyAppError(error)
  };
}

/** Checks the structural invariants documented for an AppResult. */
export function isValidAppResult<T>(result: AppResult<T>): boolean {
  if (result.success) {
    return result.error === undefined;
  }
  if (result.error === undefined || result.data !== undefined) {
    return false;
  }
  return result.error.code.trim().length > 0 && result.error.message.trim().length > 0;
}

/** Returns a new IDLE state for an operation. */
export function createInitialOperationState(): OperationState {
  return {
    status: OperationStatus.IDLE
  };
}

/** Returns an isolated ERROR state correlated with its AppError when available. */
export function createErrorOperationState(error: AppError): OperationState {
  const state: OperationState = {
    status: OperationStatus.ERROR,
    error: copyAppError(error)
  };
  if (error.correlationId !== undefined) {
    state.correlationId = error.correlationId;
  }
  return state;
}
