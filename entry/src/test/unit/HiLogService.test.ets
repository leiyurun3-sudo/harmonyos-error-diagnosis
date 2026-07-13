import { describe, expect, it } from '@ohos/hypium';
import { ErrorCode } from '../../main/ets/constants/ErrorCodes';
import {
  createLogRecord,
  HiLogService,
  LogContext,
  LogLevel,
  LogMetadataKey,
  LogMetadataItem
} from '../../main/ets/service/platform/HiLogService';
import { CapturingLogSink } from '../fakes/CapturingLogSink';

export default function hiLogServiceTest() {
  describe('HiLogService', () => {
    it('uses the documented log level values', 0, () => {
      expect(LogLevel.DEBUG).assertEqual('DEBUG');
      expect(LogLevel.INFO).assertEqual('INFO');
      expect(LogLevel.WARN).assertEqual('WARN');
      expect(LogLevel.ERROR).assertEqual('ERROR');
    });

    it('writes a valid structured record through the injected sink', 0, () => {
      const sink = new CapturingLogSink();
      const service = new HiLogService(sink);
      const context: LogContext = {
        domain: 'diagnosis',
        event: 'completed',
        correlationId: 'synthetic-correlation-001',
        result: 'success',
        durationMs: 0,
        errorCode: ErrorCode.UNKNOWN_ERROR,
        metadata: [
          { key: LogMetadataKey.RECORD_COUNT, value: 0 }
        ]
      };

      const accepted = service.log(LogLevel.INFO, context);

      expect(accepted).assertTrue();
      expect(sink.records.length).assertEqual(1);
      expect(sink.records[0].durationMs).assertEqual(0);
      expect(sink.records[0].metadata.length).assertEqual(1);
    });

    it('drops non-whitelisted and sensitive metadata', 0, () => {
      const metadata: Array<LogMetadataItem> = [
        { key: 'rawText', value: 'synthetic diagnostic text' },
        { key: 'token', value: 'SYNTHETIC_TOKEN_123' },
        { key: LogMetadataKey.RULE_VERSION, value: 'password=SYNTHETIC_PASSWORD_456' },
        { key: LogMetadataKey.PAGE_NAME, value: 'synthetic@example.invalid' },
        { key: LogMetadataKey.RULE_VERSION, value: '13800138000' },
        { key: LogMetadataKey.TEXT_LENGTH_RANGE, value: 'https://internal.invalid' },
        { key: LogMetadataKey.PAGE_NAME, value: 'DiagnosisPage' }
      ];
      const record = createLogRecord(LogLevel.WARN, {
        domain: 'diagnosis',
        event: 'degraded',
        metadata: metadata
      }, 1700000000000);
      const serialized = JSON.stringify(record);

      expect(record !== undefined).assertTrue();
      expect(record?.metadata.length).assertEqual(1);
      expect(serialized.includes('SYNTHETIC_TOKEN_123')).assertFalse();
      expect(serialized.includes('SYNTHETIC_PASSWORD_456')).assertFalse();
      expect(serialized.includes('synthetic@example.invalid')).assertFalse();
      expect(serialized.includes('13800138000')).assertFalse();
      expect(serialized.includes('internal.invalid')).assertFalse();
      expect(serialized.includes('rawText')).assertFalse();
    });

    it('rejects empty identifiers and negative durations', 0, () => {
      const sink = new CapturingLogSink();
      const service = new HiLogService(sink);

      const emptyDomainAccepted = service.log(LogLevel.INFO, {
        domain: '   ',
        event: 'completed'
      });
      const negativeDurationAccepted = service.log(LogLevel.INFO, {
        domain: 'diagnosis',
        event: 'completed',
        durationMs: -1
      });

      expect(emptyDomainAccepted).assertFalse();
      expect(negativeDurationAccepted).assertFalse();
      expect(sink.records.length).assertEqual(0);
    });

    it('isolates recorded metadata from caller mutation', 0, () => {
      const sink = new CapturingLogSink();
      const service = new HiLogService(sink);
      const metadata: Array<LogMetadataItem> = [
        { key: LogMetadataKey.PAGE_NAME, value: 'DiagnosisPage' }
      ];

      service.log(LogLevel.DEBUG, {
        domain: 'navigation',
        event: 'page_entered',
        metadata: metadata
      });
      metadata[0].value = 'ChangedPage';

      expect(sink.records[0].metadata[0].value).assertEqual('DiagnosisPage');
    });
  });
}
