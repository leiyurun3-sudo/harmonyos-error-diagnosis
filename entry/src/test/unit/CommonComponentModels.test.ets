import { describe, expect, it } from '@ohos/hypium';
import { OperationStatus } from '../../main/ets/model/ResultModels';
import {
  ConfirmEventGate,
  createAsyncStatePresentation,
  createConfirmPresentation,
  createEmptyStatePresentation,
  createInlineNoticePresentation,
  NoticeSeverity
} from '../../main/ets/components/common/CommonComponentModels';

export default function commonComponentModelsTest() {
  describe('CommonComponentModels', () => {
    it('maps every OperationStatus to an explicit presentation', 0, () => {
      expect(createAsyncStatePresentation(OperationStatus.IDLE, '', false, undefined, false).showLoading).assertFalse();
      expect(createAsyncStatePresentation(OperationStatus.LOADING, '', false, undefined, false).showLoading).assertTrue();
      expect(createAsyncStatePresentation(OperationStatus.SUCCESS, '', false, undefined, false).status)
        .assertEqual(OperationStatus.SUCCESS);
      expect(createAsyncStatePresentation(OperationStatus.ERROR, '', false, undefined, false).showError).assertTrue();
      expect(createAsyncStatePresentation(OperationStatus.CANCELLED, '', false, undefined, false).status)
        .assertEqual(OperationStatus.CANCELLED);
    });

    it('shows only the safe AppError message in ERROR state', 0, () => {
      const presentation = createAsyncStatePresentation(OperationStatus.ERROR, '备用提示', false, {
        code: 'STORAGE_WRITE_FAILED',
        message: '保存失败，请重试。',
        retryable: true,
        causeType: 'C:\\Users\\private\\token=secret',
        correlationId: 'private-correlation-id'
      }, true);
      const serialized = JSON.stringify(presentation);

      expect(presentation.message).assertEqual('保存失败，请重试。');
      expect(serialized.includes('token=secret')).assertFalse();
      expect(serialized.includes('private-correlation-id')).assertFalse();
      expect(serialized.includes('STORAGE_WRITE_FAILED')).assertFalse();
    });

    it('shows retry only for ERROR with an available callback', 0, () => {
      expect(createAsyncStatePresentation(OperationStatus.ERROR, '', false, undefined, true).showRetry).assertTrue();
      expect(createAsyncStatePresentation(OperationStatus.ERROR, '', false, undefined, false).showRetry).assertFalse();
      expect(createAsyncStatePresentation(OperationStatus.LOADING, '', false, undefined, true).showRetry).assertFalse();
    });

    it('retains valid content when showContent is true', 0, () => {
      expect(createAsyncStatePresentation(OperationStatus.LOADING, '', true, undefined, false).showContent).assertTrue();
      expect(createAsyncStatePresentation(OperationStatus.ERROR, '', true, undefined, true).showContent).assertTrue();
      expect(createAsyncStatePresentation(OperationStatus.SUCCESS, '', false, undefined, false).showContent).assertFalse();
    });

    it('shows an empty-state action only when label and callback both exist', 0, () => {
      expect(createEmptyStatePresentation('暂无历史', '还没有记录', '开始诊断', true).showAction).assertTrue();
      expect(createEmptyStatePresentation('暂无历史', '还没有记录', '开始诊断', false).showAction).assertFalse();
      expect(createEmptyStatePresentation('暂无历史', '还没有记录', '   ', true).showAction).assertFalse();
    });

    it('uses safe fallback text for invalid empty-state input', 0, () => {
      const presentation = createEmptyStatePresentation('  ', '', undefined, false);

      expect(presentation.title).assertEqual('暂无内容');
      expect(presentation.description).assertEqual('当前没有可展示的内容。');
    });

    it('preserves all supported notice severities', 0, () => {
      expect(createInlineNoticePresentation('提示', NoticeSeverity.INFO, undefined, false, false).severity)
        .assertEqual(NoticeSeverity.INFO);
      expect(createInlineNoticePresentation('警告', NoticeSeverity.WARNING, undefined, false, false).severity)
        .assertEqual(NoticeSeverity.WARNING);
      expect(createInlineNoticePresentation('错误', NoticeSeverity.ERROR, undefined, false, false).severity)
        .assertEqual(NoticeSeverity.ERROR);
    });

    it('keeps notice action and dismiss availability independent', 0, () => {
      const actionOnly = createInlineNoticePresentation('提示', NoticeSeverity.INFO, '处理', true, false);
      const dismissOnly = createInlineNoticePresentation('提示', NoticeSeverity.INFO, undefined, false, true);

      expect(actionOnly.showAction).assertTrue();
      expect(actionOnly.showDismiss).assertFalse();
      expect(dismissOnly.showAction).assertFalse();
      expect(dismissOnly.showDismiss).assertTrue();
    });

    it('normalizes empty notice text without adding technical details', 0, () => {
      const presentation = createInlineNoticePresentation('   ', NoticeSeverity.ERROR, undefined, false, false);

      expect(presentation.message).assertEqual('操作遇到问题，请稍后重试。');
      expect(JSON.stringify(presentation).includes('causeType')).assertFalse();
    });

    it('uses explicit dangerous confirmation wording', 0, () => {
      const dangerous = createConfirmPresentation('删除记录', '删除后无法恢复', true);
      const regular = createConfirmPresentation('清空输入', '是否继续', false);

      expect(dangerous.dangerLabel).assertEqual('危险操作，确认后无法自动恢复');
      expect(dangerous.confirmLabel).assertEqual('确认危险操作');
      expect(regular.confirmLabel).assertEqual('确认');
      expect(regular.cancelLabel).assertEqual('取消');
    });

    it('cancel never invokes confirm', 0, () => {
      const gate = new ConfirmEventGate();
      let confirmCount: number = 0;
      let cancelCount: number = 0;

      expect(gate.cancel(() => cancelCount++)).assertTrue();
      expect(gate.confirm(() => confirmCount++)).assertFalse();
      expect(confirmCount).assertEqual(0);
      expect(cancelCount).assertEqual(1);
    });

    it('allows confirmation only once per opening', 0, () => {
      const gate = new ConfirmEventGate();
      let count: number = 0;

      expect(gate.confirm(() => count++)).assertTrue();
      expect(gate.confirm(() => count++)).assertFalse();
      expect(count).assertEqual(1);
    });

    it('reset isolates callback state between dialog openings', 0, () => {
      const gate = new ConfirmEventGate();
      let count: number = 0;
      gate.confirm(() => count++);

      gate.reset();

      expect(gate.confirm(() => count++)).assertTrue();
      expect(count).assertEqual(2);
    });
  });
}
