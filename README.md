# 开发报错诊断助手

HarmonyOS API 26、ArkTS Stage模型的本地开发报错诊断应用。

本版在原有本地诊断、报告和历史记录基础上，完成了沉浸光感、可变字体、AI 对话、Agent、Skill、视觉 AI、互动卡片、应用子窗与零依赖演示后端。首页底部导航已改为等宽对齐，避免选中项放大后挤压内容。

## 已实现功能

- 本地规则诊断：输入校验、错误分类、原因分析、处理步骤、报告保存与历史查询。
- 截图诊断：系统安全图片选择器 + Core Vision Kit OCR，识别结果可直接进入诊断流程。
- AI 对话：内置零费用 `DevAssist Mini` 端侧规则/意图模型，断网也能演示；可切换 HTTP API。
- Agent：本地 Planner、Skill Router、Verifier 流程；支持填写平台注册 Agent ID 检测系统 Agent 能力。
- Skill：JSON Formatter、Error Triage、Report Writer、Privacy Redactor。
- 视觉 AI：端侧文字识别，图片不默认上传。
- 智慧多窗：创建应用子窗并展示“闪控窗”式诊断进度；不支持子窗的设备会返回明确降级提示。
- 互动卡片：点击或摇一摇切换诊断卡片状态；模拟器无传感器时可点击演示。
- 沉浸光感：核心卡片和操作使用 API 26 `uiMaterial.ImmersiveMaterial`，启用触控跟随光感。
- 可变字体：标题和关键状态使用 `fontVariations`，信息层级随字重变化。
- 主题与隐私：浅色、深色、跟随系统，以及完整隐私说明和本地优先策略。

## 系统能力边界

华为官方的系统级 Skill 入口、系统 Agent、小艺入口、系统实况窗/互动卡片通常需要开发者实名认证、平台登记、服务配置或设备支持。本仓库提供真实 SDK 适配入口和可运行的应用内演示，不伪造平台注册结果；没有资质或模拟器不支持时，会自动使用本地 Agent、Skill、点击互动卡片和应用子窗。

## 演示后端

`backend/` 是零第三方依赖的 Node.js 服务：

```powershell
cd backend
npm test
npm start
```

默认端口 `8787`，提供 `/health`、`/api/models`、`/api/chat`、`/api/agent/run` 和 `/api/vision/analyze`。先执行 `backend/start-emulator-api.ps1` 建立 HDC 端口转发，应用使用 `http://127.0.0.1:8787`；API 不可达会自动降级到免费端侧模型。详细操作见 `docs/项目使用与开发手册.md`。

## 开发环境

- DevEco Studio 26.0.0.461
- HarmonyOS SDK 26.0.0.23 / API 26
- OHPM 26.0.0.410
- Hvigor 6.26.1

PowerShell执行 Hvigor前设置：

```powershell
$env:DEVECO_SDK_HOME='D:\downloading\DevEco Studio\sdk'
```

## 验证命令

依赖安装、Local Test和 Debug构建：

```powershell
& 'D:\Dev\IDE\DevEco Studio\tools\ohpm\bin\ohpm.bat' install

& 'D:\Dev\IDE\DevEco Studio\tools\hvigor\bin\hvigorw.bat' `
  --mode module -p module=entry@default -p product=default `
  test --no-daemon

& 'D:\Dev\IDE\DevEco Studio\tools\hvigor\bin\hvigorw.bat' `
  --mode module -p module=entry@default -p product=default `
  -p buildMode=debug -p requiredDeviceType=phone `
  assembleHap --no-daemon
```

ArkTS Linter（命令行参数中的 SDK根目录是 `sdk`，API数值版本需使用 `26.0.0`）：

```powershell
$project = (Get-Location).Path
$node = 'D:\Dev\IDE\DevEco Studio\tools\node\node.exe'
$linter = 'D:\Dev\IDE\DevEco Studio\plugins\codelinter\index.js'
$checkPaths = '[\"' + ($project -replace '\\', '/') + '/entry/src/main/ets\"]'

& $node $linter `
  --project $project `
  --dir $checkPaths `
  --config "$project\code-linter.json5" `
  --sdkPath 'D:\Dev\IDE\DevEco Studio\sdk' `
  --sdkNumberVersion '26.0.0' `
  --sdkStringVersion '26.0.0' `
  --workdir 'D:\Dev\IDE\DevEco Studio\plugins\codelinter' `
  --logPath "$project\entry\build\code-linter.log" `
  --inIde false --incremental false --fix false --fixSelected false -l cn
```

设备测试需要先安装由同一套本地 Debug签名签署的应用 HAP和 `ohosTest` HAP。签名产物只放在被 Git忽略的 `entry/build/`，不得使用或提交发布证书、私钥和口令。安装完成后执行：

```powershell
$hdc = 'D:\Dev\IDE\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe'
& $hdc list targets
& $hdc -t 127.0.0.1:5555 shell aa test `
  -b com.example.errordiagnosis -m entry_test `
  -s unittest OpenHarmonyTestRunner -s timeout 30000 -w 60
```

当前 `build-profile.json5` 不保存本机签名配置，因此直接执行 `onDeviceTest` 会在安装前因缺少 signed HAP退出非零；这不影响 Local Test、ohosTest源码编译或 Debug unsigned HAP构建。

## 测试边界

- Local Test只测试纯逻辑、Fixture和通过接口注入的替身。
- UI/Instrument Test用于真实 ArkUI、系统存储和设备流程。
- 测试不访问网络、OCR、真实账号、签名材料或设备隐私数据。
- 后续 Repository/Service必须先定义生产接口，测试 Fake放在测试源集并实现同一接口。
