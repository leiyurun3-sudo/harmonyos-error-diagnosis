import { HISTORY_RECORD_LIMIT } from '../constants/AppLimits';

/** Stable values persisted by the settings repository. */
export enum ThemeMode {
  SYSTEM = 'SYSTEM',
  LIGHT = 'LIGHT',
  DARK = 'DARK'
}

export enum AccentTheme {
  BLUE = 'BLUE',
  CYAN = 'CYAN',
  PURPLE = 'PURPLE',
  GREEN = 'GREEN'
}

export enum ContentFontScale {
  COMPACT = 'COMPACT',
  STANDARD = 'STANDARD',
  LARGE = 'LARGE'
}

export enum VisualEffectMode {
  FULL = 'FULL',
  REDUCED = 'REDUCED',
  OFF = 'OFF'
}

/** Preferences-backed user settings. No field contains sensitive data. */
export interface UserSettings {
  themeMode: ThemeMode;
  historyLimit: number;
  firstLaunchCompleted: boolean;
  draftRecoveryEnabled: boolean;
  accentTheme: AccentTheme;
  contentFontScale: ContentFontScale;
  visualEffectMode: VisualEffectMode;
}

/** Returns a new settings object with the documented P0 defaults. */
export function createDefaultUserSettings(): UserSettings {
  return {
    themeMode: ThemeMode.SYSTEM,
    historyLimit: HISTORY_RECORD_LIMIT,
    firstLaunchCompleted: false,
    draftRecoveryEnabled: false,
    accentTheme: AccentTheme.BLUE,
    contentFontScale: ContentFontScale.STANDARD,
    visualEffectMode: VisualEffectMode.FULL
  };
}
