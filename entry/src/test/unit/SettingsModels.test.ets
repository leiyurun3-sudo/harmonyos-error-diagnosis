import { describe, expect, it } from '@ohos/hypium';
import {
  AccentTheme,
  ContentFontScale,
  createDefaultUserSettings,
  ThemeMode,
  VisualEffectMode
} from '../../main/ets/model/SettingsModels';

export default function settingsModelsTest() {
  describe('SettingsModels', () => {
    it('uses the documented theme mode wire values', 0, () => {
      expect(ThemeMode.SYSTEM).assertEqual('SYSTEM');
      expect(ThemeMode.LIGHT).assertEqual('LIGHT');
      expect(ThemeMode.DARK).assertEqual('DARK');
    });

    it('creates independent settings with documented defaults', 0, () => {
      const first = createDefaultUserSettings();
      const second = createDefaultUserSettings();

      first.themeMode = ThemeMode.DARK;

      expect(second.themeMode).assertEqual(ThemeMode.SYSTEM);
      expect(second.historyLimit).assertEqual(200);
      expect(second.firstLaunchCompleted).assertFalse();
      expect(second.draftRecoveryEnabled).assertFalse();
      expect(second.accentTheme).assertEqual(AccentTheme.BLUE);
      expect(second.contentFontScale).assertEqual(ContentFontScale.STANDARD);
      expect(second.visualEffectMode).assertEqual(VisualEffectMode.FULL);
    });
  });
}
