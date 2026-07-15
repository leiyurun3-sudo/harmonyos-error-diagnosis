import { Want } from '@kit.AbilityKit';
import { abilityDelegatorRegistry, Driver, ON } from '@kit.TestKit';
import { describe, it } from '@ohos/hypium';

const UI_SETTLE_MS: number = 300;

async function clickText(driver: Driver, text: string): Promise<void> {
  const component = await driver.findComponent(ON.text(text));
  await component.click();
  await driver.delayMs(UI_SETTLE_MS);
}

async function clickHome(driver: Driver, text: string): Promise<void> {
  const scroll = await driver.findComponent(ON.id('home_scroll'));
  const component = await scroll.scrollSearch(ON.text(text));
  await component.click();
  await driver.delayMs(UI_SETTLE_MS);
}

async function assertHome(driver: Driver): Promise<void> {
  const scroll = await driver.findComponent(ON.id('home_scroll'));
  await scroll.scrollSearch(ON.text('开发报错诊断助手'));
}

export default function navigationFlowTest() {
  describe('NavigationFlow', () => {
    it('loads all six pages and preserves explicit and system return paths', 0, async () => {
      const want: Want = {
        bundleName: 'com.example.errordiagnosis',
        abilityName: 'EntryAbility'
      };
      await abilityDelegatorRegistry.getAbilityDelegator().startAbility(want);

      const driver = Driver.create();
      await driver.delayMs(1000);
      await assertHome(driver);

      await clickHome(driver, '文本诊断');
      await driver.assertComponentExist(ON.text('诊断页'));
      await clickText(driver, '返回首页');
      await assertHome(driver);

      await clickHome(driver, '打开验证工具');
      await driver.assertComponentExist(ON.text('验证工具页'));
      await driver.pressBack();
      await driver.delayMs(UI_SETTLE_MS);
      await assertHome(driver);

      await clickHome(driver, '查看全部记录');
      await driver.assertComponentExist(ON.text('记录与设置页'));
      await clickText(driver, '查看隐私说明');
      await driver.assertComponentExist(ON.text('隐私说明页'));
      await driver.pressBack();
      await driver.delayMs(UI_SETTLE_MS);
      await driver.assertComponentExist(ON.text('记录与设置页'));

      await driver.pressBack();
      await driver.delayMs(UI_SETTLE_MS);
      await assertHome(driver);
    });
  });
}
