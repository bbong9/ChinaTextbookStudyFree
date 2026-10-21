# RD-04 验收结果

日期：2026-10-21。基于 `origin/redesign/v2` 的 `dabb079`，独立 worktree `/private/tmp/rd-04-pet-renderer`，分支 `codex/rd-04-pet-renderer`。

## 验收与实现

| 标准 | 结果与证据 |
| --- | --- |
| AC1 | Debug Gallery 新增「宠物」页。10×8 表情：[完整网格](moods-10x8.png)；[开花与裂纹](bloom-crack-0-3.png)；[与设计稿并排对比](design-comparison.png)。 |
| AC2 | 每种宠物共用头顶、眼中线、脖子与缩放锚点。米团、阿橘、冰冰 × 11 配饰：[总览](accessories-3x11.png)，`accessories/` 下有 33 张单图。 |
| AC3 | 删除旧组件，替换卡片指定的全部 16 个文件。工程源码旧组件名称搜索为 0；三种反应可重复触发，见 `PetGalleryUITests.testPetsAccessoriesAndThreeRepeatableReactions` 及反应截图。 |
| AC4 | 系统减少动态效果或 Gallery 暂停时，呼吸、眨眼、挥手和三种反应全部停止。专项运行确认 `system:true, initial:开启`，前后间隔 1.1 秒、触发升级后的宠物截图像素相同。系统设置已恢复原值 `0`。 |
| AC5 | 本卡 6 项单元测试、2 项 UI 测试通过；完整回归存在任务提示词允许的既有失败，详见下表。UI 测试中没有依赖旧中文名字的断言。 |

`PetKind.rawValue` 与 RD-05 两端目录一致，中文名从 `Pets` 读取。默认环境为米团、无配饰，未接入宠物存档。配饰仍使用原有 12 个皮肤 ID。分享卡的 ImageRenderer 入口显式接收宠物环境，防止导出时丢失当前出战伙伴。

## 测试

完整日志及 `.xcresult` 只留本地，不纳入提交。均使用 iOS 18.6 模拟器、串行执行、`CODE_SIGNING_ALLOWED=NO`。

| 运行 | 结果 | 本地证据 |
| --- | --- | --- |
| 系统减少动态效果开启，iPhone 16 | 6 单元 + 2 UI，0 失败；含分享卡环境传播检查 | `/private/tmp/rd04-system-reduce-motion.log`、同名 `.xcresult` |
| 默认工程方向，全量 build test | BUILD SUCCEEDED；237 单元有 1 项失败，17 UI 有 4 项失败，共 254 项、249 通过；TEST FAILED，退出码 65 | `/private/tmp/rd04-full-regression.log`、同名 `.xcresult` |
| 最终预览布局，iPhone 16 | 6 单元 + 2 UI，0 失败 | `/private/tmp/rd04-final-iphone16.log`、同名 `.xcresult` |
| 最终预览布局，iPhone SE (3rd gen) | 2 UI，0 失败 | `/private/tmp/rd04-final-se.log`、同名 `.xcresult` |
| 最终预览布局，iPad (A16) | 2 UI，0 失败 | `/private/tmp/rd04-final-ipad.log`、同名 `.xcresult` |
| 最终布局，系统减少动态效果开启 | 1 UI，0 失败；再次确认 `system:true, initial:开启` | `/private/tmp/rd04-final-system-motion.log`、同名 `.xcresult` |

全量命令（不传方向覆盖、不限定测试）：

```sh
xcodebuild -project apps/mobile/ChinaTextbookStudy.xcodeproj \
  -scheme ChinaTextbookStudy \
  -destination 'platform=iOS Simulator,id=8023CE44-AC84-48F9-8E7C-F4CFEAA2F4C4' \
  -derivedDataPath /private/tmp/rd04-derived \
  -resultBundlePath /private/tmp/rd04-full-regression.xcresult \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  CODE_SIGNING_ALLOWED=NO build test
```

最终系统验证限定 `PetGalleryUITests/testReduceMotionStopsBreathingBlinkWaveAndReactions`，其余最终专项运行在以上基础上加 `-only-testing:ChinaTextbookStudyTests/PetRendererTests` / `-only-testing:ChinaTextbookStudyUITests/PetGalleryUITests`，按机型选择测试集。iPhone 16 执行 `build test`；SE 和 iPad 使用该最终构建执行 `test-without-building`。防重叠断言、反应点击区及暂停前后像素检查在三机型均通过。iPhone 横屏证据仅在本地构建命令中加：

```sh
'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone=UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight'
```

未修改 `project.yml` 的方向、路由或签名配置。这沿用 RD-02 的截图方式，不代表 RD-01 正式横屏外壳验收。PR #4 在提交前检查时仍 OPEN。

### 已知失败

与 `eaeff4f` 基线一致的 5 项失败：

- `PRFixTests.testImportRestoresTodayXpSoDailyGoalBonusIsNotFarmable`：`PRFixTests.swift:347`，固定日期与当天状态导致 `XCTAssertTrue` 失败。
- `CosmeticsUITests.testUnaffordableCosmeticIsNotGranted`：宇航员按钮位于视口外，无法计算点击点。几何仍为 `{{790.0, 424.3}, {116.0, 158.0}}`，标识仍为 `cosmetic-skin_astronaut`；名称从「聪聪」变为「米团」，值新增宠物说明，**失败原因和位置未变**。
- `LessonFlowUITests.testAnsweringShowsFeedbackPanel`：反馈面板等待断言失败，`LessonFlowUITests.swift:106`。
- `LessonFlowUITests.testQuittingMidLessonAsksForConfirmation`：退出确认等待断言失败，`LessonFlowUITests.swift:127`。
- `ScreenshotTests.testCaptureMainScreens`：检查答案后的继续按钮等待失败，`ScreenshotTests.swift:36`。

`LayoutUITests` 的 5 项本次全部通过；本卡 6 项单元和 2 项 UI 在全量运行中也通过。该全量构建之后仅调整 Debug 反应预览的控件排布及防重叠断言，最终状态由三机型专项再次验证。

基线比对来源为任务提示词，以及仓库已提交的 `rd-02/tests-baseline-failures.txt`、`rd-05/ios-full-regression.txt`；未为本卡修复范围外测试。

## 截图性质

`moods-10x8.png`、`bloom-crack-0-3.png`、`accessories-3x11.png` 和 33 张配饰单图，来自模拟器单元测试中 ImageRenderer 对完整 SwiftUI 视图的导出，@2x；它们不是整屏截图。`design-comparison.png` 是设计原图与上述导出图的合成对照。

`screenshots/iphone-se/`、`screenshots/iphone16/`、`screenshots/ipad-a16/` 是 UI 测试抓取的三机型完整屏幕，包含表情、配饰、反应页；减少动态效果页另有专用截图，其中 `screenshots/iphone16/system-reduce-motion-landscape.png` 来自最终布局的系统设置开启验收，其他 `reduce-motion-landscape.png` 是 Gallery 本地暂停。仅根据 PNG 的 EXIF 方向将图片转正，没有裁切界面。完整网格超出视口，可在预览页纵向滚动查看。

## 和设计稿的差异、疑问与后续

- 表情优先遵循开发卡：开心、欢呼、自豪均为眯眼，思考看向一侧，惊讶为圆眼与 O 形嘴；保留各物种鼻子、喙、腮红与高光。设计稿神秘蛋没有脸，本卡为 10×8 表情要求补脸。
- `crack=0` 是完整蛋壳；原稿的横向锯齿对应 `crack=1`，2、3 继续增加支裂。米团开花按卡片用小花替换新芽，原稿实现为叠加花朵。
- 帽饰遮住米团新芽、猫头鹰原生学士帽；高帽超出顶部时将整只宠物等比适配画布。配饰图形只读锚点，未写宠物 × 配饰组合分支。
- 新增 `AchievementsView` 的环境读取与参数传递，属于分享图片导出边界所需的最小衔接；没有改变成就规则。
- Widget 有独立的 `MiniPandaFace` 绘制，不在卡片指定的 16 个替换文件内。本卡清理其失效组件注释和旧名描述，独立 Widget 造型保留，后续统一；本卡 AC3 的页面替换范围为主 App。
- 未实现宠物购买、喂养、存档或旧皮肤迁移，留给 RD-06 / RD-07；未做真机验收。

## 搜索与范围检查

```text
rg -n 'MascotView' apps/mobile --glob '*.swift' --glob 'project.yml'
退出码 1，0 命中。

rg -n '聪聪' apps/mobile/ChinaTextbookStudyUITests
退出码 1，0 命中，无需修改已有 UI 测试文案断言。
```

`MainShell.swift` 只有 1 处组件构造器替换；`HomeView.swift` 只有 2 处。core、`UserProgress`、备份、经济、工程配置均无改动。已重新运行 XcodeGen，生成工程不提交。`codebase_memory.detect_changes` 核对了已跟踪文件影响面，新增文件另由 Git 清单核对。

主目录既有 `SeedInstaller.swift` 修改及 `output/` 未跟踪文件保留。只在本卡 worktree 开发，资源软链接仍为忽略文件，不提交。

## 暂存前原始范围快照

`git diff --stat`（不含下方 `??` 新文件）：

```text
 apps/mobile/ChinaTextbookStudy/App/MainShell.swift |   2 +-
 .../ChinaTextbookStudy/Clay/ClayGallery.swift      |  15 +-
 .../ChinaTextbookStudy/Clay/ClayTokens.swift       |  20 +
 .../ChinaTextbookStudy/Components/MascotView.swift | 521 ---------------------
 .../Components/ShareCardView.swift                 |  14 +-
 .../ChinaTextbookStudy/Domain/Cosmetics.swift      |   8 +-
 .../Features/Achievements/AchievementsView.swift   |   3 +-
 .../Features/Guide/UnitGuideView.swift             |   2 +-
 .../Features/Home/HomeView.swift                   |   4 +-
 .../Features/Jump/JumpTestView.swift               |   6 +-
 .../Features/League/LeagueView.swift               |   2 +-
 .../Features/Lesson/IntroCardView.swift            |   2 +-
 .../Features/Lesson/LessonResultView.swift         |   7 +-
 .../Features/Lesson/LessonRunnerView.swift         |   6 +-
 .../Features/Onboarding/OnboardingView.swift       |  12 +-
 .../Features/Profile/ProfileView.swift             |   4 +-
 .../Features/Review/MistakeReviewRunnerView.swift  |   4 +-
 .../Features/Review/ReviewView.swift               |   2 +-
 .../Features/Settings/SettingsView.swift           |   2 +-
 .../Features/Shop/ShopView.swift                   |   4 +-
 .../Features/Stories/StoryReaderView.swift         |   2 +-
 .../Services/NotificationService.swift             |  10 +-
 .../ChinaTextbookStudyWidget/StreakWidget.swift    |   4 +-
 23 files changed, 82 insertions(+), 574 deletions(-)
```

`git status --short`（新增证据目录包含本页、截图，无完整日志）：

```text
 M apps/mobile/ChinaTextbookStudy/App/MainShell.swift
 M apps/mobile/ChinaTextbookStudy/Clay/ClayGallery.swift
 M apps/mobile/ChinaTextbookStudy/Clay/ClayTokens.swift
 D apps/mobile/ChinaTextbookStudy/Components/MascotView.swift
 M apps/mobile/ChinaTextbookStudy/Components/ShareCardView.swift
 M apps/mobile/ChinaTextbookStudy/Domain/Cosmetics.swift
 M apps/mobile/ChinaTextbookStudy/Features/Achievements/AchievementsView.swift
 M apps/mobile/ChinaTextbookStudy/Features/Guide/UnitGuideView.swift
 M apps/mobile/ChinaTextbookStudy/Features/Home/HomeView.swift
 M apps/mobile/ChinaTextbookStudy/Features/Jump/JumpTestView.swift
 M apps/mobile/ChinaTextbookStudy/Features/League/LeagueView.swift
 M apps/mobile/ChinaTextbookStudy/Features/Lesson/IntroCardView.swift
 M apps/mobile/ChinaTextbookStudy/Features/Lesson/LessonResultView.swift
 M apps/mobile/ChinaTextbookStudy/Features/Lesson/LessonRunnerView.swift
 M apps/mobile/ChinaTextbookStudy/Features/Onboarding/OnboardingView.swift
 M apps/mobile/ChinaTextbookStudy/Features/Profile/ProfileView.swift
 M apps/mobile/ChinaTextbookStudy/Features/Review/MistakeReviewRunnerView.swift
 M apps/mobile/ChinaTextbookStudy/Features/Review/ReviewView.swift
 M apps/mobile/ChinaTextbookStudy/Features/Settings/SettingsView.swift
 M apps/mobile/ChinaTextbookStudy/Features/Shop/ShopView.swift
 M apps/mobile/ChinaTextbookStudy/Features/Stories/StoryReaderView.swift
 M apps/mobile/ChinaTextbookStudy/Services/NotificationService.swift
 M apps/mobile/ChinaTextbookStudyWidget/StreakWidget.swift
?? apps/mobile/ChinaTextbookStudy/Clay/PetGallery.swift
?? apps/mobile/ChinaTextbookStudy/Components/PetAccessories.swift
?? apps/mobile/ChinaTextbookStudy/Components/PetArtwork.swift
?? apps/mobile/ChinaTextbookStudy/Components/PetDrawing.swift
?? apps/mobile/ChinaTextbookStudy/Components/PetEnvironment.swift
?? apps/mobile/ChinaTextbookStudy/Components/PetView.swift
?? apps/mobile/ChinaTextbookStudyTests/PetRendererTests.swift
?? apps/mobile/ChinaTextbookStudyUITests/PetGalleryUITests.swift
?? docs/redesign-v2/evidence/rd-04/
```
