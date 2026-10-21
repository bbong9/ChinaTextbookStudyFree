# RD-03 场景素材库 · 验证摘要

验证日期：2026-10-21。独立工作树：`/private/tmp/rd-03-scene-kit`；分支：`codex/rd-03-scene-kit`。初始集成基线为 `13120ce`；提交前已同步到 `55c120f`，包含 RD-00 基线修复和 RD-06 宠物存档接线。

## 实现与范围

- `Clay/Scene/` 覆盖卡片全部素材、三层路线、四状态字块及十二种 Dock 图标。参数保留设计源码的位置、缩放、颜色和状态输入；Path 坐标来自 `design/art.js`、`screens.js`，转换为静态 Swift Path，不在运行时解析 SVG。
- `Clay/Motion.swift` 统一 bob / drift / drift2 / pulse / twinkle / flutter，沿用 CSS 周期、幅度和 ease-in-out。静态背景使用 Canvas / `.drawingGroup()` 合成，云、蝴蝶等单独更新。
- DEBUG Gallery 保留第四页「宠物」，追加第五页「场景」，用固定数据展示地图、全部素材和四种字块状态。宠物测试改为固定进入第四页；同步基线时保留 RD-00 的宠物预览高度修复，仅将其页码条件从末页改为第四页。
- `ClayButtons.swift` 只将卡片指定的两个裸色移为 `iconButtonDepth`、`goButtonDepth` 令牌。没有修改业务、经济、存档、宠物实现、HomeView、MainShell、路由、方向配置或签名，没有新增依赖和 App 位图。

## 验收对照

| 标准 | 证据 |
| --- | --- |
| AC1 | `design-comparison.png`：02-map 设计稿与 iPhone 16 地图并排；三机横屏为 `se-map.png`、`iphone16-map.png`、`ipad-map.png`。背景使用设计稿固定坐标；按范围省略业务 HUD / 宠物，四角按钮和底部选择器为 Debug 预览控件。 |
| AC2 | `iphone16-cube-done.png`、`iphone16-cube-current.png`、`iphone16-cube-locked.png`、`iphone16-cube-game.png`，已目视检查。四状态及十二图标由 UI 用例覆盖。 |
| AC3 | `se-instruments.png`、`se-instruments-device.png`：共用 SE / iOS 18.6 上实际 Time Profiler 记录，12.653592 秒，总采样权重 550 ms、主线程 543 ms，调用栈包含 ClayMotion / SwiftUI 更新。详见下方测量边界。 |
| AC4 | `se-system-setting-enabled.png` / `se-system-setting-restored.png` 为真实系统开关打开和恢复；`se-system-{map,materials}-{before,after}.png` 为系统开启后的静帧。另有 iPhone 16 / iPad / SE 正式 UI 静帧用例及动画单元采样。 |
| AC5 | 新增实现全部为 SwiftUI Path / Canvas / 渐变，新增 App 位图、第三方依赖均为 0。证据目录中的 PNG 仅为验收截图。 |

`iphone16-materials.png` 展示全部素材和十二种 Dock 图标。

## 测试结果

所有模拟器测试使用 `scripts/redesign/sim-test.sh` 全机串行运行，iOS 18.6，关闭签名和并行测试。命令前加 `LC_ALL=C`，兼容系统 Bash 对脚本中文标点附近变量名的处理；没有修改队列脚本。

最终集成全量（`55c120f` 基线，源码提交 `bf23225`）：**287/287 通过**，其中单元 **268/268**、UI **19/19**；退出码 **0**，0 跳过、0 预期失败。包含 SceneKitTests **4/4**、SceneKitUITests **2/2**、ClayGalleryUITests **2/2**、PetGalleryUITests **2/2**。没有筛选、跳过或失败重试。

```text
ChinaTextbookStudyTests.xctest: Executed 268 tests, with 0 failures (0 unexpected)
ChinaTextbookStudyUITests.xctest: Executed 19 tests, with 0 failures (0 unexpected)
xcresult: totalTestCount=287 passedTests=287 failedTests=0 skippedTests=0 expectedFailures=0
** TEST SUCCEEDED **
```

已完成的专项结果：

- iPhone 16 横屏：SceneKitUITests **2/2 通过**；宠物 Gallery **2/2 通过**。
- SE 横屏：正式 SceneKitUITests **2/2 通过**；真实系统开关临时取证用例 **1/1 通过**，结束时确认系统开关恢复为 false、App 暂停值恢复为「关闭」。临时驱动已删除，不纳入提交和最终全量。
- iPad：素材 / 四状态 / 十二图标用例通过；最终静帧用例复跑 **1/1 通过**。
- 减少动态效果静帧比较覆盖地图和全部素材，先等待 0.6 秒让按钮按压反馈复位，再间隔 1.2 秒比较全屏解码像素。Canvas 合成观测到 iPhone 1 个像素、iPad 2 个像素的单级色阶差；最终断言逐通道容忍 1/255 色阶舍入，没有裁掉动画区域。
- SceneKitTests **4/4 通过**，覆盖原 CSS 周期与极值、暂停时的原始变换、地图路线控制点、SVG 星形舍入；macOS 提取的同组 XCTest **4/4 通过**仅作补充。
- XcodeGen、源码和测试独立类型检查通过。没有修改 core，未运行 npm test。

上面三机截图、系统开关和 Instruments 取证在同步前完成；同步前后 `Clay/Scene/` Git tree 均为 `f6c396f10c27a6865a4b2f984233f5b8ea7d9c9b`，`Motion.swift` blob 均为 `a363b4ceb823c749470485b1780af0bf56d9cc3a`。最终集成全量另行验证分页框架与 RD-00 / RD-06 的兼容。

## 系统开关与性能测量边界

真实系统开关通过 XCTest 打开 Settings → 辅助功能 → 动态效果 → 减弱动态效果；同时确认 `UIAccessibility.isReduceMotionEnabled == true` 和 App 暂停值为「开启」。地图、全部素材分别通过全屏静帧比较；最后关闭系统开关并确认恢复。成功关键输出来自 1 项测试、0 失败的同一轮：

```text
RD03_SYSTEM_REDUCE_VERIFIED
RD03_SYSTEM_REDUCE_RESTORED=false
Executed 1 test, with 0 failures (0 unexpected)
** TEST SUCCEEDED **
```

Instruments 记录设备为共用 SE `40CF54B0-FCAC-4473-B856-31DDBA65ACC6`，附加 App PID 22898；实际起止为 **2026-10-21 10:57:19.228–10:57:31.882（GMT+8）**，位于场景地图保持前台、暂停关闭的 10:54:10–10:59:09 取证窗口内。Time Profiler 正常完成并保存，UI 中有实际采样和 ClayMotion 调用栈。

550 ms / 543 ms 是整个记录窗口累计采样权重，不能当作单帧耗时或 FPS。该模拟器的 Animation Hitches 报 `Hitches is not supported on this platform`，Time Profiler 也有一项表缺少输入源警告，Hangs 显示 No Data；这些均不计作 0 次卡顿。本卡按 AC3 允许的 Instruments 截图提交模拟器取证，没有声称量化 FPS 或真机性能通过。

## 命令

```sh
cd apps/mobile && xcodegen generate
# 以下命令在工作树根目录执行：
LC_ALL=C DERIVED_DATA=/private/tmp/rd03-validation/DerivedData \
  scripts/redesign/sim-test.sh iphone16 \
  -resultBundlePath /private/tmp/rd03-validation/integrated-regression-iphone16.xcresult \
  -collect-test-diagnostics never -jobs 2 CODE_SIGNING_REQUIRED=NO
```

三机场景专项使用同一队列入口，分别选择 `iphone16` / `se` / `ipad`，加 `-only-testing:ChinaTextbookStudyUITests/SceneKitUITests`。iPad 最终静帧复跑再限定 `/testReducedMotionFreezesMapAndEveryAnimationKind`。iPhone 横屏取证另加临时构建参数 `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone=UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight`，没有写回工程；完整回归使用工程原始方向。

```sh
xcrun xctrace record --template 'Time Profiler' \
  --device 40CF54B0-FCAC-4473-B856-31DDBA65ACC6 \
  --attach ChinaTextbookStudy --time-limit 12s \
  --output /private/tmp/rd03-validation/se-time-profiler.trace
```

系统开关用例的名称为 `ZZRD03EvidenceDriver/testLiveSceneAndSystemReducedMotion`，仅用于本机取证，已在最终全量前删除并重新生成工程。

## 历史结果与清理

同步 RD-00 前的 `13120ce` 完整回归：241 项单元 / 1 失败、19 项 UI / 5 失败。五项旧失败与 eaeff4f 对应方法和断言一致；第六项为 RD-04 竖屏宠物布局断言，并在未改动的 `13120ce` 上复现相同坐标（`692.4063981042655 > 708.3501184834123` 不成立）。这些历史结果不代替最终集成回归。

早期两轮临时人工驱动等待超时，未算作系统开关通过；最终由上面真实 Settings 自动操作的 0 失败结果替代。

`git diff --check` 及范围检查通过。codebase_memory `detect_changes` 列出本卡 15 个源码 / 测试文件；没有修改主目录文件。主目录的 SeedInstaller 哈希与开工快照存在并行变化，没有将其回滚或宣称整个主目录哈希未变。

完整日志、`.xcresult` 和 trace 保留在本机 `/private/tmp/rd03-validation/`，不提交。按 README 要求，PR 推送后清理本卡 `.xcresult` 与中间日志；仓库仅保存截图和本摘要。
