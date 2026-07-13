import { window } from '@kit.ArkUI';
import { Want } from '@kit.AbilityKit';
import { abilityDelegatorRegistry, Driver, ON } from '@kit.TestKit';
import { describe, it } from '@ohos/hypium';

const UI_SETTLE_MS: number = 300;

async function startMainAbility(): Promise<void> {
  const want: Want = {
    bundleName: 'com.example.errordiagnosis',
    abilityName: 'EntryAbility'
  };
  await abilityDelegatorRegistry.getAbilityDelegator().startAbility(want);
  await Driver.create().delayMs(1000);
}

async function currentWindow(): Promise<window.Window> {
  const ability = await abilityDelegatorRegistry.getAbilityDelegator().getCurrentTopAbility();
  return window.getLastWindow(ability.context);
}

async function loadPage(path: string): Promise<void> {
  const mainWindow = await currentWindow();
  await mainWindow.loadContent(path);
  await Driver.create().delayMs(UI_SETTLE_MS);
}

async function clickText(driver: Driver, text: string): Promise<void> {
  const component = await driver.findComponent(ON.text(text));
  await component.click();
  await driver.delayMs(UI_SETTLE_MS);
}

async function clickPageText(driver: Driver, text: string): Promise<void> {
  const scroll = await driver.findComponent(ON.id('common_components_scroll'));
  const component = await scroll.scrollSearch(ON.text(text));
  await component.click();
  await driver.delayMs(UI_SETTLE_MS);
}

async function assertPageText(driver: Driver, text: string): Promise<void> {
  const scroll = await driver.findComponent(ON.id('common_components_scroll'));
  await scroll.scrollSearch(ON.text(text));
}

export default function commonComponentsFlowTest() {
  describe('CommonComponentsFlow', () => {
    it('renders async empty and inline states and dispatches their independent events', 0, async () => {
      await startMainAbility();
      await loadPage('pages/testing/CommonComponentsTestHost');
      const driver = Driver.create();
      try {
        await driver.assertComponentExist(ON.text('公共组件测试宿主'));
        await driver.assertComponentExist(ON.text('正在加载'));
        await driver.assertComponentExist(ON.text('正在加载组件数据'));
        await driver.assertComponentExist(ON.text('最后一份有效内容'));
        await driver.assertComponentExist(ON.text('暂无历史记录'));
        await driver.assertComponentExist(ON.text('警告'));

        await clickPageText(driver, '显示错误状态');
        await assertPageText(driver, '加载失败');
        await assertPageText(driver, '安全错误信息，可再次尝试');
        await clickPageText(driver, '重新加载');
        await assertPageText(driver, '事件：重试');

        await clickPageText(driver, '开始诊断');
        await assertPageText(driver, '事件：空状态操作');
        await clickPageText(driver, '查看处理方法');
        await assertPageText(driver, '事件：错误操作');
        await clickPageText(driver, '关闭提示');
        await assertPageText(driver, '事件：关闭错误');
      } finally {
        await loadPage('pages/home/HomePage');
      }
    });

    it('confirms once and treats explicit cancel and system back as cancel', 0, async () => {
      await startMainAbility();
      await loadPage('pages/testing/CommonComponentsTestHost');
      const driver = Driver.create();
      try {
        await clickPageText(driver, '打开危险确认');
        await driver.assertComponentExist(ON.text('删除测试记录'));
        await driver.assertComponentExist(ON.text('危险操作，确认后无法自动恢复'));
        await clickText(driver, '确认危险操作');
        await driver.assertComponentExist(ON.text('事件：确认'));

        await clickPageText(driver, '打开危险确认');
        await clickText(driver, '取消');
        await driver.assertComponentExist(ON.text('事件：取消'));

        await clickPageText(driver, '打开危险确认');
        await driver.pressBack();
        await driver.delayMs(UI_SETTLE_MS);
        await driver.assertComponentExist(ON.text('事件：取消'));
      } finally {
        await loadPage('pages/home/HomePage');
      }
    });

    it('stays operable at 1.5 font scale and follows LIGHT DARK and SYSTEM', 0, async () => {
      await startMainAbility();
      const ability = await abilityDelegatorRegistry.getAbilityDelegator().getCurrentTopAbility();
      const applicationContext = ability.context.getApplicationContext();
      applicationContext.setFontSizeScale(1.5);
      await loadPage('pages/testing/CommonComponentsTestHost');
      const driver = Driver.create();
      try {
        await assertPageText(driver, '当前没有历史记录，完成诊断后会显示在这里。');
        await clickPageText(driver, '开始诊断');
        await assertPageText(driver, '事件：空状态操作');

        await clickPageText(driver, '组件深色主题');
        await assertPageText(driver, '组件主题：DARK');
        await clickPageText(driver, '组件浅色主题');
        await assertPageText(driver, '组件主题：LIGHT');
        await clickPageText(driver, '组件跟随系统');
        await assertPageText(driver, '组件主题：SYSTEM');
      } finally {
        applicationContext.setFontSizeScale(1.0);
        await loadPage('pages/home/HomePage');
      }
    });
  });
}
