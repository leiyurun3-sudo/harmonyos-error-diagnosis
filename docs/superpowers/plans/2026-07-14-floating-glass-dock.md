# Floating Glass Dock Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a four-item floating luminous-glass Dock and a persisted settings surface for theme mode, accent color, content font size, and visual-effect level without changing diagnosis business behavior.

**Architecture:** Keep `HomePage` as the single `@Entry` and Navigation owner. Its root content becomes a top-level shell that switches HOME/TOOLS/RECORDS/SETTINGS locally while `NavPathStack` remains responsible for diagnosis, report, privacy, and legacy deep destinations. `AppStateStore` remains the single source for visual preferences; `SettingsViewModel` persists them through the existing repository and Preferences boundary.

**Tech Stack:** HarmonyOS API 26, ArkTS, ArkUI Navigation/Stack, `uiMaterial.ImmersiveMaterial`, Preferences, Hypium Local Test and ohosTest.

## Global Constraints

- The Dock must remain visually floating above the safe-area bottom; it must never degrade into a full-width attached bottom bar.
- Primary items are HOME, TOOLS, RECORDS, SETTINGS; diagnosis and report destinations hide the Dock naturally by covering the Navigation root.
- Full effect uses `uiMaterial.ImmersiveMaterial`; reduced/off modes preserve layout and navigation.
- No third-party UI or animation library and no infinite decorative animation.
- Preserve current T17 diagnosis/report behavior and existing AppRouter contracts.
- All settings are local and contain no sensitive data.

---

### Task 1: Persisted visual preference models

**Files:**
- Modify: `entry/src/main/ets/model/SettingsModels.ets`
- Modify: `entry/src/main/ets/constants/StorageKeys.ets`
- Modify: `entry/src/main/ets/repository/settings/SettingsRepository.ets`
- Modify: `entry/src/test/unit/SettingsModels.test.ets`
- Modify: `entry/src/test/unit/SettingsRepository.test.ets`
- Modify: `entry/src/test/fakes/FakeSettingsRepository.ets`

**Interfaces:**
- Produces: `AccentTheme`, `ContentFontScale`, `VisualEffectMode` and corresponding `UserSettings` fields.
- Defaults: blue accent, standard font, full visual effects.

- [ ] Add failing model tests asserting stable enum strings and defaults.
- [ ] Add failing repository tests for read/write, invalid-value normalization, V1-to-V2 defaults, rollback, and reset.
- [ ] Run the complete Local Test suite and confirm failures are caused by missing fields/keys.
- [ ] Add the three enums and fields, bump schema to V2, accept V1 data while supplying new defaults, and persist the new keys transactionally.
- [ ] Update fake copies and fixtures so all `UserSettings` copies remain isolated.
- [ ] Re-run Local Test until the full suite passes.

### Task 2: App state and settings actions

**Files:**
- Modify: `entry/src/main/ets/store/AppStateStore.ets`
- Modify: `entry/src/main/ets/viewmodel/settings/SettingsViewModel.ets`
- Modify: `entry/src/main/ets/service/platform/AppRuntime.ets`
- Modify: `entry/src/test/unit/AppStateStore.test.ets`
- Modify: `entry/src/test/unit/SettingsViewModel.test.ets`

**Interfaces:**
- Produces: observable `accentTheme`, `contentFontScale`, `visualEffectMode`.
- Produces: `updateVisualPreferences(accentTheme, contentFontScale, visualEffectMode)` and runtime wrapper.

- [ ] Add failing tests for load, immediate session application, successful persistence, save failure session-only behavior, and reset.
- [ ] Run Local Test and verify the new tests fail for missing actions/state.
- [ ] Extend every store copy/load/save path and add a generic settings update path that does not reapply platform color mode unnecessarily.
- [ ] Add the ViewModel/runtime visual-preference update method using the existing revision and lifecycle guards.
- [ ] Re-run Local Test until the full suite passes.

### Task 3: Theme tokens and Dock presentation model

**Files:**
- Modify: `entry/src/main/ets/theme/ThemeModels.ets`
- Create: `entry/src/main/ets/components/navigation/FloatingDockModels.ets`
- Create: `entry/src/main/ets/components/navigation/FloatingGlassDock.ets`
- Create: `entry/src/test/unit/FloatingDockModels.test.ets`
- Modify: `entry/src/test/List.test.ets`

**Interfaces:**
- Produces: `DockItem.HOME/TOOLS/RECORDS/SETTINGS`, stable labels, selection helper, and Dock callback.
- Consumes: `AppStateStore`, effective theme and visual-effect mode.

- [ ] Add failing pure tests for four stable items, selected state, and effect-mode presentation.
- [ ] Run Local Test and verify the model module is missing.
- [ ] Add accent-aware theme palettes plus Dock background, border, glow, selected-surface, and selected-text tokens.
- [ ] Implement a 64–72vp floating component with 16vp side inset, rounded outline, 44vp targets, low-intensity container glow, selected-item glow, and `systemMaterial` only when full effects are enabled.
- [ ] Use safe text/icon glyphs plus accessibility labels; defer unverified system Symbol resource names.
- [ ] Re-run Local Test and compile the component with the app.

### Task 4: Top-level shell and settings page

**Files:**
- Create: `entry/src/main/ets/pages/settings/SettingsRootView.ets`
- Create: `entry/src/main/ets/pages/history/RecordsRootView.ets`
- Create: `entry/src/main/ets/pages/tools/ToolsRootView.ets`
- Modify: `entry/src/main/ets/pages/home/HomePage.ets`
- Modify: `entry/src/main/resources/base/element/string.json`
- Modify: `entry/src/ohosTest/ets/test/pages/NavigationFlow.test.ets`
- Create: `entry/src/ohosTest/ets/test/pages/FloatingDockFlow.test.ets`
- Modify: `entry/src/ohosTest/ets/test/List.test.ets`

**Interfaces:**
- Home root owns `@State selectedDockItem` and passes `onSelect` to `FloatingGlassDock`.
- Settings root calls runtime visual-preference updates and existing theme switching.
- Privacy continues through `AppRouter.openPrivacy({ origin: HISTORY_SETTINGS })`.

- [ ] Add failing device-flow assertions for four Dock items, selected-page content, privacy navigation, and Dock absence on diagnosis/report.
- [ ] Preserve HomePage's existing `Navigation`, route destination builder and diagnosis/report flows; wrap only root content in a `Stack` with the Dock overlay.
- [ ] Add root views for tools, records and settings; keep legacy NavDestination pages for existing deep-route tests.
- [ ] Move theme verification controls out of Home content into Settings, add accent/font/effect controls, and retain session-only failure feedback.
- [ ] Give every root scroll view at least 104vp bottom padding so the Dock never covers its final action.
- [ ] Change only text diagnosis to the Home content strong focus; screenshot diagnosis remains an ordinary card.
- [ ] Run Local Test, Instrument/UI tests and verify navigation/back behavior.

### Task 5: Final integration verification

**Files:**
- Modify only defects found in files from Tasks 1–4.
- Update: `docs/视觉与动效设计说明书.md` only if implementation differs from verified device behavior.

- [ ] Run complete Local Test: `hvigorw.bat test --no-daemon`.
- [ ] Run ArkTS Linter on production `.ets` files using the project baseline command.
- [ ] Build Debug HAP with API 26 using `assembleHap`.
- [ ] Install and launch on the connected emulator; verify HOME/TOOLS/RECORDS/SETTINGS, diagnosis/report Dock hiding, LIGHT/DARK/SYSTEM, four accents, three font scales and three effect modes.
- [ ] Verify 1.5× system font, scrolling, last-item visibility, and 44vp touch targets.
- [ ] Verify static degradation keeps a floating rounded Dock and all four navigation actions.
- [ ] Run `git diff --check` and report modified files without committing.
