# T17 Light Immersive Material Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the light-theme blue neon simulation with official API 26 white immersive material while preserving the committed dark theme.

**Architecture:** Theme tokens define the static light-theme fallback and preserve exact dark-theme values. The three existing focal surfaces conditionally enable one shared light-theme `ImmersiveMaterial` configuration through ArkUI's universal `systemMaterial` property.

**Tech Stack:** HarmonyOS API 26, ArkTS, ArkUI `uiMaterial`, Hypium Local Test, Hvigor, ArkTS Linter.

## Global Constraints

- Preserve dark palette values from commit `cdc2c09` exactly.
- Modify only light-theme visuals and the three existing T17 focal surfaces.
- Do not change diagnosis behavior, routing, persistence, ordinary cards, or UiTest registration.
- Do not commit or push this revision without a new user request.

---

### Task 1: Light-theme semantic colors

**Files:**
- Modify: `entry/src/test/unit/AppStateStore.test.ets`
- Modify: `entry/src/main/ets/theme/ThemeModels.ets`

- [x] Add a failing test asserting light background `#ECEEF2`, light glass tokens `#66FFFFFF/#E6FFFFFF/#99FFFFFF`, and unchanged dark tokens.
- [x] Run full Local Test and confirm the assertions fail against the committed blue light palette.
- [x] Update only the light palette and leave all dark values unchanged.
- [x] Run full Local Test and confirm 291 tests pass.

### Task 2: Official immersive material on light focal surfaces

**Files:**
- Modify: `entry/src/main/ets/pages/home/HomePage.ets`
- Modify: `entry/src/main/ets/pages/diagnosis/DiagnosisPage.ets`
- Modify: `entry/src/main/ets/pages/report/ReportPage.ets`

- [x] Import `uiMaterial` from `@kit.ArkUI` and `EffectiveTheme` from the theme module.
- [x] Create one component field using `ImmersiveStyle.THIN`, white material color, interactive feedback, default white light effect, and system shadow.
- [x] Apply it through `systemMaterial(...)` only when the focal surface is active and the effective theme is LIGHT; pass `undefined` for dark theme and ordinary cards.
- [x] Preserve all existing IDs, callbacks, state bindings and press-scale animation.

### Task 3: Verification

**Files:**
- Verify only; no new UI tests.

- [x] Run full Local Test, ArkTS Linter, Debug HAP build, and ohosTest HAP build.
- [x] Run `git diff --check` and inspect the targeted diff for unchanged dark values and no business changes.
- [x] Report the API 26 simulator checks left to the user; do not commit or install the app.

### Task 4: Home action hierarchy and readability

**Files:**
- Modify: `entry/src/test/unit/AppStateStore.test.ets`
- Modify: `entry/src/main/ets/theme/ThemeModels.ets`
- Modify: `entry/src/main/ets/pages/home/HomePage.ets`
- Modify: `entry/src/main/ets/components/common/EmptyStateView.ets`

- [x] Add failing palette assertions for the light-blue action surface, border, glow, and dark-blue text.
- [x] Run Local Test and confirm compilation fails because the semantic tokens do not exist.
- [x] Add the semantic colors without changing existing light focus or dark theme values.
- [x] Give image and text diagnosis entries the same white immersive material treatment.
- [x] Apply light-blue immersive material to the remaining home actions and empty-state action; preserve dark behavior.
- [x] Run Local Test, ArkTS Linter, Debug HAP build, ohosTest HAP build, and `git diff --check`.
