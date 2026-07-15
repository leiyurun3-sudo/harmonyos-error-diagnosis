import { AccentTheme, ThemeMode } from '../model/SettingsModels';

/** Resolved light/dark theme used by ArkUI after SYSTEM is evaluated. */
export enum EffectiveTheme {
  LIGHT = 'LIGHT',
  DARK = 'DARK'
}

/** Central P0 semantic colors. T23 may extend these tokens without changing pages. */
export interface ThemePalette {
  pageBackground: string;
  surfaceBackground: string;
  focusSurface: string;
  focusBorder: string;
  focusGlow: string;
  secondaryActionSurface: string;
  secondaryActionBorder: string;
  secondaryActionGlow: string;
  secondaryActionText: string;
  navigationBackground: string;
  primaryText: string;
  secondaryText: string;
  accent: string;
  accentSurface: string;
  error: string;
}

export type SystemThemeListener = (theme: EffectiveTheme) => void;

/** Replaceable boundary between theme orchestration and HarmonyOS configuration APIs. */
export interface ThemePlatform {
  getSystemTheme(): EffectiveTheme;
  applyThemeMode(mode: ThemeMode): void;
  start(listener: SystemThemeListener): void;
  stop(): void;
}

const LIGHT_PALETTE: ThemePalette = {
  pageBackground: '#ECEEF2',
  surfaceBackground: '#F8F9FB',
  focusSurface: '#66FFFFFF',
  focusBorder: '#E6FFFFFF',
  focusGlow: '#99FFFFFF',
  secondaryActionSurface: '#66D7ECFF',
  secondaryActionBorder: '#B3EAF6FF',
  secondaryActionGlow: '#6658AFFF',
  secondaryActionText: '#075985',
  navigationBackground: '#ECEEF2',
  primaryText: '#171A1F',
  secondaryText: '#5D6673',
  accent: '#0A59F7',
  accentSurface: '#240A59F7',
  error: '#B3261E'
};

const DARK_PALETTE: ThemePalette = {
  pageBackground: '#101216',
  surfaceBackground: '#1A1D23',
  focusSurface: '#805179C8',
  focusBorder: '#F0B9DDFF',
  focusGlow: '#B35D8FFF',
  secondaryActionSurface: '#805179C8',
  secondaryActionBorder: '#F0B9DDFF',
  secondaryActionGlow: '#B35D8FFF',
  secondaryActionText: '#F3F5F8',
  navigationBackground: '#101216',
  primaryText: '#F3F5F8',
  secondaryText: '#B5BDC9',
  accent: '#7EACFF',
  accentSurface: '#337EACFF',
  error: '#FFB4AB'
};

function copyPalette(palette: ThemePalette): ThemePalette {
  return {
    pageBackground: palette.pageBackground,
    surfaceBackground: palette.surfaceBackground,
    focusSurface: palette.focusSurface,
    focusBorder: palette.focusBorder,
    focusGlow: palette.focusGlow,
    secondaryActionSurface: palette.secondaryActionSurface,
    secondaryActionBorder: palette.secondaryActionBorder,
    secondaryActionGlow: palette.secondaryActionGlow,
    secondaryActionText: palette.secondaryActionText,
    navigationBackground: palette.navigationBackground,
    primaryText: palette.primaryText,
    secondaryText: palette.secondaryText,
    accent: palette.accent,
    accentSurface: palette.accentSurface,
    error: palette.error
  };
}

/** Pure SYSTEM/LIGHT/DARK resolver used by production code and Local Test. */
export function resolveEffectiveTheme(
  selectedTheme: ThemeMode,
  systemTheme: EffectiveTheme
): EffectiveTheme {
  if (selectedTheme === ThemeMode.LIGHT) {
    return EffectiveTheme.LIGHT;
  }
  if (selectedTheme === ThemeMode.DARK) {
    return EffectiveTheme.DARK;
  }
  return systemTheme;
}

function applyAccent(palette: ThemePalette, theme: EffectiveTheme, accentTheme: AccentTheme): void {
  if (accentTheme === AccentTheme.CYAN) {
    palette.accent = theme === EffectiveTheme.DARK ? '#67E8F9' : '#007D8A';
    palette.accentSurface = theme === EffectiveTheme.DARK ? '#3367E8F9' : '#24007D8A';
    palette.focusGlow = theme === EffectiveTheme.DARK ? '#9967E8F9' : '#667DEAF2';
  } else if (accentTheme === AccentTheme.PURPLE) {
    palette.accent = theme === EffectiveTheme.DARK ? '#C4B5FD' : '#7656D6';
    palette.accentSurface = theme === EffectiveTheme.DARK ? '#33C4B5FD' : '#247656D6';
    palette.focusGlow = theme === EffectiveTheme.DARK ? '#99A78BFA' : '#668B6EE8';
  } else if (accentTheme === AccentTheme.GREEN) {
    palette.accent = theme === EffectiveTheme.DARK ? '#6EE7B7' : '#087F5B';
    palette.accentSurface = theme === EffectiveTheme.DARK ? '#336EE7B7' : '#24087F5B';
    palette.focusGlow = theme === EffectiveTheme.DARK ? '#996EE7B7' : '#6652C79A';
  }
}

export interface ChoiceVisualState {
  background: string;
  foreground: string;
  borderColor: string;
  borderWidth: number;
}

/** Returns an isolated semantic palette for the resolved theme and selected accent preset. */
export function getThemePalette(
  theme: EffectiveTheme,
  accentTheme: AccentTheme = AccentTheme.BLUE
): ThemePalette {
  const palette = copyPalette(theme === EffectiveTheme.DARK ? DARK_PALETTE : LIGHT_PALETTE);
  applyAccent(palette, theme, accentTheme);
  return palette;
}

/** Pure selected-state mapping used by settings choice controls. */
export function resolveChoiceVisualState(palette: ThemePalette, selected: boolean): ChoiceVisualState {
  if (selected) {
    return {
      background: palette.accent,
      foreground: '#FFFFFFFF',
      borderColor: palette.accent,
      borderWidth: 1
    };
  }
  return {
    background: palette.surfaceBackground,
    foreground: palette.primaryText,
    borderColor: '#00000000',
    borderWidth: 0
  };
}

/** Stable text used only by the T12 verification surface and device tests. */
export function themeStatusText(selected: ThemeMode, effective: EffectiveTheme): string {
  return `当前主题：${selected}/${effective}`;
}
