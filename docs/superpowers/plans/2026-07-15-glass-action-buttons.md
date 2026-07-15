# Glass Action Buttons Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the unreadable default-blue primary actions on diagnosis and report pages with a reusable glowing glass button matching the home focus-entry visual language.

**Architecture:** Add a pure ArkTS presentation model that maps theme/effect/interaction inputs to deterministic visual values, then render those values in a small shared ArkUI component. `DiagnosisPage` and `ReportPage` provide labels, state, IDs, and callbacks; the component never imports a ViewModel, Repository, router, or business model.

**Tech Stack:** HarmonyOS API 26, ArkTS, ArkUI Stage model, `uiMaterial.ImmersiveMaterial`, Hypium Local Test, Hvigor, ArkTS Code Linter.

## Global Constraints

- Preserve all diagnosis, report saving, editing, retry, and navigation behavior.
- Style only “开始诊断”, “保存报告”, and “编辑原文” as primary glass actions.
- Keep example, re-diagnose, expand/collapse, return, retry, and dismiss actions low emphasis.
- Reuse `focusSurface`, `focusBorder`, `focusGlow`, and `primaryText` semantic colors.
- Support `FULL`, `REDUCED`, and `OFF` visual-effect modes without making disabled text unreadable.
- Do not implement OCR, T19–T24, or any new business feature.
- Do not control a simulator; device visual acceptance remains manual.

---

## File Structure

- Create `entry/src/main/ets/components/common/GlassActionButtonModels.ets`: pure, Local-Testable visual-state and action-availability mapping.
- Create `entry/src/main/ets/components/common/GlassActionButton.ets`: ArkUI adapter that consumes `AppStateStore` and renders the model.
- Create `entry/src/test/unit/GlassActionButtonModels.test.ets`: light/dark, effect-mode, disabled, pressed, and dispatch tests.
- Modify `entry/src/test/List.test.ets`: register the new Local Test suite.
- Modify `entry/src/main/ets/pages/diagnosis/DiagnosisPage.ets`: replace only `diagnosis_start` and remove page-local glass implementation.
- Modify `entry/src/main/ets/pages/report/ReportPage.ets`: replace `report_save` and `report_edit_text`; retain report-card material and all other buttons.

### Task 1: Pure Glass Button Presentation Model

**Files:**
- Create: `entry/src/main/ets/components/common/GlassActionButtonModels.ets`
- Create: `entry/src/test/unit/GlassActionButtonModels.test.ets`
- Modify: `entry/src/test/List.test.ets`

**Interfaces:**
- Consumes: `ThemePalette`, `EffectiveTheme`, `VisualEffectMode`.
- Produces: `GlassActionVisualState`, `createGlassActionVisualState(...)`, and `canDispatchGlassAction(enabled, loading)`.

- [ ] **Step 1: Register a failing Local Test suite**

Add the import and invocation to `entry/src/test/List.test.ets`:

```ts
import glassActionButtonModelsTest from './unit/GlassActionButtonModels.test';

export default function testsuite() {
  // Keep all existing suites.
  glassActionButtonModelsTest();
}
```

Create `entry/src/test/unit/GlassActionButtonModels.test.ets`:

```ts
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
```

- [ ] **Step 2: Run Local Test and verify RED**

Run:

```powershell
$env:DEVECO_SDK_HOME='D:\Dev\IDE\DevEco Studio\sdk'
& 'D:\Dev\IDE\DevEco Studio\tools\hvigor\bin\hvigorw.bat' `
  --mode module -p module=entry@default -p product=default `
  test --no-daemon --stacktrace
```

Expected: non-zero exit because `GlassActionButtonModels.ets` does not exist.

- [ ] **Step 3: Implement the minimal pure model**

Create `entry/src/main/ets/components/common/GlassActionButtonModels.ets`:

```ts
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
  const effectsEnabled = effectMode !== VisualEffectMode.OFF && enabled;
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
```

- [ ] **Step 4: Run Local Test and verify GREEN**

Run the Task 1 command again.

Expected: exit code 0 and `GlassActionButtonModels` tests pass with the full Local Test suite.

- [ ] **Step 5: Commit the pure model**

```powershell
git add entry/src/main/ets/components/common/GlassActionButtonModels.ets `
  entry/src/test/unit/GlassActionButtonModels.test.ets entry/src/test/List.test.ets
git commit -m "test: define glass action button states"
```

### Task 2: Shared ArkUI Glass Action Component and Diagnosis Integration

**Files:**
- Create: `entry/src/main/ets/components/common/GlassActionButton.ets`
- Modify: `entry/src/main/ets/pages/diagnosis/DiagnosisPage.ets`

**Interfaces:**
- Consumes: `createGlassActionVisualState(...)`, `canDispatchGlassAction(...)`, `AppStateStore`.
- Produces: `GlassActionButton` with `label`, `buttonId`, `enabled`, `loading`, and `onAction` inputs.

- [ ] **Step 1: Create the thin ArkUI adapter**

Create `entry/src/main/ets/components/common/GlassActionButton.ets`:

```ts
import { uiMaterial } from '@kit.ArkUI';
import { AppStateStore } from '../../store/AppStateStore';
import { getThemePalette, ThemePalette } from '../../theme/ThemeModels';
import {
  canDispatchGlassAction,
  createGlassActionVisualState,
  GlassActionVisualState
} from './GlassActionButtonModels';

@Component
export struct GlassActionButton {
  private readonly lightFocusMaterial: uiMaterial.ImmersiveMaterial = new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.THIN,
    materialColor: '#33FFFFFF',
    colorInvert: false,
    applyShadow: true,
    interactive: true,
    lightEffect: { color: Color.White }
  });
  @Consume('appState')
  appState: AppStateStore;
  @Prop
  label: ResourceStr = '';
  @Prop
  buttonId: string = '';
  @Prop
  enabled: boolean = true;
  @Prop
  loading: boolean = false;
  @State
  private pressed: boolean = false;
  onAction: () => void = (): void => {};

  private palette(): ThemePalette {
    return getThemePalette(this.appState.effectiveTheme, this.appState.accentTheme);
  }

  private visualState(): GlassActionVisualState {
    return createGlassActionVisualState(
      this.palette(),
      this.appState.effectiveTheme,
      this.appState.visualEffectMode,
      canDispatchGlassAction(this.enabled, this.loading),
      this.pressed
    );
  }

  build() {
    Button(this.label)
      .id(this.buttonId)
      .width('100%')
      .constraintSize({ minHeight: 52 })
      .fontSize(16 * this.appState.contentFontMultiplier)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.visualState().foregroundColor)
      .backgroundColor(this.visualState().backgroundColor)
      .backgroundBlurStyle(this.visualState().useDarkBlur ? BlurStyle.Thin : BlurStyle.NONE)
      .systemMaterial(this.visualState().useLightMaterial ? this.lightFocusMaterial : undefined)
      .border({ width: this.visualState().borderWidth, color: this.visualState().borderColor })
      .borderRadius(14)
      .opacity(this.visualState().opacity)
      .shadow({
        radius: this.visualState().shadowRadius,
        color: this.visualState().shadowColor,
        offsetX: 0,
        offsetY: this.visualState().shadowOffsetY
      })
      .scale({ x: this.visualState().scale, y: this.visualState().scale })
      .animation({
        duration: this.visualState().animationEnabled ? (this.pressed ? 100 : 180) : 0,
        curve: this.pressed ? Curve.EaseOut : Curve.Friction
      })
      .enabled(canDispatchGlassAction(this.enabled, this.loading))
      .onTouch((event: TouchEvent): void => {
        if (!canDispatchGlassAction(this.enabled, this.loading)) {
          this.pressed = false;
        } else if (event.type === TouchType.Down) {
          this.pressed = true;
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.pressed = false;
        }
      })
      .onClick((): void => {
        if (canDispatchGlassAction(this.enabled, this.loading)) {
          this.onAction();
        }
      })
  }
}
```

- [ ] **Step 2: Replace only the diagnosis primary action**

In `DiagnosisPage.ets`:

- Import `GlassActionButton`.
- Remove the page-local `uiMaterial` import, `lightFocusMaterial`, `startButtonScale`, and imports used only by the deleted styling.
- Replace the existing `diagnosis_start` Button block with:

```ts
GlassActionButton({
  label: $r('app.string.diagnosis_start'),
  buttonId: 'diagnosis_start',
  enabled: this.viewModel.diagnosisOperation.status !== OperationStatus.LOADING,
  loading: this.viewModel.diagnosisOperation.status === OperationStatus.LOADING,
  onAction: (): void => { this.diagnose(); }
})
```

Do not alter the example or return buttons.

- [ ] **Step 3: Compile the application integration**

Run:

```powershell
$env:DEVECO_SDK_HOME='D:\Dev\IDE\DevEco Studio\sdk'
& 'D:\Dev\IDE\DevEco Studio\tools\hvigor\bin\hvigorw.bat' `
  --mode module -p module=entry@default -p product=default `
  -p buildMode=debug assembleHap --no-daemon --stacktrace
```

Expected: exit code 0; `DiagnosisPage.ets` and `GlassActionButton.ets` compile under API 26.

- [ ] **Step 4: Run full Local Test**

Run the Task 1 test command.

Expected: exit code 0.

- [ ] **Step 5: Commit diagnosis integration**

```powershell
git add entry/src/main/ets/components/common/GlassActionButton.ets `
  entry/src/main/ets/pages/diagnosis/DiagnosisPage.ets
git commit -m "feat: add shared glass action button"
```

### Task 3: Report Integration and Final Verification

**Files:**
- Modify: `entry/src/main/ets/pages/report/ReportPage.ets`

**Interfaces:**
- Consumes: `GlassActionButton` from Task 2.
- Produces: glass `report_save` and `report_edit_text` actions with unchanged ViewModel callbacks and state rules.

- [ ] **Step 1: Replace the report save action**

Import `GlassActionButton`, then replace the existing save Button with:

```ts
GlassActionButton({
  label: this.viewModel?.saveOperation.status === OperationStatus.LOADING ?
    $r('app.string.report_saving') : (this.viewModel?.isSaved ?
    $r('app.string.report_saved') : $r('app.string.report_save')),
  buttonId: 'report_save',
  enabled: this.viewModel?.saveOperation.status !== OperationStatus.LOADING &&
    !this.viewModel?.isSaved,
  loading: this.viewModel?.saveOperation.status === OperationStatus.LOADING,
  onAction: (): void => { this.saveReport(); }
})
```

Keep the existing save error notice directly below it.

- [ ] **Step 2: Replace the editable-session action**

Inside the existing `hasEditableSession` conditional, replace only `report_edit_text` with:

```ts
GlassActionButton({
  label: $r('app.string.report_edit_text'),
  buttonId: 'report_edit_text',
  onAction: (): void => { this.editInput(); }
})
```

Keep “重新诊断” and “返回来源页” unchanged.

- [ ] **Step 3: Run the complete verification matrix**

Run the full Local Test command from Task 1, then:

```powershell
$project = (Get-Location).Path
$node = 'D:\Dev\IDE\DevEco Studio\tools\node\node.exe'
$linter = 'D:\Dev\IDE\DevEco Studio\plugins\codelinter\index.js'
$checkPaths = '[\"' + ($project -replace '\\', '/') + '/entry/src/main/ets\"]'
& $node $linter --project $project --dir $checkPaths `
  --config "$project\code-linter.json5" `
  --sdkPath 'D:\Dev\IDE\DevEco Studio\sdk' `
  --sdkNumberVersion '26.0.0' --sdkStringVersion '26.0.0' `
  --workdir 'D:\Dev\IDE\DevEco Studio\plugins\codelinter' `
  --logPath "$project\entry\build\code-linter.log" `
  --inIde false --incremental false --fix false --fixSelected false -l cn

$env:DEVECO_SDK_HOME='D:\Dev\IDE\DevEco Studio\sdk'
& 'D:\Dev\IDE\DevEco Studio\tools\hvigor\bin\hvigorw.bat' `
  --mode module -p module=entry@default -p product=default `
  -p buildMode=debug assembleHap --no-daemon --stacktrace
& 'D:\Dev\IDE\DevEco Studio\tools\hvigor\bin\hvigorw.bat' `
  --mode module -p module=entry@ohosTest -p product=default `
  -p buildMode=debug assembleHap --no-daemon --stacktrace
git diff --check
```

Expected: all commands exit 0; Linter reports zero defects. Existing unsigned-HAP and pre-existing warning messages may remain documented but must not be represented as device execution success.

- [ ] **Step 4: Review the final diff against scope**

Run:

```powershell
git diff -- entry/src/main/ets/components/common `
  entry/src/main/ets/pages/diagnosis/DiagnosisPage.ets `
  entry/src/main/ets/pages/report/ReportPage.ets `
  entry/src/test/List.test.ets entry/src/test/unit/GlassActionButtonModels.test.ets
```

Confirm the diff does not modify ViewModels, Repositories, routes, OCR, diagnosis rules, report state transitions, or secondary button styling.

- [ ] **Step 5: Commit report integration**

```powershell
git add entry/src/main/ets/pages/report/ReportPage.ets
git commit -m "style: unify diagnosis and report glass actions"
```

After the commit, leave push, merge, and device acceptance to the user unless explicitly requested.
