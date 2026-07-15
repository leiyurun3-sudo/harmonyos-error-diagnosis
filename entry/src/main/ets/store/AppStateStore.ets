import {
  AppError,
  createInitialOperationState,
  OperationState,
  OperationStatus
} from '../model/ResultModels';
import {
  AccentTheme,
  ContentFontScale,
  createDefaultUserSettings,
  ThemeMode,
  UserSettings,
  VisualEffectMode
} from '../model/SettingsModels';
import {
  EffectiveTheme,
  resolveEffectiveTheme
} from '../theme/ThemeModels';

function copyError(error: AppError): AppError {
  const copied: AppError = {
    code: error.code,
    message: error.message,
    retryable: error.retryable
  };
  if (error.causeType !== undefined) {
    copied.causeType = error.causeType;
  }
  if (error.correlationId !== undefined) {
    copied.correlationId = error.correlationId;
  }
  return copied;
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

function copyOperationState(state: OperationState): OperationState {
  const copied: OperationState = {
    status: state.status
  };
  if (state.error !== undefined) {
    copied.error = copyError(state.error);
  }
  if (state.correlationId !== undefined) {
    copied.correlationId = state.correlationId;
  }
  return copied;
}

/** Single observable source for application-level P0 settings and effective theme. */
@Observed
export class AppStateStore {
  selectedThemeMode: ThemeMode = ThemeMode.SYSTEM;
  systemTheme: EffectiveTheme = EffectiveTheme.LIGHT;
  effectiveTheme: EffectiveTheme = EffectiveTheme.LIGHT;
  isThemeSessionOnly: boolean = false;
  accentTheme: AccentTheme = AccentTheme.BLUE;
  contentFontScale: ContentFontScale = ContentFontScale.STANDARD;
  contentFontMultiplier: number = 1;
  visualEffectMode: VisualEffectMode = VisualEffectMode.FULL;

  private settingsValue: UserSettings = createDefaultUserSettings();
  private loadStateValue: OperationState = createInitialOperationState();
  private saveStateValue: OperationState = createInitialOperationState();
  private lastSettingsErrorValue?: AppError;

  get settings(): UserSettings {
    return copySettings(this.settingsValue);
  }

  get loadState(): OperationState {
    return copyOperationState(this.loadStateValue);
  }

  get saveState(): OperationState {
    return copyOperationState(this.saveStateValue);
  }

  get lastSettingsError(): AppError | undefined {
    return this.lastSettingsErrorValue === undefined ? undefined : copyError(this.lastSettingsErrorValue);
  }

  beginLoad(): boolean {
    if (this.loadStateValue.status === OperationStatus.LOADING) {
      return false;
    }
    this.loadStateValue = {
      status: OperationStatus.LOADING
    };
    this.lastSettingsErrorValue = undefined;
    return true;
  }

  completeLoad(settings: UserSettings): void {
    this.settingsValue = copySettings(settings);
    this.selectedThemeMode = settings.themeMode;
    this.applyVisualState(settings);
    this.recalculateEffectiveTheme();
    this.loadStateValue = {
      status: OperationStatus.SUCCESS
    };
    this.lastSettingsErrorValue = undefined;
    this.isThemeSessionOnly = false;
  }

  /** Completes a delayed startup read without replacing a newer session theme choice. */
  completeLoadPreservingTheme(settings: UserSettings): void {
    const merged = copySettings(settings);
    merged.themeMode = this.selectedThemeMode;
    merged.accentTheme = this.accentTheme;
    merged.contentFontScale = this.contentFontScale;
    merged.visualEffectMode = this.visualEffectMode;
    this.settingsValue = merged;
    this.recalculateEffectiveTheme();
    this.loadStateValue = {
      status: OperationStatus.SUCCESS
    };
  }

  failLoad(error: AppError): void {
    const copied = copyError(error);
    this.loadStateValue = {
      status: OperationStatus.ERROR,
      error: copied
    };
    this.lastSettingsErrorValue = copied;
  }

  cancelLoad(): void {
    if (this.loadStateValue.status === OperationStatus.LOADING) {
      this.loadStateValue = {
        status: OperationStatus.CANCELLED
      };
    }
  }

  beginSave(themeMode: ThemeMode): boolean {
    if (this.saveStateValue.status === OperationStatus.LOADING) {
      return false;
    }
    this.applySessionTheme(themeMode);
    this.saveStateValue = {
      status: OperationStatus.LOADING
    };
    this.lastSettingsErrorValue = undefined;
    return true;
  }

  beginVisualSave(
    accentTheme: AccentTheme,
    contentFontScale: ContentFontScale,
    visualEffectMode: VisualEffectMode
  ): boolean {
    if (this.saveStateValue.status === OperationStatus.LOADING) {
      return false;
    }
    const updated = copySettings(this.settingsValue);
    updated.accentTheme = accentTheme;
    updated.contentFontScale = contentFontScale;
    updated.visualEffectMode = visualEffectMode;
    this.settingsValue = updated;
    this.applyVisualState(updated);
    this.saveStateValue = {
      status: OperationStatus.LOADING
    };
    this.lastSettingsErrorValue = undefined;
    return true;
  }

  completeSave(settings: UserSettings): void {
    this.settingsValue = copySettings(settings);
    this.selectedThemeMode = settings.themeMode;
    this.applyVisualState(settings);
    this.recalculateEffectiveTheme();
    this.saveStateValue = {
      status: OperationStatus.SUCCESS
    };
    this.lastSettingsErrorValue = undefined;
    this.isThemeSessionOnly = false;
  }

  failSave(error: AppError): void {
    const copied = copyError(error);
    this.saveStateValue = {
      status: OperationStatus.ERROR,
      error: copied
    };
    this.lastSettingsErrorValue = copied;
    this.isThemeSessionOnly = true;
  }

  cancelSave(): void {
    if (this.saveStateValue.status === OperationStatus.LOADING) {
      this.saveStateValue = {
        status: OperationStatus.CANCELLED
      };
    }
  }

  updateSystemTheme(theme: EffectiveTheme): void {
    this.systemTheme = theme;
    this.recalculateEffectiveTheme();
  }

  clearSettingsError(): void {
    this.lastSettingsErrorValue = undefined;
  }

  private applySessionTheme(themeMode: ThemeMode): void {
    const updated = copySettings(this.settingsValue);
    updated.themeMode = themeMode;
    this.settingsValue = updated;
    this.selectedThemeMode = themeMode;
    this.recalculateEffectiveTheme();
  }

  private recalculateEffectiveTheme(): void {
    this.effectiveTheme = resolveEffectiveTheme(this.selectedThemeMode, this.systemTheme);
  }

  private applyVisualState(settings: UserSettings): void {
    this.accentTheme = settings.accentTheme;
    this.contentFontScale = settings.contentFontScale;
    if (settings.contentFontScale === ContentFontScale.COMPACT) {
      this.contentFontMultiplier = 0.9;
    } else if (settings.contentFontScale === ContentFontScale.LARGE) {
      this.contentFontMultiplier = 1.15;
    } else {
      this.contentFontMultiplier = 1;
    }
    this.visualEffectMode = settings.visualEffectMode;
  }
}
