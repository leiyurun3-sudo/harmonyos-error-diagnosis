import { describe, expect, it } from '@ohos/hypium';
import { ErrorCode } from '../../main/ets/constants/ErrorCodes';
import {
  AppError,
  AppResult,
  createFailureResult,
  createSuccessResult,
  isValidAppResult
} from '../../main/ets/model/ResultModels';
import { createHttpStatusEntryFixture } from '../fixtures/ModelFixtures';

export default function resultModelsTest() {
  describe('ResultModels', () => {
    it('represents a static HTTP status entry with required arrays', 0, () => {
      const entry = createHttpStatusEntryFixture();

      expect(entry.code).assertEqual(404);
      expect(entry.name).assertEqual('Not Found');
      expect(entry.causes.length).assertEqual(0);
      expect(entry.steps.length).assertEqual(0);
    });

    it('creates a valid success result with data', 0, () => {
      const result = createSuccessResult<number>(200);

      expect(result.success).assertTrue();
      expect(result.data).assertEqual(200);
      expect(result.error === undefined).assertTrue();
      expect(isValidAppResult<number>(result)).assertTrue();
    });

    it('preserves a non-retryable failure and isolates the error', 0, () => {
      const error: AppError = {
        code: ErrorCode.VAL_INPUT_EMPTY,
        message: 'Synthetic empty input',
        retryable: false
      };
      const result = createFailureResult<number>(error);

      error.message = 'changed by caller';

      expect(result.success).assertFalse();
      expect(result.error?.message).assertEqual('Synthetic empty input');
      expect(result.error?.retryable).assertFalse();
      expect(isValidAppResult<number>(result)).assertTrue();
    });

    it('rejects contradictory success and failure shapes', 0, () => {
      const error: AppError = {
        code: ErrorCode.UNKNOWN_ERROR,
        message: 'Synthetic unknown failure',
        retryable: true
      };
      const successWithError: AppResult<number> = {
        success: true,
        data: 1,
        error: error
      };
      const failureWithData: AppResult<number> = {
        success: false,
        data: 1,
        error: error
      };
      const failureWithoutError: AppResult<number> = {
        success: false
      };

      expect(isValidAppResult<number>(successWithError)).assertFalse();
      expect(isValidAppResult<number>(failureWithData)).assertFalse();
      expect(isValidAppResult<number>(failureWithoutError)).assertFalse();
    });
  });
}
