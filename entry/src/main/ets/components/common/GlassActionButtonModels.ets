import { VisualEffectMode } from '../../model/SettingsModels';
import { EffectiveTheme, ThemePalette } from '../../theme/ThemeModels';

export interface GlassActionVisualState {
  backgroundColor: string;
  foregroundColor: string;
  borderColor: string;
  borderWidth: number;
  shadowRadius: number;
  shadowColor: string;
  shadowOffsetY: number;
  useLightMaterial: boolean;
  useDarkBlur: boolean;
  scale: number;
  opacity: number;
  animationEnabled: boolean;
}

export function canDispatchGlassAction(enabled: boolean, loading: boolean): boolean {
  return enabled && !loading;
}

export function createGlassActionVisualState(
  palette: ThemePalette,
  theme: EffectiveTheme,
  effectMode: VisualEffectMode,
  enabled: boolean,
  pressed: boolean
): GlassActionVisualState {
  const effectsEnabled: boolean = effectMode !== VisualEffectMode.OFF && enabled;
  let shadowRadius: number = 0;
  if (effectsEnabled) {
    shadowRadius = effectMode === VisualEffectMode.FULL ? 24 : 10;
  }
  return {
    backgroundColor: palette.focusSurface,
    foregroundColor: palette.primaryText,
    borderColor: palette.focusBorder,
    borderWidth: 2,
    shadowRadius: shadowRadius,
    shadowColor: effectsEnabled ? palette.focusGlow : '#00000000',
    shadowOffsetY: effectsEnabled ? 6 : 0,
    useLightMaterial: effectsEnabled && theme === EffectiveTheme.LIGHT,
    useDarkBlur: effectsEnabled && theme === EffectiveTheme.DARK,
    scale: effectsEnabled && pressed ? 0.98 : 1,
    opacity: enabled ? 1 : 0.72,
    animationEnabled: effectsEnabled
  };
}
