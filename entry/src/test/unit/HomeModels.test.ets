import { describe, expect, it } from '@ohos/hypium';
import { SourceType } from '../../main/ets/model/DiagnosisModels';
import {
  createHomeReportItem,
  formatSavedAt
} from '../../main/ets/viewmodel/home/HomeModels';
import { createReportFixture } from '../fixtures/ReportFixtures';

export default function homeModelsTest() {
  describe('HomeModels', () => {
    it('creates a safe display item without raw text or database fields', 0, () => {
      const report = createReportFixture('synthetic-home-card', 1, 1700000000000);
      report.rawText = 'PRIVATE_RAW_TEXT';
      report.evidence = ['PRIVATE_EVIDENCE'];
      report.sourceType = SourceType.IMAGE;

      const item = createHomeReportItem(report);
      const serialized = JSON.stringify(item);

      expect(item.reportId).assertEqual('synthetic-home-card');
      expect(item.sourceLabel).assertEqual('截图来源');
      expect(serialized.includes('PRIVATE_RAW_TEXT')).assertFalse();
      expect(serialized.includes('PRIVATE_EVIDENCE')).assertFalse();
      expect(serialized.includes('rawText')).assertFalse();
    });

    it('truncates long user-facing fields and keeps an accurate accessibility summary', 0, () => {
      const report = createReportFixture('synthetic-long-card', 1, 1700000000000);
      report.errorType = 'T'.repeat(80);
      report.summary = 'S'.repeat(180);

      const item = createHomeReportItem(report);

      expect(item.errorType.length).assertEqual(48);
      expect(item.summary.length).assertEqual(120);
      expect(item.accessibilityText.includes(item.summary)).assertTrue();
      expect(item.accessibilityText.includes(item.savedAtText)).assertTrue();
    });

    it('formats valid saved time and safely labels missing time', 0, () => {
      expect(formatSavedAt(1700000000000).includes('2023-')).assertTrue();
      expect(formatSavedAt(undefined)).assertEqual('保存时间未知');
    });
  });
}
