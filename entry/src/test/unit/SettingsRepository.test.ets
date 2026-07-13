import { describe, expect, it } from '@ohos/hypium';
import {
  SETTINGS_SCHEMA_VERSION,
  StorageKey
} from '../../main/ets/constants/StorageKeys';
import { ErrorCode } from '../../main/ets/constants/ErrorCodes';
import {
  ThemeMode,
  UserSettings
} from '../../main/ets/model/SettingsModels';
import { LocalSettingsRepository } from '../../main/ets/repository/settings/SettingsRepository';
import { HiLogService } from '../../main/ets/service/platform/HiLogService';
import { CapturingLogSink } from '../fakes/CapturingLogSink';
import {
  InMemoryPreferencesState,
  InMemoryPreferencesStore
} from '../fakes/InMemoryPreferencesStore';

function createRepository(
  store: InMemoryPreferencesStore,
  sink: CapturingLogSink = new CapturingLogSink()
): LocalSettingsRepository {
  return new LocalSettingsRepository(store, new HiLogService(sink));
}

function createChangedSettings(): UserSettings {
  return {
    themeMode: ThemeMode.DARK,
    historyLimit: 200,
    firstLaunchCompleted: true,
    draftRecoveryEnabled: true
  };
}

export default function settingsRepositoryTest() {
  describe('SettingsRepository', () => {
    it('returns independent documented defaults on first read', 0, async (): Promise<void> => {
      const state = new InMemoryPreferencesState();
      const repository = createRepository(new InMemoryPreferencesStore(state));
      const first = await repository.get();
      if (first.data !== undefined) {
        first.data.themeMode = ThemeMode.DARK;
      }
      const second = await repository.get();

      expect(first.success).assertTrue();
      expect(second.data?.themeMode).assertEqual(ThemeMode.SYSTEM);
      expect(second.data?.historyLimit).assertEqual(200);
      expect(second.data?.firstLaunchCompleted).assertFalse();
      expect(second.data?.draftRecoveryEnabled).assertFalse();
    });

    it('persists all settings and schema version across repository instances', 0, async (): Promise<void> => {
      const state = new InMemoryPreferencesState();
      const firstStore = new InMemoryPreferencesStore(state);
      const updateResult = await createRepository(firstStore).update(createChangedSettings());
      const secondStore = new InMemoryPreferencesStore(state);
      const restored = await createRepository(secondStore).get();

      expect(updateResult.success).assertTrue();
      expect(restored.data?.themeMode).assertEqual(ThemeMode.DARK);
      expect(restored.data?.historyLimit).assertEqual(200);
      expect(restored.data?.firstLaunchCompleted).assertTrue();
      expect(restored.data?.draftRecoveryEnabled).assertTrue();
      expect(secondStore.valueOf(StorageKey.SCHEMA_VERSION)).assertEqual(SETTINGS_SCHEMA_VERSION);
    });

    it('resets persisted settings to isolated defaults', 0, async (): Promise<void> => {
      const state = new InMemoryPreferencesState();
      const repository = createRepository(new InMemoryPreferencesStore(state));
      await repository.update(createChangedSettings());
      const reset = await repository.reset();
      if (reset.data !== undefined) {
        reset.data.firstLaunchCompleted = true;
      }
      const restored = await createRepository(new InMemoryPreferencesStore(state)).get();

      expect(reset.success).assertTrue();
      expect(restored.data?.themeMode).assertEqual(ThemeMode.SYSTEM);
      expect(restored.data?.historyLimit).assertEqual(200);
      expect(restored.data?.firstLaunchCompleted).assertFalse();
      expect(restored.data?.draftRecoveryEnabled).assertFalse();
    });

    it('falls back for invalid persisted theme and fixed history limit', 0, async (): Promise<void> => {
      const state = new InMemoryPreferencesState();
      const store = new InMemoryPreferencesStore(state);
      store.seed(StorageKey.THEME_MODE, 'NEON');
      store.seed(StorageKey.HISTORY_LIMIT, 999);

      const result = await createRepository(store).get();

      expect(result.success).assertTrue();
      expect(result.data?.themeMode).assertEqual(ThemeMode.SYSTEM);
      expect(result.data?.historyLimit).assertEqual(200);
    });

    it('maps read failures without leaking platform details', 0, async (): Promise<void> => {
      const sink = new CapturingLogSink();
      const repository = createRepository(
        new InMemoryPreferencesStore(new InMemoryPreferencesState(), true, false),
        sink
      );

      const result = await repository.get();
      const serializedLog = JSON.stringify(sink.records);

      expect(result.success).assertFalse();
      expect(result.data === undefined).assertTrue();
      expect(result.error?.code).assertEqual(ErrorCode.SETTINGS_READ_FAILED);
      expect(serializedLog.includes('Synthetic preferences read failure')).assertFalse();
      expect(serializedLog.includes('NEON')).assertFalse();
    });

    it('maps update and reset failures to the write error code', 0, async (): Promise<void> => {
      const sink = new CapturingLogSink();
      const repository = createRepository(
        new InMemoryPreferencesStore(new InMemoryPreferencesState(), false, true),
        sink
      );

      const update = await repository.update(createChangedSettings());
      const reset = await repository.reset();

      expect(update.success).assertFalse();
      expect(update.error?.code).assertEqual(ErrorCode.SETTINGS_WRITE_FAILED);
      expect(reset.success).assertFalse();
      expect(reset.error?.code).assertEqual(ErrorCode.SETTINGS_WRITE_FAILED);
      expect(JSON.stringify(sink.records).includes('Synthetic preferences write failure')).assertFalse();
      expect(JSON.stringify(sink.records).includes(ThemeMode.DARK)).assertFalse();
    });

    it('copies update input before returning it to the caller', 0, async (): Promise<void> => {
      const state = new InMemoryPreferencesState();
      const input = createChangedSettings();
      const repository = createRepository(new InMemoryPreferencesStore(state));
      const result = await repository.update(input);
      input.themeMode = ThemeMode.LIGHT;
      if (result.data !== undefined) {
        result.data.draftRecoveryEnabled = false;
      }

      const restored = await repository.get();

      expect(restored.data?.themeMode).assertEqual(ThemeMode.DARK);
      expect(restored.data?.draftRecoveryEnabled).assertTrue();
    });
  });
}
