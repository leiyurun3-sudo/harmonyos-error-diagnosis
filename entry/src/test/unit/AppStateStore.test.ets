import { describe, expect, it } from '@ohos/hypium';
import { OperationStatus } from '../../main/ets/model/ResultModels';
import { ThemeMode } from '../../main/ets/model/SettingsModels';
import { AppStateStore } from '../../main/ets/store/AppStateStore';
import {
  EffectiveTheme,
  getThemePalette,
  resolveEffectiveTheme
} from '../../main/ets/theme/ThemeModels';

export default function appStateStoreTest() {
  describe('AppStateStore', () => {
    it('starts with SYSTEM and a safe effective theme', 0, () => {
      const store = new AppStateStore();

      expect(store.selectedThemeMode).assertEqual(ThemeMode.SYSTEM);
      expect(store.effectiveTheme).assertEqual(EffectiveTheme.LIGHT);
      expect(store.loadState.status).assertEqual(OperationStatus.IDLE);
      expect(store.saveState.status).assertEqual(OperationStatus.IDLE);
      expect(store.isThemeSessionOnly).assertFalse();
    });

    it('resolves SYSTEM from light and dark system modes', 0, () => {
      expect(resolveEffectiveTheme(ThemeMode.SYSTEM, EffectiveTheme.LIGHT))
        .assertEqual(EffectiveTheme.LIGHT);
      expect(resolveEffectiveTheme(ThemeMode.SYSTEM, EffectiveTheme.DARK))
        .assertEqual(EffectiveTheme.DARK);
    });

    it('keeps explicit LIGHT and DARK independent of system changes', 0, () => {
      expect(resolveEffectiveTheme(ThemeMode.LIGHT, EffectiveTheme.DARK))
        .assertEqual(EffectiveTheme.LIGHT);
      expect(resolveEffectiveTheme(ThemeMode.DARK, EffectiveTheme.LIGHT))
        .assertEqual(EffectiveTheme.DARK);
    });

    it('publishes isolated settings and operation snapshots', 0, () => {
      const store = new AppStateStore();
      const settings = store.settings;
      const loadState = store.loadState;
      settings.themeMode = ThemeMode.DARK;
      loadState.status = OperationStatus.ERROR;

      expect(store.settings.themeMode).assertEqual(ThemeMode.SYSTEM);
      expect(store.loadState.status).assertEqual(OperationStatus.IDLE);
    });

    it('returns centralized semantic palettes', 0, () => {
      const light = getThemePalette(EffectiveTheme.LIGHT);
      const dark = getThemePalette(EffectiveTheme.DARK);

      expect(light.pageBackground === dark.pageBackground).assertFalse();
      expect(light.primaryText === dark.primaryText).assertFalse();
      expect(light.navigationBackground === dark.navigationBackground).assertFalse();
      expect(light.focusGlow.length > 0).assertTrue();
      expect(dark.focusGlow.length > 0).assertTrue();
      expect(light.focusGlow === dark.focusGlow).assertFalse();
      expect(light.pageBackground).assertEqual('#ECEEF2');
      expect(light.navigationBackground).assertEqual('#ECEEF2');
      expect(light.surfaceBackground).assertEqual('#F8F9FB');
      expect(light.focusSurface).assertEqual('#66FFFFFF');
      expect(light.focusBorder).assertEqual('#E6FFFFFF');
      expect(light.focusGlow).assertEqual('#99FFFFFF');
      expect(light.secondaryActionSurface).assertEqual('#66D7ECFF');
      expect(light.secondaryActionBorder).assertEqual('#B3EAF6FF');
      expect(light.secondaryActionGlow).assertEqual('#6658AFFF');
      expect(light.secondaryActionText).assertEqual('#075985');
      expect(dark.pageBackground).assertEqual('#101216');
      expect(dark.focusSurface).assertEqual('#805179C8');
      expect(dark.focusBorder).assertEqual('#F0B9DDFF');
      expect(dark.focusGlow).assertEqual('#B35D8FFF');
    });
  });
}
