import { describe, expect, it } from '@ohos/hypium';
import httpStatusResource from '../../main/resources/rawfile/http_status_v1.json';
import {
  HTTP_STATUS_CODE_MAX,
  HTTP_STATUS_CODE_MIN
} from '../../main/ets/constants/AppLimits';
import { HttpStatusEntry } from '../../main/ets/model/ResultModels';
import {
  createHttpStatusNameFixtures,
  createRequiredHttpStatusCodesFixture,
  HttpStatusNameFixture,
  STATIC_RESOURCE_SCHEMA_VERSION,
  STATIC_RESOURCE_VERSION
} from '../fixtures/StaticResourceFixtures';

interface HttpStatusResource {
  schemaName: string;
  schemaVersion: number;
  resourceVersion: string;
  entries: Array<HttpStatusEntry>;
}

function findStatus(entries: Array<HttpStatusEntry>, code: number): HttpStatusEntry | undefined {
  for (let index: number = 0; index < entries.length; index++) {
    if (entries[index].code === code) {
      return entries[index];
    }
  }
  return undefined;
}

export default function httpStatusResourceTest() {
  describe('HttpStatusResource', () => {
    const resource: HttpStatusResource = httpStatusResource;

    it('uses the documented schema and resource versions', 0, () => {
      expect(resource.schemaName).assertEqual('http-status');
      expect(resource.schemaVersion).assertEqual(STATIC_RESOURCE_SCHEMA_VERSION);
      expect(resource.resourceVersion).assertEqual(STATIC_RESOURCE_VERSION);
    });

    it('contains every required P0 HTTP status code', 0, () => {
      const requiredCodes = createRequiredHttpStatusCodesFixture();

      expect(resource.entries.length).assertEqual(requiredCodes.length);
      for (let index: number = 0; index < requiredCodes.length; index++) {
        expect(findStatus(resource.entries, requiredCodes[index]) !== undefined).assertTrue();
      }
    });

    it('keeps HTTP status codes unique and within input boundaries', 0, () => {
      let duplicateCount: number = 0;
      for (let left: number = 0; left < resource.entries.length; left++) {
        const code = resource.entries[left].code;
        expect(code >= HTTP_STATUS_CODE_MIN && code <= HTTP_STATUS_CODE_MAX).assertTrue();
        for (let right: number = left + 1; right < resource.entries.length; right++) {
          if (code === resource.entries[right].code) {
            duplicateCount++;
          }
        }
      }

      expect(duplicateCount).assertEqual(0);
    });

    it('matches the official registered HTTP status names', 0, () => {
      const fixtures: Array<HttpStatusNameFixture> = createHttpStatusNameFixtures();

      for (let index: number = 0; index < fixtures.length; index++) {
        expect(findStatus(resource.entries, fixtures[index].code)?.name).assertEqual(fixtures[index].name);
      }
    });

    it('provides complete explanations and actionable steps', 0, () => {
      for (let index: number = 0; index < resource.entries.length; index++) {
        const entry = resource.entries[index];
        expect(entry.name.trim().length > 0).assertTrue();
        expect(entry.category.trim().length > 0).assertTrue();
        expect(entry.description.trim().length > 0).assertTrue();
        expect(entry.causes.length >= 1).assertTrue();
        expect(entry.steps.length >= 2).assertTrue();
      }
    });

    it('uses categories that agree with the numeric status class', 0, () => {
      for (let index: number = 0; index < resource.entries.length; index++) {
        const entry = resource.entries[index];
        if (entry.code >= 200 && entry.code <= 299) {
          expect(entry.category).assertEqual('Success');
        } else if (entry.code >= 400 && entry.code <= 499) {
          expect(entry.category).assertEqual('Client Error');
        } else if (entry.code >= 500 && entry.code <= 599) {
          expect(entry.category).assertEqual('Server Error');
        }
      }
    });

    it('does not share mutable collections between status entries', 0, () => {
      expect(resource.entries[0].causes === resource.entries[1].causes).assertFalse();
      expect(resource.entries[0].steps === resource.entries[1].steps).assertFalse();
    });
  });
}
