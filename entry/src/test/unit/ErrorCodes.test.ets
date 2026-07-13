import { describe, expect, it } from '@ohos/hypium';
import {
  ErrorCode,
  getP0ErrorCodes
} from '../../main/ets/constants/ErrorCodes';

export default function errorCodesTest() {
  describe('ErrorCodes', () => {
    it('contains every documented P0 code exactly once', 0, () => {
      const codes = getP0ErrorCodes();
      let duplicateCount: number = 0;

      for (let left: number = 0; left < codes.length; left++) {
        for (let right: number = left + 1; right < codes.length; right++) {
          if (codes[left] === codes[right]) {
            duplicateCount++;
          }
        }
      }

      expect(codes.length).assertEqual(22);
      expect(duplicateCount).assertEqual(0);
      expect(codes[0]).assertEqual(ErrorCode.VAL_INPUT_EMPTY);
      expect(codes[codes.length - 1]).assertEqual(ErrorCode.UNKNOWN_ERROR);
    });

    it('does not expose deferred network or AI errors as P0 codes', 0, () => {
      const serialized = JSON.stringify(getP0ErrorCodes());

      expect(serialized.includes('NETWORK_UNAVAILABLE')).assertFalse();
      expect(serialized.includes('AI_ANALYSIS_FAILED')).assertFalse();
    });

    it('returns independent code collections', 0, () => {
      const first = getP0ErrorCodes();
      const second = getP0ErrorCodes();

      first.pop();

      expect(first.length).assertEqual(21);
      expect(second.length).assertEqual(22);
    });
  });
}
