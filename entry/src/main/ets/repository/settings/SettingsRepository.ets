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
  AccentTheme,
  ContentFontScale,
  createDefaultUserSettings,
  ThemeMode,
  UserSettings,
  VisualEffectMode
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
    draftRecoveryEnabled: settings.draftRecoveryEnabled,
    accentTheme: settings.accentTheme,
    contentFontScale: settings.contentFontScale,
    visualEffectMode: settings.visualEffectMode
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

function normalizedAccentTheme(value: PreferenceValue): AccentTheme {
  if (value === AccentTheme.CYAN || value === AccentTheme.PURPLE || value === AccentTheme.GREEN) {
    return value;
  }
  return AccentTheme.BLUE;
}

function normalizedContentFontScale(value: PreferenceValue): ContentFontScale {
  if (value === ContentFontScale.COMPACT || value === ContentFontScale.LARGE) {
    return value;
  }
  return ContentFontScale.STANDARD;
}

function normalizedVisualEffectMode(value: PreferenceValue): VisualEffectMode {
  if (value === VisualEffectMode.REDUCED || value === VisualEffectMode.OFF) {
    return value;
  }
  return VisualEffectMode.FULL;
}

function normalizedSettings(settings: UserSettings): UserSettings {
  return {
    themeMode: normalizedTheme(settings.themeMode),
    historyLimit: normalizedHistoryLimit(settings.historyLimit),
    firstLaunchCompleted: normalizedBoolean(settings.firstLaunchCompleted, false),
    draftRecoveryEnabled: normalizedBoolean(settings.draftRecoveryEnabled, false),
    accentTheme: normalizedAccentTheme(settings.accentTheme),
    contentFontScale: normalizedContentFontScale(settings.contentFontScale),
    visualEffectMode: normalizedVisualEffectMode(settings.visualEffectMode)
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
      if (typeof schemaVersion !== 'number' || (schemaVersion !== 1 && schemaVersion !== SETTINGS_SCHEMA_VERSION)) {
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
      const accentTheme = await this.store.read(StorageKey.ACCENT_THEME, defaults.accentTheme);
      const contentFontScale = await this.store.read(StorageKey.CONTENT_FONT_SCALE, defaults.contentFontScale);
      const visualEffectMode = await this.store.read(StorageKey.VISUAL_EFFECT_MODE, defaults.visualEffectMode);
      return createSuccessResult<UserSettings>({
        themeMode: normalizedTheme(themeMode),
        historyLimit: normalizedHistoryLimit(historyLimit),
        firstLaunchCompleted: normalizedBoolean(firstLaunchCompleted, defaults.firstLaunchCompleted),
        draftRecoveryEnabled: normalizedBoolean(draftRecoveryEnabled, defaults.draftRecoveryEnabled),
        accentTheme: normalizedAccentTheme(accentTheme),
        contentFontScale: normalizedContentFontScale(contentFontScale),
        visualEffectMode: normalizedVisualEffectMode(visualEffectMode)
      });
    } catch (_) {
      return this.readFailure();
    }
  }

  async update(settings: UserSettings): Promise<AppResult<UserSettings>> {
    try {
      const normalized = normalizedSettings(settings);
      await this.persistWithRollback(normalized);
      return createSuccessResult<UserSettings>(copySettings(normalized));
    } catch (_) {
      return this.writeFailure('update');
    }
  }

  async reset(): Promise<AppResult<UserSettings>> {
    try {
      const defaults = createDefaultUserSettings();
      await this.persistWithRollback(defaults);
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
    await this.store.write(StorageKey.ACCENT_THEME, settings.accentTheme);
    await this.store.write(StorageKey.CONTENT_FONT_SCALE, settings.contentFontScale);
    await this.store.write(StorageKey.VISUAL_EFFECT_MODE, settings.visualEffectMode);
    await this.store.write(StorageKey.SCHEMA_VERSION, SETTINGS_SCHEMA_VERSION);
    await this.store.flush();
  }

  private async persistWithRollback(settings: UserSettings): Promise<void> {
    const previous = await this.get();
    if (!previous.success || previous.data === undefined) {
      throw new Error('Settings snapshot unavailable');
    }
    try {
      await this.persist(settings);
    } catch (_) {
      try {
        await this.persist(previous.data);
      } catch (_) {
        // The original write failure remains authoritative; no platform details escape.
      }
      throw new Error('Settings persistence failed');
    }
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
