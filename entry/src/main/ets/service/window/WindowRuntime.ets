import { window } from '@kit.ArkUI';

let mainWindowStage: window.WindowStage | undefined;
let flashWindow: window.Window | undefined;

export function configureWindowRuntime(stage: window.WindowStage): void {
  mainWindowStage = stage;
}

export async function openFlashControlWindow(): Promise<string> {
  if (mainWindowStage === undefined) {
    return '主窗口尚未准备完成';
  }
  try {
    if (flashWindow !== undefined) {
      await flashWindow.showWindow();
      return '闪控子窗已恢复显示';
    }
    flashWindow = await mainWindowStage.createSubWindowWithOptions('DevAssistFlashControl', {
      title: '诊断闪控窗',
      decorEnabled: true,
      isModal: false,
      windowRect: { left: 80, top: 220, width: 720, height: 920 },
      maximizeSupported: false,
      zLevel: 2
    });
    await flashWindow.loadContent('pages/window/FlashControlWindow');
    await flashWindow.showWindow();
    return '已创建可拖动的应用闪控子窗';
  } catch (_) {
    flashWindow = undefined;
    return '当前设备不支持应用子窗，已保留页面内闪控卡片';
  }
}

export async function closeFlashControlWindow(): Promise<string> {
  if (flashWindow === undefined) {
    return '闪控子窗当前未打开';
  }
  try {
    await flashWindow.destroyWindow();
  } catch (_) {
    flashWindow = undefined;
    return '闪控子窗已关闭';
  }
  flashWindow = undefined;
  return '闪控子窗已关闭';
}

export function disposeWindowRuntime(): void {
  closeFlashControlWindow();
  mainWindowStage = undefined;
}
