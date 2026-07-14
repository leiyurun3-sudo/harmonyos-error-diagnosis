import { DiagnosisReport, SourceType } from '../../model/DiagnosisModels';

const SUMMARY_LIMIT: number = 120;
const TYPE_LIMIT: number = 48;

export interface HomeReportItem {
  reportId: string;
  errorType: string;
  summary: string;
  savedAtText: string;
  sourceLabel: string;
  accessibilityText: string;
}

function normalizedText(value: string, fallback: string, limit: number): string {
  const normalized = value.trim().length === 0 ? fallback : value.trim();
  if (normalized.length <= limit) {
    return normalized;
  }
  return `${normalized.slice(0, limit - 1)}…`;
}

function twoDigits(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}

export function formatSavedAt(savedAt: number | undefined): string {
  if (savedAt === undefined || !Number.isFinite(savedAt) || savedAt < 0) {
    return '保存时间未知';
  }
  const date = new Date(savedAt);
  return `${date.getFullYear()}-${twoDigits(date.getMonth() + 1)}-${twoDigits(date.getDate())} ` +
    `${twoDigits(date.getHours())}:${twoDigits(date.getMinutes())}`;
}

export function createHomeReportItem(report: DiagnosisReport): HomeReportItem {
  const errorType = normalizedText(report.errorType, '未分类错误', TYPE_LIMIT);
  const summary = normalizedText(report.summary, '暂无报告摘要', SUMMARY_LIMIT);
  const savedAtText = formatSavedAt(report.savedAt);
  const sourceLabel = report.sourceType === SourceType.IMAGE ? '截图来源' : '文本来源';
  return {
    reportId: report.id,
    errorType: errorType,
    summary: summary,
    savedAtText: savedAtText,
    sourceLabel: sourceLabel,
    accessibilityText: `${errorType}，${summary}，${savedAtText}，${sourceLabel}`
  };
}

export function copyHomeReportItems(items: Array<HomeReportItem>): Array<HomeReportItem> {
  return items.map((item: HomeReportItem): HomeReportItem => ({
    reportId: item.reportId,
    errorType: item.errorType,
    summary: item.summary,
    savedAtText: item.savedAtText,
    sourceLabel: item.sourceLabel,
    accessibilityText: item.accessibilityText
  }));
}
