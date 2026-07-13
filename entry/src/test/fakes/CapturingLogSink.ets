import {
  LogRecord,
  LogSink
} from '../../main/ets/service/platform/HiLogService';

export class CapturingLogSink implements LogSink {
  records: Array<LogRecord> = [];

  write(record: LogRecord): void {
    this.records.push(record);
  }
}
