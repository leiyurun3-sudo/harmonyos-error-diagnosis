# Floating Glass Dock Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复悬浮 Dock 横向错位、材质过度模糊，以及设置选项状态变化后未重绘的问题。

**Architecture:** 将 Dock 尺寸与透明度收敛到可测试的纯模型；页面通过父容器 padding 约束 Dock 宽度。`AppStateStore` 继续作为唯一设置状态源，但需要变化刷新的子组件改用 `@ObjectLink` 接收 `@Observed` 实例。

**Tech Stack:** HarmonyOS API 26、ArkTS、ArkUI V1 状态管理、`uiMaterial.ImmersiveMaterial`、Hypium。

## Global Constraints

- Dock 必须保持悬浮，不改成贴底全宽导航栏。
- 使用 API 26 已确认存在的 `ImmersiveStyle.ULTRA_THIN`。
- 选中项必须同时通过主题色背景、文字和图标表达。
- 不修改诊断业务、报告业务和现有路由契约。
- 不提交 Git。

---

### Task 1: Dock 视觉参数纯模型

**Files:**
- Modify: `entry/src/main/ets/model/FloatingDockModels.ets`
- Test: `entry/src/test/unit/FloatingDockModels.test.ets`

**Interfaces:**
- Produces: `getFloatingDockVisualSpec(): FloatingDockVisualSpec`

- [ ] 先增加失败测试，断言左右 padding 为 18vp、容器高度 64vp、浅色覆盖层透明度低于旧值。
- [ ] 运行 Hvigor `test`，确认测试因接口不存在而失败。
- [ ] 实现不可变视觉参数返回值，并让测试通过。

### Task 2: 状态观察与选中样式

**Files:**
- Modify: `entry/src/main/ets/components/navigation/FloatingGlassDock.ets`
- Modify: `entry/src/main/ets/pages/settings/SettingsRootView.ets`
- Modify: `entry/src/main/ets/pages/home/HomePage.ets`

**Interfaces:**
- Consumes: `@Observed AppStateStore`
- Produces: `@ObjectLink appState: AppStateStore`

- [ ] 将 Dock 和设置页的状态输入改为 `@ObjectLink`，由 HomePage 显式传入同一实例。
- [ ] 选中按钮使用主题色半透明填充、主题色描边和高对比文字；未选中项使用普通表面色。
- [ ] 用带左右 padding 的父 Row 包裹 Dock，移除 `100% + margin` 的溢出组合。

### Task 3: Liquid Glass 材质收敛与验证

**Files:**
- Modify: `entry/src/main/ets/components/navigation/FloatingGlassDock.ets`

- [ ] 使用 `ULTRA_THIN`，降低 materialColor、背景覆盖层、边框和阴影强度。
- [ ] 运行完整本地测试。
- [ ] 构建 Debug HAP，检查 ArkTS 正式页面编译。
- [ ] 若当前签名环境可用，在模拟器检查居中、透明度和设置选中态；否则明确记录为待 DevEco 运行验证。
