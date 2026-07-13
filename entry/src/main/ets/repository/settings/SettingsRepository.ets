import { HISTORY_RECORD_LIMIT } from '../../constants/AppLimits';
import { ErrorCode } from '../../constants/ErrorCodes';
import {
  SETTINGS_SCHEMA_VERSION,
  StorageKey
} from '../../constants/StorageKeys';
import {
  AppResult,
  createFailureResult,
  createSuccessResult
} from '../../model/ResultModels';
import {
  createDefaultUserSettings,
  ThemeMode,
  UserSettings
} from '../../model/SettingsModels';
import {
  HiLogService,
  LogLevel,
  LogMetadataKey
} from '../../service/platform/HiLogService';
import {
  PreferenceValue,
  PreferencesStore
} from '../../storage/preferences/PreferencesStore';

export interface SettingsRepository {
  get(): Promise<AppResult<UserSettings>>;
  update(settings: UserSettings): Promise<AppResult<UserSettings>>;
  reset(): Promise<AppResult<UserSettings>>;
}

function copySettings(settings: UserSettings): UserSettings {
  return {
    themeMode: settings.themeMode,
    historyLimit: settings.historyLimit,
    firstLaunchCompleted: settings.firstLaunchCompleted,
    draftRecoveryEnabled: settings.draftRecoveryEnabled
  };
}

function normalizedTheme(value: PreferenceValue): ThemeMode {
  if (value === ThemeMode.LIGHT) {
    return ThemeMode.LIGHT;
  }
  if (value === ThemeMode.DARK) {
    return ThemeMode.DARK;
  }
  return ThemeMode.SYSTEM;
}

function normalizedBoolean(value: PreferenceValue, defaultValue: boolean): boolean {
  return typeof value === 'boolean' ? value : defaultValue;
}

function normalizedHistoryLimit(value: PreferenceValue): number {
  return typeof value === 'number' && value === HISTORY_RECORD_LIMIT ? value : HISTORY_RECORD_LIMIT;
}

function normalizedSettings(settings: UserSettings): UserSettings {
  return {
    themeMode: normalizedTheme(settings.themeMode),
    historyLimit: normalizedHistoryLimit(settings.historyLimit),
    firstLaunchCompleted: normalizedBoolean(settings.firstLaunchCompleted, false),
    draftRecoveryEnabled: normalizedBoolean(settings.draftRecoveryEnabled, false)
  };
}

/** Preferences-backed P0 settings repository. */
export class LocalSettingsRepository implements SettingsRepository {
  private store: PreferencesStore;
  private logger: HiLogService;

  constructor(store: PreferencesStore, logger: HiLogService) {
    this.store = store;
    this.logger = logger;
  }

  async get(): Promise<AppResult<UserSettings>> {
    const defaults = createDefaultUserSettings();
    try {
      const schemaVersion = await this.store.read(StorageKey.SCHEMA_VERSION, SETTINGS_SCHEMA_VERSION);
      if (typeof schemaVersion !== 'number' || schemaVersion !== SETTINGS_SCHEMA_VERSION) {
        return createSuccessResult<UserSettings>(defaults);
      }
      const themeMode = await this.store.read(StorageKey.THEME_MODE, defaults.themeMode);
      const historyLimit = await this.store.read(StorageKey.HISTORY_LIMIT, defaults.historyLimit);
      const firstLaunchCompleted = await this.store.read(
        StorageKey.FIRST_LAUNCH_COMPLETED,
        defaults.firstLaunchCompleted
      );
      const draftRecoveryEnabled = await this.store.read(
        StorageKey.DRAFT_RECOVERY_ENABLED,
        defaults.draftRecoveryEnabled
      );
      return createSuccessResult<UserSettings>({
        themeMode: normalizedTheme(themeMode),
        historyLimit: normalizedHistoryLimit(historyLimit),
        firstLaunchCompleted: normalizedBoolean(firstLaunchCompleted, defaults.firstLaunchCompleted),
        draftRecoveryEnabled: normalizedBoolean(draftRecoveryEnabled, defaults.draftRecoveryEnabled)
      });
    } catch (_) {
      return this.readFailure();
    }
  }

  async update(settings: UserSettings): Promise<AppResult<UserSettings>> {
    try {
      const normalized = normalizedSettings(settings);
      await this.persist(normalized);
      return createSuccessResult<UserSettings>(copySettings(normalized));
    } catch (_) {
      return this.writeFailure('update');
    }
  }

  async reset(): Promise<AppResult<UserSettings>> {
    try {
      const defaults = createDefaultUserSettings();
      await this.persist(defaults);
      return createSuccessResult<UserSettings>(copySettings(defaults));
    } catch (_) {
      return this.writeFailure('reset');
    }
  }

  private async persist(settings: UserSettings): Promise<void> {
    await this.store.write(StorageKey.THEME_MODE, settings.themeMode);
    await this.store.write(StorageKey.HISTORY_LIMIT, settings.historyLimit);
    await this.store.write(StorageKey.FIRST_LAUNCH_COMPLETED, settings.firstLaunchCompleted);
    await this.store.write(StorageKey.DRAFT_RECOVERY_ENABLED, settings.draftRecoveryEnabled);
    await this.store.write(StorageKey.SCHEMA_VERSION, SETTINGS_SCHEMA_VERSION);
    await this.store.flush();
  }

  private readFailure(): AppResult<UserSettings> {
    this.logFailure('read', ErrorCode.SETTINGS_READ_FAILED);
    return createFailureResult<UserSettings>({
      code: ErrorCode.SETTINGS_READ_FAILED,
      message: '设置读取失败，已使用默认设置。',
      retryable: true,
      causeType: 'PREFERENCES_READ'
    });
  }

  private writeFailure(stage: string): AppResult<UserSettings> {
    this.logFailure(stage, ErrorCode.SETTINGS_WRITE_FAILED);
    return createFailureResult<UserSettings>({
      code: ErrorCode.SETTINGS_WRITE_FAILED,
      message: '设置保存失败，请重试。',
      retryable: true,
      causeType: 'PREFERENCES_WRITE'
    });
  }

  private logFailure(stage: string, code: ErrorCode): void {
    this.logger.log(LogLevel.ERROR, {
      domain: 'settings',
      event: 'preferences_failed',
      errorCode: code,
      metadata: [
        { key: LogMetadataKey.STAGE, value: stage }
      ]
    });
  }
}
