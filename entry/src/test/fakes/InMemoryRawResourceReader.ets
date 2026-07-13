import { ErrorCode } from '../../main/ets/constants/ErrorCodes';
import {
  AppResult,
  createFailureResult,
  createSuccessResult
} from '../../main/ets/model/ResultModels';
import {
  RawResourceReader
} from '../../main/ets/storage/static/RawResourceStore';

export interface RawTextFixture {
  resourceName: string;
  content: string;
}

interface ReadCounter {
  resourceName: string;
  count: number;
}

export class InMemoryRawResourceReader implements RawResourceReader {
  private fixtures: Array<RawTextFixture>;
  private counters: Array<ReadCounter> = [];

  constructor(fixtures: Array<RawTextFixture>) {
    this.fixtures = fixtures;
  }

  readText(resourceName: string): Promise<AppResult<string>> {
    this.increment(resourceName);
    for (let index: number = 0; index < this.fixtures.length; index++) {
      if (this.fixtures[index].resourceName === resourceName) {
        return Promise.resolve(createSuccessResult<string>(this.fixtures[index].content));
      }
    }
    return Promise.resolve(createFailureResult<string>({
      code: ErrorCode.RULE_RESOURCE_FAILED,
      message: 'Synthetic resource is unavailable',
      retryable: true,
      causeType: 'RAWFILE_READ'
    }));
  }

  getReadCount(resourceName: string): number {
    for (let index: number = 0; index < this.counters.length; index++) {
      if (this.counters[index].resourceName === resourceName) {
        return this.counters[index].count;
      }
    }
    return 0;
  }

  private increment(resourceName: string): void {
    for (let index: number = 0; index < this.counters.length; index++) {
      if (this.counters[index].resourceName === resourceName) {
        this.counters[index].count++;
        return;
      }
    }
    this.counters.push({ resourceName: resourceName, count: 1 });
  }
}
