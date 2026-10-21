# RD-09 首页闯关地图验收记录

日期：2026-10-21。测量基线：`12fb6c8`（已合并 RD-07 / RD-10）。PR 最终基线：`c8eb737`，仅新增其他卡片提示词文档；rebase 无冲突。
验证环境：共用 iOS 18.6 模拟器；全部测试经 `scripts/redesign/sim-test.sh` 串行执行，`CODE_SIGNING_ALLOWED=NO`。

## 实现与边界

- `MainShell` 根页面切换为 `MapHomeView`；删除旧首页、竖向地图和临时横条。
- 原 `PathNodeBuilder` 与 `PathMapNode` 整段原样搬到 `Domain/PathNodes.swift`。从 `// MARK: - Node building` 起逐字比较为相同，SHA256：`13ce49604f4cb2c0a4db3c9489296e08222903afe3d1acf953330b855a3acc6f`。
- 普通课按全书序号显示，宝箱和单元挑战沿用 builder 状态；当前定位排除挑战，全通定位最后一节普通课。
- `LazyHStack` 按单元加载；静态远山、地面、前景、小路和字块分层合成，滚动视差由几何变换更新。全部入口保留至少 44pt 命中区。
- RD-08 每日奖励、RD-19 故事/听读、RD-21 设置、RD-13 识字占位按卡片降级。宠物小屋/商店/图鉴使用 RD-07 路由。
- 未改经济规则、存档结构、core、`Features/Lesson/`、方向或签名配置。`ProgressStore` 只增加 DEBUG 合成测试种子和注释调整。
- `BookDetailView` 是旧地图另一调用点；为删除旧类型，改用同一横向地图，保留手册、跳级、宝箱及原红心拦截。
- 实际还在 Widget 找到三处旧宠物称呼注释，仅改注释，未改 Widget 功能。

## 启动耗时（AC5）

同一台 iPhone 16，同一内置 `g1up`（32 节课）。从 `app.launch()` 前的单调时钟开始，等到 `lesson-row-*` 中标记“当前”的按钮存在且可点击为止；每组终止并启动三次，取中位数。测试：`HomeLaunchPerformanceTests.testLongBookLaunchThreeTimes`。

| 首页 | 第 1 次（秒） | 第 2 次（秒） | 第 3 次（秒） | 中位数（秒） |
| --- | ---: | ---: | ---: | ---: |
| 旧首页，12fb6c8 | 55.076903 | 3.663969 | 3.189730 | 3.663969 |
| 新地图，6266882 | 4.451090 | 3.231597 | 3.353670 | 3.353670 |

两组都完整保留首轮，没有剔除；首轮可能包含安装/资源与模拟器首次启动开销。新地图中位数比旧首页减少约 8.47%，低于 4.396763 秒门槛（旧中位数 × 1.2）。这测量的是 UI 测试可操作首屏耗时，不是纯业务加载耗时。

### 滚动采样及未完成的验收

最终全量运行中的 `MapHomeUITests.testLongBookScrollFPS` 使用同一 32 课书，连续 5 次快速左滑、5 次快速右滑。DEBUG `CADisplayLink` 只统计滚动偏移变化后 0.25 秒内的显示回调，结果为：

```text
RD09_SCROLL_FPS frames=894 fps=32.77 p95_ms=59.15
```

截图见 `scroll-fps.png`。读取测试输出后探针仍继续采样，截图时显示 913 帧 / 32.84 FPS / p95 58.29ms，属于同一次运行中的稍后时刻。已将静态层合成、单元懒加载，并把滚动偏移订阅限制在视差、定位按钮和诊断视图；仍存在长帧，**AC5“快速滑动不卡顿”未完整验收**。这属于 Debug 模拟器回调统计，不代表真机 FPS、渲染 GPU 耗时或稳定 60 FPS；后续需要 Instruments / 真机继续定位长帧。AC5 启动耗时门槛通过，滚动项保留未勾选。

## 功能回归映射（AC3 / AC4）

| 验收行为 | UI 测试 |
| --- | --- |
| 当前节点可见→闯关→返回→头像菜单错题本→返回→课本徽章换书 | `MapHomeUITests.testCurrentLessonReviewAndBookSwitch` |
| 空状态及选书；缺书时原下载卡可用 | `testEmptyAndDownloadStates`（下载使用合成清单，仅证明按钮及原下载卡接线，没有发起外网下载） |
| 全屏开箱→领取→返回；0 心进入原补心提示 | `testChestClaimAndZeroHeartGate` |
| 原每日见面礼、云恢复提示、本地联赛结算 | `testDailyRewardCloudRestoreAndLeagueOverlays`（合成进度；云信封由生产 `Backup.makeEnvelope` 生成，不涉及真实 iCloud 数据） |
| Dock → 原故事列表及课文听读列表 | `testStoryDockPreservesStoriesAndReadingRoutes` |
| 锁定提示、单元手册与锁定单元跳级 | `testLockedNodeUnitGuideAndJump` |
| 长书远处当前课初次定位；滚远后回当前 | `testDistantCurrentLessonInitiallyVisible`、`testLongBookScrollReturnsToCurrent` |
| 每日任务、本周报告、金币/连签/红心详情 | `testQuestsAndOriginalDetailSheets` |
| 原页面与 RD-07 / 占位路由入口 | `LayoutUITests`、`ShellUITests.testMapEntrancesOpenAndReturn` |

## 减少动态效果（AC6）

`testReducedMotionStaysStillAndLocatesCurrentAfterScroll` 检查视差停止、GoButton 停止呼吸、宠物像素间隔一秒保持一致，且横滑后仍可回到当前课。系统的 `accessibilityReduceMotion` 进入同一暂停分支；自动化使用 DEBUG 测试参数开启该分支，没有修改模拟器系统偏好。单测覆盖 0.3 / 0.6 / 1.0 / 1.1 各层暂停修正为零。

## 设备与截图

截图均缩到原分辨率的 1/2。首屏比较保留真实新用户 32 节数学课的数据，与设计稿的识字示例在课名、节点数量和进度上不同。

| 设备 / 场景 | 证据 |
| --- | --- |
| iPhone 16 首屏与设计稿并排 | `comparison.png`、`home.png` |
| iPhone SE (3rd gen) | `home-se.png`、`book-picker-se.png` |
| iPhone 16 Pro Max（使用已有设备） | `home-promax.png`、`book-picker-promax.png` |
| iPad (A16) | `home-ipad.png`、`book-picker-ipad.png` |
| 节点开始气泡 / 换书双栏 | `start-popup.png`、`book-picker.png` |
| 空状态 / 缺书下载卡 | `empty.png`、`download.png` |
| 每日见面礼 / 云恢复 / 本地联赛 | `daily-reward.png`、`cloud-restore.png`、`league-result.png` |
| 领取宝箱 / 0 心拦截 / 任务 | `chest.png`、`zero-hearts.png`、`quests.png` |
| 滚动采样 / 减少动态效果 | `scroll-fps.png`、`reduce-motion.png` |

最终截图专项均为 `MapHomeUITests/testCaptureHomeAndTapTargets`，分别在 SE、iPad、已有 Pro Max 上执行，各 1 项、0 失败。真实检查截图确认：HUD 在安全区内贴边，七项 Dock 无重叠；SE / iPad 增高舞台时树冠伸入天空，无画布裁切。

## 基线对照与回归修复

首轮新首页全量暴露了头像长按、节点气泡子按钮标识、地标命中及横屏滚动退出问题。纯基线 `12fb6c8` 的下列 7 项对照均通过，随后在本卡修复并重新验证；不将新首页失败归为基线问题：

- `ClayGalleryUITests` 2 项；`CosmeticsUITests` 2 项。
- `LayoutUITests.testReviewEntryOpensRunnerWithMistake`。
- `LessonFlowUITests.testPathHomeOpensLessonViaStartPopup`。
- `LessonShellFlowUITests.testJumpTestCompletesAllFifteenQuestions`。

`ShellUITests.testMapEntrancesOpenAndReturn` 已覆盖原临时横条的全部 15 项入口；三处场景地标由 `testSceneLandmarksOpenAndReturn` 单独验证。节点气泡和任务卡使用独立无障碍容器保留内部按钮标识；装饰层关闭命中；头像短按菜单与 DEBUG 长按画廊均保留。

## 范围核查

- 原 builder 段逐字比较相同，原 `PathNodeBuilderTests` 继续纳入全量测试。
- `packages/core`、`Domain/Economy.swift`、`Domain/EconomyV2.swift`、`Models/CoreTypes.swift`、`Domain/Backup.swift`、`Features/Lesson/`、`Features/Pets/`、`project.yml` 相对基线均为零 diff。
- Swift 源码中 `HomeView` / `PathMapView` 类型引用、`temporaryEntrances` 及 `聪聪` 文案零残留。
- `codebase_memory` fast 刷新并执行 `detect_changes(base_branch: "origin/redesign/v2")`；Swift 图仅辅助影响分析，逻辑原样和禁止路径由 Git 文本对比单独核实。
- 主目录原有 `SeedInstaller.swift` 修改与 output 文件均保留，未参与本卡提交。

## 测试结果

测试时源码提交：`6266882`，rebase 后对应 `94b7161`；`apps/mobile` 的 Git tree 与模拟器脚本 blob 在 rebase 前后完全相同。iPhone 16 全量于 2026-10-21 19:44（Asia/Shanghai）结束。

```sh
LC_ALL=C scripts/redesign/sim-test.sh iphone16 \
  -resultBundlePath /private/tmp/rd-09-final2-iphone16.xcresult \
  -collect-test-diagnostics never

# 下列命令分别用 se / ipad / promax，且只运行截图相关用例：
LC_ALL=C scripts/redesign/sim-test.sh se \
  -only-testing:ChinaTextbookStudyUITests/MapHomeUITests/testCaptureHomeAndTapTargets \
  -resultBundlePath /private/tmp/rd-09-canvas-se.xcresult \
  -collect-test-diagnostics never
```

| 最终运行 | 通过 / 总数 | 失败 | 跳过 |
| --- | ---: | ---: | ---: |
| iPhone 16 单元测试 | 283 / 283 | 0 | 0 |
| iPhone 16 UI 测试（含地图 13 项） | 50 / 50 | 0 | 0 |
| iPhone SE (3rd gen) 截图 | 1 / 1 | 0 | 0 |
| iPhone 16 Pro Max 截图 | 1 / 1 | 0 | 0 |
| iPad (A16) 截图 | 1 / 1 | 0 | 0 |

最终 `xcresulttool get test-results summary` 摘要：

```text
result: Passed
totalTestCount: 333
passedTests: 333
failedTests: 0
skippedTests: 0
runtimeWarnings: []
```

最终提交前的整段 diff 检查只发现 `HomeRewardSheets.swift` 文件尾部多余空行，已移除；没有可执行代码变化，因此未重复运行模拟器测试。

全量关键输出：

```text
Executed 283 tests, with 0 failures (0 unexpected) in 25.499 seconds
Executed 50 tests, with 0 failures (0 unexpected) in 1334.035 seconds
** TEST SUCCEEDED **
```

旧首页启动对照在纯基线 worktree 中临时使用相同的 `HomeLaunchPerformanceTests` 测量脚本，业务源码不变；其他基线回归使用原测试。基线通过后的临时测量脚本已撤下。未改 core，因此没有重复运行 npm 测试。未做真机、外网资源下载或真实 iCloud 验证。

只提交半分辨率截图及此摘要；完整日志、附件导出和 `.xcresult` 按提示词在推送并创建 PR 后清理。
