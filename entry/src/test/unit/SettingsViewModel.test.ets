import { describe, expect, it } from '@ohos/hypium';
import { ErrorCode } from '../../main/ets/constants/ErrorCodes';
import {
  AppResult,
  createFailureResult,
  createSuccessResult,
  OperationStatus
} from '../../main/ets/model/ResultModels';
import {
  AccentTheme,
  ContentFontScale,
  createDefaultUserSettings,
  ThemeMode,
  UserSettings,
  VisualEffectMode
} from '../../main/ets/model/SettingsModels';
import { HiLogService } from '../../main/ets/service/platform/HiLogService';
import { AppStateStore } from '../../main/ets/store/AppStateStore';
import { EffectiveTheme } from '../../main/ets/theme/ThemeModels';
import { SettingsViewModel } from '../../main/ets/viewmodel/settings/SettingsViewModel';
import { CapturingLogSink } from '../fakes/CapturingLogSink';
import { FakeSettingsRepository } from '../fakes/FakeSettingsRepository';
import { FakeThemePlatform } from '../fakes/FakeThemePlatform';

function settingsWithTheme(themeMode: ThemeMode): UserSettings {
  const settings = createDefaultUserSettings();
  settings.themeMode = themeMode;
  return settings;
}

function failure(code: ErrorCode): AppResult<UserSettings> {
  return createFailureResult<UserSettings>({
    code: code,
    message: '可安全展示的设置错误',
    retryable: true,
    causeType: 'SYNTHETIC_TEST'
  });
}

interface ViewModelFixture {
  repository: FakeSettingsRepository;
  platform: FakeThemePlatform;
  store: AppStateStore;
  sink: CapturingLogSink;
  viewModel: SettingsViewModel;
}

function createFixture(systemTheme: EffectiveTheme = EffectiveTheme.LIGHT): ViewModelFixture {
  const repository = new FakeSettingsRepository();
  const platform = new FakeThemePlatform(systemTheme);
  const store = new AppStateStore();
  const sink = new CapturingLogSink();
  return {
    repository: repository,
    platform: platform,
    store: store,
    sink: sink,
    viewModel: new SettingsViewModel(repository, store, platform, new HiLogService(sink))
  };
}

export default function settingsViewModelTest() {
  describe('SettingsViewModel', () => {
    it('loads SYSTEM without blocking the initial store', 0, async () => {
      const fixture = createFixture(EffectiveTheme.DARK);
      const promise = fixture.viewModel.initialize();

      expect(fixture.store.selectedThemeMode).assertEqual(ThemeMode.SYSTEM);
      expect(fixture.store.loadState.status).assertEqual(OperationStatus.LOADING);
      await promise;
      expect(fixture.store.effectiveTheme).assertEqual(EffectiveTheme.DARK);
      expect(fixture.store.loadState.status).assertEqual(OperationStatus.SUCCESS);
    });

    it('restores LIGHT on startup', 0, async () => {
      const fixture = createFixture(EffectiveTheme.DARK);
      fixture.repository.getResult = createSuccessResult<UserSettings>(settingsWithTheme(ThemeMode.LIGHT));

      await fixture.viewModel.initialize();

      expect(fixture.store.selectedThemeMode).assertEqual(ThemeMode.LIGHT);
      expect(fixture.store.effectiveTheme).assertEqual(EffectiveTheme.LIGHT);
      expect(fixture.platform.appliedModes[fixture.platform.appliedModes.length - 1])
        .assertEqual(ThemeMode.LIGHT);
    });

    it('restores DARK on startup', 0, async () => {
      const fixture = createFixture();
      fixture.repository.getResult = createSuccessResult<UserSettings>(settingsWithTheme(ThemeMode.DARK));

      await fixture.viewModel.initialize();

      expect(fixture.store.selectedThemeMode).assertEqual(ThemeMode.DARK);
      expect(fixture.store.effectiveTheme).assertEqual(EffectiveTheme.DARK);
    });

    it('keeps safe SYSTEM theme and exposes standardized read failure', 0, async () => {
      const fixture = createFixture();
      fixture.repository.getResult = failure(ErrorCode.SETTINGS_READ_FAILED);

      await fixture.viewModel.initialize();

      expect(fixture.store.selectedThemeMode).assertEqual(ThemeMode.SYSTEM);
      expect(fixture.store.loadState.status).assertEqual(OperationStatus.ERROR);
      expect(fixture.store.lastSettingsError?.code).assertEqual(ErrorCode.SETTINGS_READ_FAILED);
    });

    it('switches LIGHT immediately and persists the complete settings', 0, async () => {
      const fixture = createFixture(EffectiveTheme.DARK);
      const promise = fixture.viewModel.switchTheme(ThemeMode.LIGHT);

      expect(fixture.store.effectiveTheme).assertEqual(EffectiveTheme.LIGHT);
      expect(fixture.store.saveState.status).assertEqual(OperationStatus.LOADING);
      const saved = await promise;
      expect(saved).assertTrue();
      expect(fixture.repository.updates[0].themeMode).assertEqual(ThemeMode.LIGHT);
      expect(fixture.store.saveState.status).assertEqual(OperationStatus.SUCCESS);
    });

    it('switches DARK successfully', 0, async () => {
      const fixture = createFixture();

      expect(await fixture.viewModel.switchTheme(ThemeMode.DARK)).assertTrue();
      expect(fixture.store.selectedThemeMode).assertEqual(ThemeMode.DARK);
      expect(fixture.store.effectiveTheme).assertEqual(EffectiveTheme.DARK);
    });

    it('updates and persists visual preferences as one settings transaction', 0, async () => {
      const fixture = createFixture();

      const saved = await fixture.viewModel.updateVisualPreferences(
        AccentTheme.GREEN,
        ContentFontScale.LARGE,
        VisualEffectMode.REDUCED
      );

      expect(saved).assertTrue();
      expect(fixture.store.accentTheme).assertEqual(AccentTheme.GREEN);
      expect(fixture.store.contentFontScale).assertEqual(ContentFontScale.LARGE);
      expect(fixture.store.contentFontMultiplier).assertEqual(1.15);
      expect(fixture.store.visualEffectMode).assertEqual(VisualEffectMode.REDUCED);
      expect(fixture.repository.updates[0].accentTheme).assertEqual(AccentTheme.GREEN);
      expect(fixture.repository.updates[0].contentFontScale).assertEqual(ContentFontScale.LARGE);
      expect(fixture.repository.updates[0].visualEffectMode).assertEqual(VisualEffectMode.REDUCED);
    });

    it('switches back to SYSTEM and follows the current system theme', 0, async () => {
      const fixture = createFixture(EffectiveTheme.DARK);
      await fixture.viewModel.switchTheme(ThemeMode.LIGHT);

      expect(await fixture.viewModel.switchTheme(ThemeMode.SYSTEM)).assertTrue();
      expect(fixture.store.selectedThemeMode).assertEqual(ThemeMode.SYSTEM);
      expect(fixture.store.effectiveTheme).assertEqual(EffectiveTheme.DARK);
    });

    it('keeps a failed write effective only for the current session', 0, async () => {
      const fixture = createFixture();
      fixture.repository.updateResults.push(failure(ErrorCode.SETTINGS_WRITE_FAILED));

      const saved = await fixture.viewModel.switchTheme(ThemeMode.DARK);

      expect(saved).assertFalse();
      expect(fixture.store.selectedThemeMode).assertEqual(ThemeMode.DARK);
      expect(fixture.store.effectiveTheme).assertEqual(EffectiveTheme.DARK);
      expect(fixture.store.saveState.status).assertEqual(OperationStatus.ERROR);
      expect(fixture.store.isThemeSessionOnly).assertTrue();
      expect(fixture.store.lastSettingsError?.code).assertEqual(ErrorCode.SETTINGS_WRITE_FAILED);
    });

    it('retries normally after a failed write', 0, async () => {
      const fixture = createFixture();
      fixture.repository.updateResults.push(failure(ErrorCode.SETTINGS_WRITE_FAILED));
      fixture.repository.updateResults.push(createSuccessResult<UserSettings>(settingsWithTheme(ThemeMode.LIGHT)));
      await fixture.viewModel.switchTheme(ThemeMode.DARK);

      const saved = await fixture.viewModel.switchTheme(ThemeMode.LIGHT);

      expect(saved).assertTrue();
      expect(fixture.repository.updates.length).assertEqual(2);
      expect(fixture.store.isThemeSessionOnly).assertFalse();
      expect(fixture.store.saveState.status).assertEqual(OperationStatus.SUCCESS);
    });

    it('rejects duplicate submissions while save is LOADING', 0, async () => {
      const fixture = createFixture();
      fixture.repository.updateDelayMs = 80;

      const first = fixture.viewModel.switchTheme(ThemeMode.DARK);
      const duplicate = await fixture.viewModel.switchTheme(ThemeMode.LIGHT);
      await first;

      expect(duplicate).assertFalse();
      expect(fixture.repository.updates.length).assertEqual(1);
      expect(fixture.store.selectedThemeMode).assertEqual(ThemeMode.DARK);
    });

    it('does not let a stale startup read overwrite a newer user theme', 0, async () => {
      const fixture = createFixture();
      fixture.repository.getDelayMs = 80;
      const persisted = settingsWithTheme(ThemeMode.LIGHT);
      persisted.firstLaunchCompleted = true;
      persisted.draftRecoveryEnabled = true;
      fixture.repository.getResult = createSuccessResult<UserSettings>(persisted);
      const initialization = fixture.viewModel.initialize();

      const saved = await fixture.viewModel.switchTheme(ThemeMode.DARK);
      await initialization;

      expect(saved).assertTrue();
      expect(fixture.store.selectedThemeMode).assertEqual(ThemeMode.DARK);
      expect(fixture.store.effectiveTheme).assertEqual(EffectiveTheme.DARK);
      expect(fixture.repository.updates[0].themeMode).assertEqual(ThemeMode.DARK);
      expect(fixture.repository.updates[0].firstLaunchCompleted).assertTrue();
      expect(fixture.repository.updates[0].draftRecoveryEnabled).assertTrue();
    });

    it('restores a persisted theme after Store and ViewModel reconstruction', 0, async () => {
      const first = createFixture();
      await first.viewModel.switchTheme(ThemeMode.DARK);
      const second = createFixture();
      second.repository.getResult = createSuccessResult<UserSettings>(first.repository.updates[0]);

      await second.viewModel.initialize();

      expect(second.store.selectedThemeMode).assertEqual(ThemeMode.DARK);
      expect(second.store.effectiveTheme).assertEqual(EffectiveTheme.DARK);
    });

    it('updates SYSTEM when the real system theme changes', 0, async () => {
      const fixture = createFixture();
      await fixture.viewModel.initialize();

      fixture.platform.emitSystemTheme(EffectiveTheme.DARK);

      expect(fixture.store.effectiveTheme).assertEqual(EffectiveTheme.DARK);
    });

    it('does not let system changes override explicit LIGHT or DARK', 0, async () => {
      const fixture = createFixture();
      await fixture.viewModel.initialize();
      await fixture.viewModel.switchTheme(ThemeMode.DARK);

      fixture.platform.emitSystemTheme(EffectiveTheme.LIGHT);

      expect(fixture.store.selectedThemeMode).assertEqual(ThemeMode.DARK);
      expect(fixture.store.effectiveTheme).assertEqual(EffectiveTheme.DARK);
    });

    it('resets through Repository without creating page behavior', 0, async () => {
      const fixture = createFixture(EffectiveTheme.DARK);
      await fixture.viewModel.switchTheme(ThemeMode.LIGHT);

      const reset = await fixture.viewModel.resetSettings();

      expect(reset).assertTrue();
      expect(fixture.repository.resetCount).assertEqual(1);
      expect(fixture.store.selectedThemeMode).assertEqual(ThemeMode.SYSTEM);
      expect(fixture.store.effectiveTheme).assertEqual(EffectiveTheme.DARK);
    });

    it('clears a displayed error without mutating operation history', 0, async () => {
      const fixture = createFixture();
      fixture.repository.getResult = failure(ErrorCode.SETTINGS_READ_FAILED);
      await fixture.viewModel.initialize();

      fixture.viewModel.clearError();

      expect(fixture.store.lastSettingsError === undefined).assertTrue();
      expect(fixture.store.loadState.status).assertEqual(OperationStatus.ERROR);
    });

    it('does not leak repository objects or platform exception text into logs', 0, async () => {
      const fixture = createFixture();
      fixture.repository.getResult = failure(ErrorCode.SETTINGS_READ_FAILED);
      await fixture.viewModel.initialize();
      const serialized = JSON.stringify(fixture.sink.records);

      expect(serialized.includes('SYNTHETIC_TEST')).assertFalse();
      expect(serialized.includes('historyLimit')).assertFalse();
      expect(serialized.includes('draftRecoveryEnabled')).assertFalse();
      expect(serialized.includes(ErrorCode.SETTINGS_READ_FAILED)).assertTrue();
    });

    it('stops observing system changes when disposed', 0, async () => {
      const fixture = createFixture();
      await fixture.viewModel.initialize();

      fixture.viewModel.dispose();

      expect(fixture.platform.stopCount).assertEqual(1);
    });
  });
}
