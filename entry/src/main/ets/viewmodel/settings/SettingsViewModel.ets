import { ErrorCode } from '../../constants/ErrorCodes';
import {
  AppError,
  AppResult,
  OperationStatus
} from '../../model/ResultModels';
import {
  AccentTheme,
  ContentFontScale,
  ThemeMode,
  UserSettings,
  VisualEffectMode
} from '../../model/SettingsModels';
import { SettingsRepository } from '../../repository/settings/SettingsRepository';
import {
  HiLogService,
  LogLevel,
  LogMetadataKey
} from '../../service/platform/HiLogService';
import { AppStateStore } from '../../store/AppStateStore';
import {
  EffectiveTheme,
  ThemePlatform
} from '../../theme/ThemeModels';

function fallbackError(code: ErrorCode): AppError {
  const readFailure = code === ErrorCode.SETTINGS_READ_FAILED;
  return {
    code: code,
    message: readFailure ? '设置读取失败，已使用安全默认主题。' : '设置保存失败，请重试。',
    retryable: true,
    causeType: readFailure ? 'SETTINGS_READ' : 'SETTINGS_WRITE'
  };
}

function resultError(result: AppResult<UserSettings>, code: ErrorCode): AppError {
  return result.error === undefined ? fallbackError(code) : result.error;
}

/** Orchestrates SettingsRepository, platform theme APIs and the single AppStateStore. */
export class SettingsViewModel {
  private repository: SettingsRepository;
  private store: AppStateStore;
  private themePlatform: ThemePlatform;
  private logger: HiLogService;
  private observingSystemTheme: boolean = false;
  private initializationPromise?: Promise<boolean>;
  private settingsRevision: number = 0;
  private lifecycleGeneration: number = 0;

  constructor(
    repository: SettingsRepository,
    store: AppStateStore,
    themePlatform: ThemePlatform,
    logger: HiLogService
  ) {
    this.repository = repository;
    this.store = store;
    this.themePlatform = themePlatform;
    this.logger = logger;
  }

  get settings(): UserSettings {
    return this.store.settings;
  }

  initialize(): Promise<boolean> {
    if (this.initializationPromise !== undefined) {
      return this.initializationPromise;
    }
    const generation = this.lifecycleGeneration;
    const revision = this.settingsRevision;
    this.initializationPromise = this.loadSettings(generation, revision);
    return this.initializationPromise;
  }

  private async loadSettings(generation: number, revision: number): Promise<boolean> {
    if (!this.store.beginLoad()) {
      return false;
    }
    this.startSystemThemeObservation();
    this.themePlatform.applyThemeMode(this.store.selectedThemeMode);
    let result: AppResult<UserSettings>;
    try {
      result = await this.repository.get();
    } catch (_) {
      result = {
        success: false,
        error: fallbackError(ErrorCode.SETTINGS_READ_FAILED)
      };
    }
    if (generation !== this.lifecycleGeneration) {
      return false;
    }
    if (!result.success || result.data === undefined) {
      const error = resultError(result, ErrorCode.SETTINGS_READ_FAILED);
      this.store.failLoad(error);
      this.logFailure('load', error.code, this.store.isThemeSessionOnly);
      return false;
    }
    if (revision === this.settingsRevision) {
      this.store.completeLoad(result.data);
    } else {
      this.store.completeLoadPreservingTheme(result.data);
    }
    this.themePlatform.applyThemeMode(this.store.selectedThemeMode);
    this.logSuccess('load', this.store.selectedThemeMode);
    return true;
  }

  async switchTheme(themeMode: ThemeMode): Promise<boolean> {
    if (this.store.saveState.status === OperationStatus.LOADING || !this.store.beginSave(themeMode)) {
      return false;
    }
    this.settingsRevision++;
    const generation = this.lifecycleGeneration;
    if (themeMode === ThemeMode.SYSTEM) {
      this.store.updateSystemTheme(this.themePlatform.getSystemTheme());
    }
    this.themePlatform.applyThemeMode(themeMode);
    if (this.initializationPromise !== undefined) {
      await this.initializationPromise;
    }
    if (generation !== this.lifecycleGeneration) {
      return false;
    }
    let result: AppResult<UserSettings>;
    try {
      result = await this.repository.update(this.store.settings);
    } catch (_) {
      result = {
        success: false,
        error: fallbackError(ErrorCode.SETTINGS_WRITE_FAILED)
      };
    }
    if (generation !== this.lifecycleGeneration) {
      return false;
    }
    return this.finishSave(result, 'update');
  }

  async updateVisualPreferences(
    accentTheme: AccentTheme,
    contentFontScale: ContentFontScale,
    visualEffectMode: VisualEffectMode
  ): Promise<boolean> {
    if (this.store.saveState.status === OperationStatus.LOADING ||
      !this.store.beginVisualSave(accentTheme, contentFontScale, visualEffectMode)) {
      return false;
    }
    this.settingsRevision++;
    const generation = this.lifecycleGeneration;
    if (this.initializationPromise !== undefined) {
      await this.initializationPromise;
    }
    if (generation !== this.lifecycleGeneration) {
      return false;
    }
    let result: AppResult<UserSettings>;
    try {
      result = await this.repository.update(this.store.settings);
    } catch (_) {
      result = {
        success: false,
        error: fallbackError(ErrorCode.SETTINGS_WRITE_FAILED)
      };
    }
    if (generation !== this.lifecycleGeneration) {
      return false;
    }
    return this.finishSave(result, 'visual');
  }

  async resetSettings(): Promise<boolean> {
    if (this.store.saveState.status === OperationStatus.LOADING || !this.store.beginSave(ThemeMode.SYSTEM)) {
      return false;
    }
    this.settingsRevision++;
    const generation = this.lifecycleGeneration;
    this.store.updateSystemTheme(this.themePlatform.getSystemTheme());
    this.themePlatform.applyThemeMode(ThemeMode.SYSTEM);
    if (this.initializationPromise !== undefined) {
      await this.initializationPromise;
    }
    if (generation !== this.lifecycleGeneration) {
      return false;
    }
    let result: AppResult<UserSettings>;
    try {
      result = await this.repository.reset();
    } catch (_) {
      result = {
        success: false,
        error: fallbackError(ErrorCode.SETTINGS_WRITE_FAILED)
      };
    }
    if (generation !== this.lifecycleGeneration) {
      return false;
    }
    return this.finishSave(result, 'reset');
  }

  clearError(): void {
    this.store.clearSettingsError();
  }

  dispose(): void {
    this.lifecycleGeneration++;
    this.store.cancelLoad();
    this.store.cancelSave();
    if (this.observingSystemTheme) {
      this.themePlatform.stop();
      this.observingSystemTheme = false;
    }
  }

  private finishSave(result: AppResult<UserSettings>, stage: string): boolean {
    if (!result.success || result.data === undefined) {
      const error = resultError(result, ErrorCode.SETTINGS_WRITE_FAILED);
      this.store.failSave(error);
      this.logFailure(stage, error.code, true);
      return false;
    }
    this.store.completeSave(result.data);
    this.themePlatform.applyThemeMode(result.data.themeMode);
    this.logSuccess(stage, result.data.themeMode);
    return true;
  }

  private startSystemThemeObservation(): void {
    this.store.updateSystemTheme(this.themePlatform.getSystemTheme());
    if (this.observingSystemTheme) {
      return;
    }
    this.themePlatform.start((theme: EffectiveTheme): void => {
      this.store.updateSystemTheme(theme);
    });
    this.observingSystemTheme = true;
  }

  private logSuccess(stage: string, themeMode: ThemeMode): void {
    this.logger.log(LogLevel.INFO, {
      domain: 'settings',
      event: 'theme_state_updated',
      result: 'success',
      metadata: [
        { key: LogMetadataKey.STAGE, value: `${stage}:${themeMode}` }
      ]
    });
  }

  private logFailure(stage: string, errorCode: string, sessionOnly: boolean): void {
    this.logger.log(LogLevel.ERROR, {
      domain: 'settings',
      event: 'theme_state_failed',
      result: sessionOnly ? 'session_only' : 'safe_default',
      errorCode: errorCode,
      metadata: [
        { key: LogMetadataKey.STAGE, value: stage }
      ]
    });
  }
}
