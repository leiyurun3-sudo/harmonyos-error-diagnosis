import { Want } from '@kit.AbilityKit';
import { abilityDelegatorRegistry, Driver, ON } from '@kit.TestKit';
import { describe, it } from '@ohos/hypium';

export default function homePageSmokeTest() {
  describe('HomePageSmoke', () => {
    it('shows the application name and three formal product entries', 0, async () => {
      const want: Want = {
        bundleName: 'com.example.errordiagnosis',
        abilityName: 'EntryAbility'
      };
      await abilityDelegatorRegistry.getAbilityDelegator().startAbility(want);

      const driver = Driver.create();
      await driver.delayMs(1000);
      await driver.assertComponentExist(ON.text('开发报错诊断助手'));
      const scroll = await driver.findComponent(ON.id('home_scroll'));
      await scroll.scrollSearch(ON.text('截图诊断'));
      await scroll.scrollSearch(ON.text('文本诊断'));
      await scroll.scrollSearch(ON.text('打开验证工具'));
    });
  });
}
