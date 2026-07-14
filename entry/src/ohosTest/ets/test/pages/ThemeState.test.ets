import { abilityDelegatorRegistry, Driver, ON } from '@kit.TestKit';
import { describe, expect, it } from '@ohos/hypium';
import { ErrorCode } from '../../../../main/ets/constants/ErrorCodes';
import { SETTINGS_PREFERENCES_NAME } from '../../../../main/ets/constants/StorageKeys';
import {
  AppResult,
  createFailureResult,
  createSuccessResult,
  OperationStatus
} from '../../../../main/ets/model/ResultModels';
import {
  createDefaultUserSettings,
  ThemeMode,
  UserSettings
} from '../../../../main/ets/model/SettingsModels';
import {
  LocalSettingsRepository,
  SettingsRepository
} from '../../../../main/ets/repository/settings/SettingsRepository';
import {
  appStateStore,
  configureAppRuntime,
  configureAppRuntimeWithAdapters,
  switchApplicationTheme
} from '../../../../main/ets/service/platform/AppRuntime';
import {
  HiLogService,
  LogRecord,
  LogSink
} from '../../../../main/ets/service/platform/HiLogService';
import { AppStateStore } from '../../../../main/ets/store/AppStateStore';
import { LazyHarmonyPreferencesStore } from '../../../../main/ets/storage/preferences/PreferencesStore';
import {
  EffectiveTheme,
  SystemThemeListener,
  ThemePlatform
} from '../../../../main/ets/theme/ThemeModels';
import { SettingsViewModel } from '../../../../main/ets/viewmodel/settings/SettingsViewModel';

class SilentLogSink implements LogSink {
  write(record: LogRecord): void {
  }
}

class DeviceFakeThemePlatform implements ThemePlatform {
  private systemTheme: EffectiveTheme;
  private listener?: SystemThemeListener;

  constructor(systemTheme: EffectiveTheme) {
    this.systemTheme = systemTheme;
  }

  getSystemTheme(): EffectiveTheme {
    return this.systemTheme;
  }

  applyThemeMode(mode: ThemeMode): void {
  }

  start(listener: SystemThemeListener): void {
    this.listener = listener;
  }

  stop(): void {
    this.listener = undefined;
  }

  emitSystemTheme(theme: EffectiveTheme): void {
    this.systemTheme = theme;
    this.listener?.(theme);
  }
}

class DeviceFailureSettingsRepository implements SettingsRepository {
  private failRead: boolean;
  private failWrite: boolean;

  constructor(failRead: boolean, failWrite: boolean) {
    this.failRead = failRead;
    this.failWrite = failWrite;
  }

  async get(): Promise<AppResult<UserSettings>> {
    if (this.failRead) {
      return createFailureResult<UserSettings>({
        code: ErrorCode.SETTINGS_READ_FAILED,
        message: '设置读取失败，已使用安全默认主题。',
        retryable: true
      });
    }
    return createSuccessResult<UserSettings>(createDefaultUserSettings());
  }

  async update(settings: UserSettings): Promise<AppResult<UserSettings>> {
    if (this.failWrite) {
      return createFailureResult<UserSettings>({
        code: ErrorCode.SETTINGS_WRITE_FAILED,
        message: '设置保存失败，请重试。',
        retryable: true
      });
    }
    return createSuccessResult<UserSettings>(settings);
  }

  async reset(): Promise<AppResult<UserSettings>> {
    return createSuccessResult<UserSettings>(createDefaultUserSettings());
  }
}

function createDeviceViewModel(
  repository: SettingsRepository,
  store: AppStateStore,
  systemTheme: EffectiveTheme
): SettingsViewModel {
  return new SettingsViewModel(
    repository,
    store,
    new DeviceFakeThemePlatform(systemTheme),
    new HiLogService(new SilentLogSink())
  );
}

export default function themeStateTest() {
  describe('ThemeState', () => {
    it('restores the persisted theme into a reconstructed Store and ViewModel', 0, async () => {
      expect(await switchApplicationTheme(ThemeMode.DARK)).assertTrue();
      const ability = await abilityDelegatorRegistry.getAbilityDelegator().getCurrentTopAbility();
      const context = ability.context;
      const repository = new LocalSettingsRepository(
        new LazyHarmonyPreferencesStore(context, SETTINGS_PREFERENCES_NAME),
        new HiLogService(new SilentLogSink())
      );
      const reconstructedStore = new AppStateStore();
      const reconstructed = createDeviceViewModel(
        repository,
        reconstructedStore,
        EffectiveTheme.LIGHT
      );

      expect(await reconstructed.initialize()).assertTrue();
      expect(reconstructedStore.selectedThemeMode).assertEqual(ThemeMode.DARK);
      expect(reconstructedStore.effectiveTheme).assertEqual(EffectiveTheme.DARK);
      reconstructed.dispose();
      expect(await switchApplicationTheme(ThemeMode.SYSTEM)).assertTrue();
    });

    it('keeps the rendered home page usable when the runtime settings read fails', 0, async () => {
      const ability = await abilityDelegatorRegistry.getAbilityDelegator().getCurrentTopAbility();
      await switchApplicationTheme(ThemeMode.SYSTEM);
      await configureAppRuntimeWithAdapters(
        new DeviceFailureSettingsRepository(true, false),
        new DeviceFakeThemePlatform(EffectiveTheme.LIGHT),
        new HiLogService(new SilentLogSink())
      );
      const driver = Driver.create();

      expect(appStateStore.loadState.status).assertEqual(OperationStatus.ERROR);
      expect(appStateStore.selectedThemeMode).assertEqual(ThemeMode.SYSTEM);
      const scroll = await driver.findComponent(ON.id('home_scroll'));
      await scroll.scrollSearch(ON.text('开发报错诊断助手'));
      await driver.assertComponentExist(ON.text('当前主题：SYSTEM/LIGHT'));
      await configureAppRuntime(ability.context);
    });

    it('renders a failed write as a clearly session-only theme', 0, async () => {
      const ability = await abilityDelegatorRegistry.getAbilityDelegator().getCurrentTopAbility();
      await configureAppRuntimeWithAdapters(
        new DeviceFailureSettingsRepository(false, true),
        new DeviceFakeThemePlatform(EffectiveTheme.LIGHT),
        new HiLogService(new SilentLogSink())
      );

      expect(await switchApplicationTheme(ThemeMode.DARK)).assertFalse();
      expect(appStateStore.saveState.status).assertEqual(OperationStatus.ERROR);
      expect(appStateStore.isThemeSessionOnly).assertTrue();
      const driver = Driver.create();
      const scroll = await driver.findComponent(ON.id('home_scroll'));
      await scroll.scrollSearch(ON.text('当前主题：DARK/DARK'));
      await scroll.scrollSearch(ON.text('主题仅在本次会话生效，保存失败后可重试'));
      await configureAppRuntime(ability.context);
    });

    it('updates the rendered SYSTEM theme when the platform color mode changes', 0, async () => {
      const ability = await abilityDelegatorRegistry.getAbilityDelegator().getCurrentTopAbility();
      const platform = new DeviceFakeThemePlatform(EffectiveTheme.DARK);
      await configureAppRuntimeWithAdapters(
        new DeviceFailureSettingsRepository(false, false),
        platform,
        new HiLogService(new SilentLogSink())
      );
      const driver = Driver.create();

      await driver.assertComponentExist(ON.text('当前主题：SYSTEM/DARK'));
      platform.emitSystemTheme(EffectiveTheme.LIGHT);
      await driver.delayMs(200);
      await driver.assertComponentExist(ON.text('当前主题：SYSTEM/LIGHT'));
      await configureAppRuntime(ability.context);
    });
  });
}
