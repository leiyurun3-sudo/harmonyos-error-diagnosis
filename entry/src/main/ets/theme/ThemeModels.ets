import { ThemeMode } from '../model/SettingsModels';

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

/** Returns an isolated semantic palette for the resolved theme. */
export function getThemePalette(theme: EffectiveTheme): ThemePalette {
  return copyPalette(theme === EffectiveTheme.DARK ? DARK_PALETTE : LIGHT_PALETTE);
}

/** Stable text used only by the T12 verification surface and device tests. */
export function themeStatusText(selected: ThemeMode, effective: EffectiveTheme): string {
  return `当前主题：${selected}/${effective}`;
}
