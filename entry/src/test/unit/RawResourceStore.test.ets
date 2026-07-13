import { describe, expect, it } from '@ohos/hypium';
import { ErrorCode } from '../../main/ets/constants/ErrorCodes';
import {
  HiLogService,
  LogMetadataKey
} from '../../main/ets/service/platform/HiLogService';
import { RawResourceStore } from '../../main/ets/storage/static/RawResourceStore';
import { CapturingLogSink } from '../fakes/CapturingLogSink';
import {
  SyntheticRawFileContentSource,
  SyntheticRawTextDecoder
} from '../fakes/RawResourceStoreFakes';

export default function rawResourceStoreTest() {
  describe('RawResourceStore', () => {
    it('reads and decodes one rawfile without exposing platform bytes', 0, async (): Promise<void> => {
      const sink = new CapturingLogSink();
      const store = new RawResourceStore(
        new SyntheticRawFileContentSource('synthetic.json'),
        new SyntheticRawTextDecoder('{"synthetic":true}'),
        new HiLogService(sink)
      );

      const result = await store.readText('synthetic.json');

      expect(result.success).assertTrue();
      expect(result.data).assertEqual('{"synthetic":true}');
      expect(sink.records.length).assertEqual(0);
    });

    it('maps a missing rawfile to the existing resource error', 0, async (): Promise<void> => {
      const sink = new CapturingLogSink();
      const store = new RawResourceStore(
        new SyntheticRawFileContentSource('available.json'),
        new SyntheticRawTextDecoder('synthetic content'),
        new HiLogService(sink)
      );

      const result = await store.readText('missing.json');

      expect(result.success).assertFalse();
      expect(result.error?.code).assertEqual(ErrorCode.RULE_RESOURCE_FAILED);
      expect(result.error?.causeType).assertEqual('RAWFILE_READ');
      expect(sink.records.length).assertEqual(1);
      expect(sink.records[0].metadata[0].key).assertEqual(LogMetadataKey.RESOURCE_NAME);
      expect(JSON.stringify(sink.records[0]).includes('Synthetic rawfile read failure')).assertFalse();
    });

    it('maps UTF-8 decoding failure without returning partial text', 0, async (): Promise<void> => {
      const sink = new CapturingLogSink();
      const store = new RawResourceStore(
        new SyntheticRawFileContentSource('synthetic.json'),
        new SyntheticRawTextDecoder('partial content', true),
        new HiLogService(sink)
      );

      const result = await store.readText('synthetic.json');

      expect(result.success).assertFalse();
      expect(result.data === undefined).assertTrue();
      expect(result.error?.causeType).assertEqual('UTF8_DECODE');
      expect(JSON.stringify(sink.records[0]).includes('partial content')).assertFalse();
    });
  });
}
