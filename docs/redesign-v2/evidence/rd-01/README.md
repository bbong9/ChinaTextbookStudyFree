# RD-01 验收证据

验收日期：2026-10-21。分支：`codex/rd-01-landscape-shell`，目标：`redesign/v2`。
本轮基线包含 RD-00、RD-02、RD-04、RD-06 和统一测试脚本；最终基线及源码指纹见 `scope-check.json`。
本目录仅记录本机 iOS 18.6 模拟器证据，只提交截图和结果摘要。

## 构建与集成

- `xcodegen generate`、统一脚本内的无签名模拟器构建成功。
- `built-orientations.json` 来自实际构建的 Info.plist：iPhone / iPad 均只有左右横屏，`UIRequiresFullScreen` 为 true，三份字体均在包内。
- `project.yml` 除方向和全屏设置外与集成基线一致；fonts/resources、签名、Team ID、Bundle ID 均未修改，生成工程未提交。
- RD-02 的 `#if DEBUG clayGallery`、首页长按头像和辅助功能入口保留。Gallery 在唯一 `NavigationStack` 的目的地内，返回后仍能进入占位页。
- RD-04 在 `MainShell.swift` / `HomeView.swift` 中的三处 `PetView` 均保留；昵称面板冲突合并为可滚动布局并保留 PetView。
- SE 首轮复验发现复习结算页的返回按钮超出可用高度；本卡按 AC4 给结算内容补滚动，保留 PetView、奖励逻辑与内容不足一屏时的居中布局。`LayoutUITests.testReviewEntryOpensRunnerWithMistake` 继续验证实际完成复习并返回；修复前关键输出见 `se-review-scroll-fix.json`。
- `scope-check.json` 记录上述检查以及测试后的源码指纹；`packages/core` 相对目标分支无改动，未运行 `npm test`。

## 串行测试

所有模拟器测试均通过 `scripts/redesign/sim-test.sh` 全机排队，先完成 iPhone 16 全量，再依次执行 SE、iPad 的截图用例；每轮结束由脚本关闭设备。共用 SE 在首轮前缺失，由该脚本按 README 1.4 的规则自动补齐同名 iOS 18.6 设备；设备 UUID 记录在截图索引中。

实际 iPhone 16 全量命令：

```sh
LC_ALL=C DERIVED_DATA=/private/tmp/rd-01-derived \
  scripts/redesign/sim-test.sh iphone16 \
  -resultBundlePath /private/tmp/rd01-final-iphone16.xcresult \
  -collect-test-diagnostics never -jobs 2
```

SE 通过同一脚本执行 `ShellUITests` 以及 `LayoutUITests` 的旧入口、实际复习、年级/换书三项；iPad 通过同一脚本执行 `ShellUITests`。
完整日志和 `.xcresult` 不提交，完成摘要和截图归档后按 README 的磁盘规则清理。

| 模拟器 | 单元测试 | UI 测试 | 摘要 |
| --- | --- | --- | --- |
| iPhone 16 | 264/264 通过 | 22/22 通过，0 跳过 | `iphone16-summary.json` |
| iPhone SE (3rd gen) | 本轮仅截图相关 UI | 7/7 通过，0 跳过 | `se-summary.json` |
| iPad (A16) | 本轮仅截图相关 UI | 4/4 通过，0 跳过 | `ipad-summary.json` |

合计 297 次测试通过，其中单元测试 264 次、UI 测试 33 次，0 失败、0 跳过。官方摘要与逐项日志计数交叉核对见 `validation-summary.json`。

## 基线与回归

已集成 RD-00 的日期测试、宠物预览布局和方向复位修复。264 条原有单元测试和 22 条 UI 测试本轮均通过，不使用历史基线失败例外。RD-00 的原始前后对照见 [RD-00 回归证据](../rd-00/README.md)。

`LayoutUITests` / `ScreenshotTests` 已更新为横屏；原有完整可见性、正确 seed 答案和业务断言保留，共享滚动助手适配自绘页头及祖先视口。未新增 `XCTSkip`，本轮 0 跳过。

## 验收项与截图索引

| 验收项 | 测试及截图 |
| --- | --- |
| AC1 / AC2 横屏、无 Tab / 侧栏 | `ShellUITests.testLaunchAndRotationStayLandscape`；`*-home-landscape.png` |
| AC3 全部 15 个占位路由进入并返回 | `ShellUITests.testAllFifteenPlaceholderRoutesOpenAndReturn`；`*-placeholder-pet-family.png` |
| AC4 排行、错题本、商店、我的、成就墙 | `LayoutUITests.testTemporaryEntrancesReachLegacyPages`；`se-legacy-{league,review,shop,profile,achievements}.png` |
| AC4 实际完成复习 | `LayoutUITests.testReviewEntryOpensRunnerWithMistake`；`se-legacy-review-runner.png` |
| AC4 换年级、实际换书 | `LayoutUITests.testGradeBrowsingAndBookSwitching`；`se-legacy-grades.png`、`se-legacy-book-picker.png` |
| AC5 完整引导、toast、自动第一课、不重复推进 | `ShellUITests.testOnboardingAutomaticallyStartsFirstLessonOnce`；`*-onboarding-first-lesson-toast.png` |
| RD-02 调试路由仍在单一栈中 | `ShellUITests.testDebugGalleryOpensAndReturnsWithinShell`；`*-clay-gallery.png` |

`screenshots.json` 记录文件、测试名、设备 UUID、原始 XCTest 附件、时间戳、尺寸和 SHA256。原图只按 EXIF 校正像素朝向，无裁切、无重绘。

## 疑问与后续

- 统一脚本在本机默认 `LC_ALL=C.UTF-8` 下把 `$busy` 后的中文标点误读入变量名，触发 `unbound variable`，首次未执行测试。最小 Bash 片段复现后，设为 `LC_ALL=C` 即可正常运行原脚本。本卡未改包装脚本或绕开全机锁；上游可给中文标点前的变量引用加花括号。
- 临时返回页头沿用现有 Duo 令牌，RD-22 再统一样式；RD-09 替换首页地图并收纳临时入口。本卡未提前实现任何新页面内容。
