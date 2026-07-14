import { Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { abilityDelegatorRegistry, Driver, ON } from '@kit.TestKit';
import { describe, it } from '@ohos/hypium';
import { ErrorCode } from '../../../../main/ets/constants/ErrorCodes';
import {
  createFailureResult,
  createSuccessResult
} from '../../../../main/ets/model/ResultModels';
import { configureHomeRuntimeWithRepository } from '../../../../main/ets/service/platform/AppRuntime';
import { DeferredReportResult, FakeReportRepository } from '../../../../test/fakes/FakeReportRepository';
import { createReportFixture } from '../../../../test/fixtures/ReportFixtures';

const UI_SETTLE_MS: number = 350;
const MAIN_WANT: Want = {
  bundleName: 'com.example.errordiagnosis',
  abilityName: 'EntryAbility'
};

async function startAbility(): Promise<void> {
  await abilityDelegatorRegistry.getAbilityDelegator().startAbility(MAIN_WANT);
  await Driver.create().delayMs(800);
}

async function loadHome(repository: FakeReportRepository): Promise<void> {
  configureHomeRuntimeWithRepository(repository);
  const ability = await abilityDelegatorRegistry.getAbilityDelegator().getCurrentTopAbility();
  const mainWindow = await window.getLastWindow(ability.context);
  await mainWindow.loadContent('pages/home/HomePage');
  await Driver.create().delayMs(UI_SETTLE_MS);
}

async function assertHomeText(driver: Driver, text: string): Promise<void> {
  const scroll = await driver.findComponent(ON.id('home_scroll'));
  await scroll.scrollSearch(ON.text(text));
}

async function clickHome(driver: Driver, text: string): Promise<void> {
  const scroll = await driver.findComponent(ON.id('home_scroll'));
  const component = await scroll.scrollSearch(ON.text(text));
  await component.click();
  await driver.delayMs(UI_SETTLE_MS);
}

async function clickRecentReport(driver: Driver, reportId: string): Promise<void> {
  const scroll = await driver.findComponent(ON.id('home_scroll'));
  const component = await scroll.scrollSearch(ON.id(`home_recent_report_${reportId}`));
  await component.click();
  await driver.delayMs(UI_SETTLE_MS);
}

export default function homePageFlowTest() {
  describe('HomePageFlow', () => {
    it('keeps three core entries operable while recent history is still loading', 0, async () => {
      await startAbility();
      const repository = new FakeReportRepository();
      repository.deferredRecent = new DeferredReportResult();
      await loadHome(repository);
      const driver = Driver.create();

      await assertHomeText(driver, '截图诊断');
      await assertHomeText(driver, '文本诊断');
      await assertHomeText(driver, '打开验证工具');
      await assertHomeText(driver, '正在加载最近记录');
      repository.deferredRecent.resolve(createSuccessResult([]));
      await driver.delayMs(UI_SETTLE_MS);

      await clickHome(driver, '截图诊断');
      await driver.assertComponentExist(ON.text('诊断页'));
      await driver.pressBack();
      await driver.delayMs(UI_SETTLE_MS);
      await clickHome(driver, '文本诊断');
      await driver.assertComponentExist(ON.text('诊断页'));
      await driver.pressBack();
      await driver.delayMs(UI_SETTLE_MS);
      await clickHome(driver, '打开验证工具');
      await driver.assertComponentExist(ON.text('验证工具页'));
      await driver.pressBack();
      await driver.delayMs(UI_SETTLE_MS);
      await clickHome(driver, '查看全部记录');
      await driver.assertComponentExist(ON.text('记录与设置页'));
      await driver.pressBack();
      await driver.delayMs(UI_SETTLE_MS);
      await assertHomeText(driver, '开发报错诊断助手');
    });

    it('shows the real empty state without synthetic reports', 0, async () => {
      await startAbility();
      await loadHome(new FakeReportRepository());
      const driver = Driver.create();

      await assertHomeText(driver, '还没有诊断记录');
      await assertHomeText(driver, '开始第一次诊断');
      await assertHomeText(driver, '查看全部记录');
    });

    it('renders three recent records and opens one report by its card', 0, async () => {
      await startAbility();
      const repository = new FakeReportRepository();
      const first = createReportFixture('synthetic-ui-recent-1', 1, 3);
      first.summary = 'Synthetic UI recent summary one';
      const second = createReportFixture('synthetic-ui-recent-2', 1, 2);
      second.summary = 'Synthetic UI recent summary two';
      const third = createReportFixture('synthetic-ui-recent-3', 1, 1);
      third.summary = 'Synthetic UI recent summary three';
      repository.recentResult = createSuccessResult([first, second, third]);
      await loadHome(repository);
      const driver = Driver.create();

      await assertHomeText(driver, 'Synthetic UI recent summary one');
      await assertHomeText(driver, 'Synthetic UI recent summary two');
      await assertHomeText(driver, 'Synthetic UI recent summary three');
      await clickRecentReport(driver, 'synthetic-ui-recent-1');
      await driver.assertComponentExist(ON.text('诊断报告页'));
      await driver.pressBack();
      await driver.delayMs(UI_SETTLE_MS);
      await assertHomeText(driver, '开发报错诊断助手');
    });

    it('shows a safe local error keeps core entry clickable and recovers on retry', 0, async () => {
      await startAbility();
      const repository = new FakeReportRepository();
      repository.recentResult = createFailureResult({
        code: ErrorCode.STORAGE_READ_FAILED,
        message: 'PRIVATE_DATABASE_PATH_AND_SQL',
        retryable: true
      });
      await loadHome(repository);
      const driver = Driver.create();

      await assertHomeText(driver, '暂时无法读取最近记录，请稍后重试。');
      await assertHomeText(driver, '重新加载');
      await assertHomeText(driver, '文本诊断');
      repository.recentResult = createSuccessResult([
        createReportFixture('synthetic-ui-retry', 1, 2)
      ]);
      await clickHome(driver, '重新加载');
      await assertHomeText(driver, 'Synthetic report summary');
    });

    it('keeps content scrollable and primary actions visible at 1.5 font scale', 0, async () => {
      await startAbility();
      const ability = await abilityDelegatorRegistry.getAbilityDelegator().getCurrentTopAbility();
      const applicationContext = ability.context.getApplicationContext();
      applicationContext.setFontSizeScale(1.5);
      try {
        await loadHome(new FakeReportRepository());
        const driver = Driver.create();
        await assertHomeText(driver, '截图诊断');
        await assertHomeText(driver, '文本诊断');
        await assertHomeText(driver, '打开验证工具');
        await assertHomeText(driver, '查看全部记录');
        await assertHomeText(driver, '跟随系统');
      } finally {
        applicationContext.setFontSizeScale(1.0);
      }
    });
  });
}
