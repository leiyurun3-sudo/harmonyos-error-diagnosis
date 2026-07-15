import { describe, expect, it } from '@ohos/hypium';
import {
  canDispatchGlassAction,
  createGlassActionVisualState
} from '../../main/ets/components/common/GlassActionButtonModels';
import { AccentTheme, VisualEffectMode } from '../../main/ets/model/SettingsModels';
import { EffectiveTheme, getThemePalette } from '../../main/ets/theme/ThemeModels';

export default function glassActionButtonModelsTest() {
  describe('GlassActionButtonModels', () => {
    it('uses the home focus tokens in light and dark themes', 0, () => {
      const lightPalette = getThemePalette(EffectiveTheme.LIGHT, AccentTheme.BLUE);
      const darkPalette = getThemePalette(EffectiveTheme.DARK, AccentTheme.PURPLE);
      const light = createGlassActionVisualState(
        lightPalette, EffectiveTheme.LIGHT, VisualEffectMode.FULL, true, false
      );
      const dark = createGlassActionVisualState(
        darkPalette, EffectiveTheme.DARK, VisualEffectMode.FULL, true, false
      );

      expect(light.backgroundColor).assertEqual(lightPalette.focusSurface);
      expect(light.foregroundColor).assertEqual(lightPalette.primaryText);
      expect(light.borderColor).assertEqual(lightPalette.focusBorder);
      expect(light.useLightMaterial).assertTrue();
      expect(light.useDarkBlur).assertFalse();
      expect(dark.backgroundColor).assertEqual(darkPalette.focusSurface);
      expect(dark.shadowColor).assertEqual(darkPalette.focusGlow);
      expect(dark.useLightMaterial).assertFalse();
      expect(dark.useDarkBlur).assertTrue();
    });

    it('reduces and disables visual effects deterministically', 0, () => {
      const palette = getThemePalette(EffectiveTheme.DARK, AccentTheme.BLUE);
      const full = createGlassActionVisualState(
        palette, EffectiveTheme.DARK, VisualEffectMode.FULL, true, false
      );
      const reduced = createGlassActionVisualState(
        palette, EffectiveTheme.DARK, VisualEffectMode.REDUCED, true, false
      );
      const off = createGlassActionVisualState(
        palette, EffectiveTheme.DARK, VisualEffectMode.OFF, true, true
      );

      expect(full.shadowRadius).assertEqual(24);
      expect(reduced.shadowRadius).assertEqual(10);
      expect(off.shadowRadius).assertEqual(0);
      expect(off.useDarkBlur).assertFalse();
      expect(off.scale).assertEqual(1);
    });

    it('keeps disabled text readable and removes glow', 0, () => {
      const palette = getThemePalette(EffectiveTheme.LIGHT, AccentTheme.GREEN);
      const disabled = createGlassActionVisualState(
        palette, EffectiveTheme.LIGHT, VisualEffectMode.FULL, false, false
      );

      expect(disabled.foregroundColor).assertEqual(palette.primaryText);
      expect(disabled.opacity).assertEqual(0.72);
      expect(disabled.shadowRadius).assertEqual(0);
      expect(disabled.useLightMaterial).assertFalse();
    });

    it('scales only an enabled pressed button when effects are active', 0, () => {
      const palette = getThemePalette(EffectiveTheme.LIGHT, AccentTheme.BLUE);
      expect(createGlassActionVisualState(
        palette, EffectiveTheme.LIGHT, VisualEffectMode.FULL, true, true
      ).scale).assertEqual(0.98);
      expect(createGlassActionVisualState(
        palette, EffectiveTheme.LIGHT, VisualEffectMode.FULL, false, true
      ).scale).assertEqual(1);
    });

    it('dispatches only while enabled and not loading', 0, () => {
      expect(canDispatchGlassAction(true, false)).assertTrue();
      expect(canDispatchGlassAction(false, false)).assertFalse();
      expect(canDispatchGlassAction(true, true)).assertFalse();
    });
  });
}
