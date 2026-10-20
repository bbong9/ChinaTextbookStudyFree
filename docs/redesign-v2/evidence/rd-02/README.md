# RD-02 验收证据

验证日期：2026-10-20。开发基线为 `redesign/v2` 的 `eaeff4f`；代码位于独立 worktree，避免与 RD-01 / RD-05 / RD-12 共享分支。

## 环境与边界

- Xcode 27.0（27A266a）、XcodeGen 2.46.0、iOS 18.6 模拟器，全部使用 `CODE_SIGNING_ALLOWED=NO`。
- 本卡没有修改屏幕方向配置。基线 iPhone 仍为竖屏；横屏截图仅通过构建参数覆盖 `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone`，待 RD-01 提供正式横屏外壳。
- 用户给定的未指定 OS 命令会选择 `OS:latest`，本机找不到对应 iPhone 16。因此使用以下专用设备 ID。原始命令保存在各测试日志开头。
- worktree 保留仓库自带 seed 数据；可选 `BundledMedia/audio`、`story-images` 为空目录。基线对照使用相同条件，不代表完整媒体包或真机验收。
- 截图来自 XCTest 附件。PNG 仅按方向元数据转正，未调色；对比图另做了裁剪与统一比例。
- 测试 `.txt` 保留完整命令与输出内容，仅清理行尾空格和末尾空行以通过 `git diff --check`；对应 `.raw.txt.gz` 保存清理前的逐字节原始输出。临时源日志未修改。

| 设备 | 专用设备 ID | 舞台截图 | 原始日志 |
| --- | --- | --- | --- |
| iPhone SE (3rd gen) | `2BFFBB16-A3BE-4564-AC5F-868D16C3D025` | [iphone-se-stage.png](iphone-se-stage.png) | [tests-iphone-se.txt](tests-iphone-se.txt) |
| iPhone 16 | `1AB108FF-245A-4626-BDF5-B6879E022162` | [iphone16-components.png](iphone16-components.png) | [tests-iphone16.txt](tests-iphone16.txt) |
| iPhone 16 Pro Max | `E6B19521-9912-4EFA-860C-CFAEB112530C` | [iphone16-pro-max-stage.png](iphone16-pro-max-stage.png) | [tests-iphone16-pro-max.txt](tests-iphone16-pro-max.txt) |
| iPad (A16) | `71B3285F-65A4-43CF-8CD9-D28129ECE554` | [ipad-a16-stage.png](ipad-a16-stage.png) | [tests-ipad-a16.txt](tests-ipad-a16.txt) |

## 验收对应

| 标准 | 证据 |
| --- | --- |
| AC1 组件视觉、内阴影、描边字 | [组件页](iphone16-components.png)、[图标与字体页](iphone16-icons-fonts.png)、[设计稿局部对比](design-comparison.png)。包含 `03-l0` 的按钮、步骤条、气泡，额外对照 `02-map` 描边字和 `09-result` 大按钮。 |
| AC2 步骤三态与回调 | `ClayGalleryUITests.testAnchorsStepStatesCallbackAndGalleryPages`：初始断言「已完成 / 当前 / 未到」，点击第 3 格后断言当前态和索引 `2`；[回调截图](iphone16-step-callback.png)。 |
| AC3 四尺寸舞台 | 上表四张截图；`StageLayoutTests` 的 3 项测试核对缩放、尺寸、四边安全区、五类锚点、贴底和侧向扩展。四设备 UI 测试另核对实际按钮边界与安全区，点击区域至少 44pt。 |
| AC4 楷体流程 | `ClayFontTests` 的 3 项流程测试覆盖首次请求、重复调用去重、成功后发布字体替换、失败静默回退及已安装检测。预览通过观察对象原地刷新。系统请求使用 `STKaitiSC-Regular`；[字体截图](iphone16-icons-fonts.png) 和日志 `RD02_FONT_STATUS=楷体已就绪` 证明模拟器中实际可用。 |
| AC5 打包字体 | `ClayFontTests.testBundledFontsAreRegisteredLicensedAndUnderEightMegabytes` 读取实际 App 的 `UIAppFonts`、字体文件、字体注册和两份 OFL。来源、提取命令、哈希及体积见 [FONT-SOURCES.md](../../../../apps/mobile/ChinaTextbookStudy/Resources/Fonts/FONT-SOURCES.md)。 |
| AC6 减少动态效果 | `ClayGalleryUITests.testReduceMotionStopsGoButton` 断言静止状态，并比较间隔 1.1 秒的解码像素。系统设置实测：[前](system-go-before.png)、[后](system-go-after.png)、[全屏](iphone16-system-reduce-motion.png)、[日志](tests-system-reduce-motion.txt) 中 `RD02_REDUCE_MOTION=system:true, initial:开启`；未点击局部开关。预览暂停分支也已验证，见 [全屏](iphone16-reduce-motion.png)。 |

全部渐变预览见 [iphone16-gradients.png](iphone16-gradients.png)。运行 `python3 docs/redesign-v2/evidence/rd-02/verify-gradients.py` 可逐项重验全部 **43** 个 SVG 渐变的色标、透明度、中心、半径和线性方向；[核对输出](gradient-audit.txt) 为 **0 项差异**。另外 7 个渐变逐项取自组件 CSS。

## 测试结果

- 最终本卡验收：**10 项单元测试 + 2 项 UI 测试，0 失败**，见 [tests-iphone16.txt](tests-iphone16.txt)。
- SE / Pro Max / iPad：各执行 **1 项 UI 测试，0 失败**；同一测试同时遍历三页预览。
- 系统减少动态效果专项：**1 项 UI 测试，0 失败**。仅在上述专用模拟器临时启用 `ReduceMotionEnabled`，使用 `UIAccessibility.isReduceMotionEnabled` 确认系统状态；测试后已恢复原值 `0`。这项验证同时覆盖最终新增的系统状态断言。
- Release 无签名构建成功，见 [build-release.txt](build-release.txt)；Debug 专用入口、路由和 Gallery 由条件编译移除。
- 完整标准配置构建成功；**214 项单元测试中 1 失败，15 项 UI 测试中 4 失败，总计 229 项 / 5 失败**，见 [tests-full.txt](tests-full.txt)。此全量运行后，最终图标、系统字体请求名和组件投影修正已用上述本卡测试及 Release 构建重新验证。
- `packages/core` 未改动，因此没有执行 `npm test`。

本卡验收重现命令（在仓库根目录执行；设备名也可替换成对应 UDID）：

```sh
cd apps/mobile
xcodegen generate
cd ../..
xcodebuild -project apps/mobile/ChinaTextbookStudy.xcodeproj \
  -scheme ChinaTextbookStudy \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -only-testing:ChinaTextbookStudyTests/StageLayoutTests \
  -only-testing:ChinaTextbookStudyTests/ClayFontTests \
  -only-testing:ChinaTextbookStudyTests/ClayGradientTests \
  -only-testing:ChinaTextbookStudyTests/ClayIconTests \
  -only-testing:ChinaTextbookStudyUITests/ClayGalleryUITests \
  CODE_SIGNING_ALLOWED=NO \
  'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone=UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight' \
  build test
```

## 基线失败与后续

以下 5 项均在不含 RD-02 改动的 `eaeff4f` 副本重现，原始输出见 [tests-baseline-failures.txt](tests-baseline-failures.txt)。基线运行在全部断言结果输出后，于诊断收集阶段停止，未产出完整 xcresult；不将其描述为完整测试套件通过。

1. `PRFixTests.testImportRestoresTodayXpSoDailyGoalBonusIsNotFarmable`：`PRFixTests.swift:347`。测试注入日期 `2026-08-26`，而 `dailyGoalReached` 使用系统日期 `2026-10-20`。
2. `CosmeticsUITests.testUnaffordableCosmeticIsNotGranted`：`cosmetic-skin_astronaut` 激活点在视图外。
3. `LessonFlowUITests.testAnsweringShowsFeedbackPanel`：`LessonFlowUITests.swift:106`，没有出现反馈面板。
4. `LessonFlowUITests.testQuittingMidLessonAsksForConfirmation`：`LessonFlowUITests.swift:127`，预期确认按钮断言失败。
5. `ScreenshotTests.testCaptureMainScreens`：`ScreenshotTests.swift:36`，预期继续按钮断言失败。

以上业务与旧测试问题留待对应卡片处理，本卡没有修改。

## 差异与疑问

- 卡片要求大按钮高 52，CSS `.btn` 高 48：按卡片实现 52pt，其余颜色、圆角、边缘和字体取 CSS；对比图保留了这一高度差异。
- 旧首页没有头像，Debug 入口使用独立头像叠加；正式头像接入留待 RD-09。Release 不显示该入口。
- 中文气泡正文按卡片使用 PingFang；设计稿使用 Noto Sans SC，因此正文的字形与字重存在差异。
- 系统楷体在 iOS 18.6 模拟器已成功可用；成功和失败的状态流均有单元证据。未在真机采集完整联网下载、断网切换过程，不将回调测试称为真实断网实录。
- 横屏产物依赖临时方向覆盖；RD-01 合并后仍需使用正式工程方向设置复验。
