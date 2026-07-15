/** Preferences file and V1 keys defined by detailed design section 8.2. */
export const SETTINGS_PREFERENCES_NAME: string = 'user_settings';
export const SETTINGS_SCHEMA_VERSION: number = 2;

export enum StorageKey {
  THEME_MODE = 'settings.theme_mode',
  FIRST_LAUNCH_COMPLETED = 'settings.first_launch_completed',
  HISTORY_LIMIT = 'settings.history_limit',
  DRAFT_RECOVERY_ENABLED = 'settings.draft_recovery_enabled',
  ACCENT_THEME = 'settings.accent_theme',
  CONTENT_FONT_SCALE = 'settings.content_font_scale',
  VISUAL_EFFECT_MODE = 'settings.visual_effect_mode',
  SCHEMA_VERSION = 'storage.schema_version'
}
