import {
  AppResult,
  createSuccessResult
} from '../../main/ets/model/ResultModels';
import {
  createDefaultUserSettings,
  UserSettings
} from '../../main/ets/model/SettingsModels';
import { SettingsRepository } from '../../main/ets/repository/settings/SettingsRepository';

function copySettings(settings: UserSettings): UserSettings {
  return {
    themeMode: settings.themeMode,
    historyLimit: settings.historyLimit,
    firstLaunchCompleted: settings.firstLaunchCompleted,
    draftRecoveryEnabled: settings.draftRecoveryEnabled,
    accentTheme: settings.accentTheme,
    contentFontScale: settings.contentFontScale,
    visualEffectMode: settings.visualEffectMode
  };
}

export class FakeSettingsRepository implements SettingsRepository {
  getResult: AppResult<UserSettings> = createSuccessResult<UserSettings>(createDefaultUserSettings());
  updateResults: Array<AppResult<UserSettings>> = [];
  resetResult: AppResult<UserSettings> = createSuccessResult<UserSettings>(createDefaultUserSettings());
  updates: Array<UserSettings> = [];
  getCount: number = 0;
  resetCount: number = 0;
  getDelayMs: number = 0;
  updateDelayMs: number = 0;

  async get(): Promise<AppResult<UserSettings>> {
    this.getCount++;
    if (this.getDelayMs > 0) {
      await new Promise<void>((resolve: () => void) => {
        setTimeout(resolve, this.getDelayMs);
      });
    }
    return this.getResult;
  }

  async update(settings: UserSettings): Promise<AppResult<UserSettings>> {
    this.updates.push(copySettings(settings));
    if (this.updateDelayMs > 0) {
      await new Promise<void>((resolve: () => void) => {
        setTimeout(resolve, this.updateDelayMs);
      });
    }
    if (this.updateResults.length > 0) {
      return this.updateResults.shift() as AppResult<UserSettings>;
    }
    return createSuccessResult<UserSettings>(copySettings(settings));
  }

  async reset(): Promise<AppResult<UserSettings>> {
    this.resetCount++;
    return this.resetResult;
  }
}
