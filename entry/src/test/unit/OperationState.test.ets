import { describe, expect, it } from '@ohos/hypium';
import { ErrorCode } from '../../main/ets/constants/ErrorCodes';
import {
  AppError,
  createErrorOperationState,
  createInitialOperationState,
  OperationStatus
} from '../../main/ets/model/ResultModels';

export default function operationStateTest() {
  describe('OperationState', () => {
    it('uses the documented operation status values', 0, () => {
      expect(OperationStatus.IDLE).assertEqual('IDLE');
      expect(OperationStatus.LOADING).assertEqual('LOADING');
      expect(OperationStatus.SUCCESS).assertEqual('SUCCESS');
      expect(OperationStatus.ERROR).assertEqual('ERROR');
      expect(OperationStatus.CANCELLED).assertEqual('CANCELLED');
    });

    it('creates independent idle states', 0, () => {
      const first = createInitialOperationState();
      const second = createInitialOperationState();

      first.status = OperationStatus.LOADING;

      expect(second.status).assertEqual(OperationStatus.IDLE);
      expect(second.error === undefined).assertTrue();
    });

    it('copies an error and correlates an error state', 0, () => {
      const error: AppError = {
        code: ErrorCode.STORAGE_WRITE_FAILED,
        message: 'Synthetic storage failure',
        retryable: true,
        correlationId: 'synthetic-correlation-002'
      };
      const state = createErrorOperationState(error);

      error.message = 'changed by caller';

      expect(state.status).assertEqual(OperationStatus.ERROR);
      expect(state.error?.message).assertEqual('Synthetic storage failure');
      expect(state.correlationId).assertEqual('synthetic-correlation-002');
    });
  });
}
