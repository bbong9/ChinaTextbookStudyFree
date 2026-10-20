# RD-12 验收证据

验证日期：2026-10-20。基线：`eaeff4f`（`redesign/v2`）。本卡只实现数据、构建及加载管线，没有新增界面，因此无界面截图。

## 审阅修正（2026-10-20）

- core 新增 `HanziOriginForm`：`script` 限定为 `jiaguwen` / `jinwen` / `xiaozhuan`，`svgPath`、`source`、`license` 均为必填字符串；Swift 同步结构，`forms` 改为对应的结构数组。实际 100 个字卡中的 8 份字源仍全部使用空数组，内容文件及 seed 未改动。
- Swift 保留 `HanziScene` 枚举，先解码场景字符串，再将未知场景映射为 `nil`。新增 `testUnknownSceneKeepsCharacterAndSharedStrokes`：将实际 seed 解压副本中的「山」场景改为 `future-scene`，确认仍可通过 `DataLoader` 加载，拼音、字源说明和笔顺仍保留；原有 `mountains` 仍映射到已知枚举。

| 本轮验证 | 结果 | 原始输出 |
| --- | --- | --- |
| `npm test` | 14 个文件，233 项通过、0 失败，退出 0 | `core-review-tests.log` |
| `npm run type-check --workspace=@cstf/core` | 退出 0 | `core-review-types.log` |
| 无签名构建及 `HanziDecodingTests` | 编译通过；6 项通过、0 失败，退出 0 | `ios-hanzi-review.log`、`ios-hanzi-review-summary.json` |

本轮从 PR 原提交 `e85c444` 建立 `/private/tmp/rd12-review-fixes` 隔离工作树，使用 Xcode 27.0（27A266a）、iPhone 16 / iOS 18.6 模拟器，XcodeGen 生成工程后运行：

```sh
cd apps/mobile && xcodegen generate && cd ../..
xcodebuild -project apps/mobile/ChinaTextbookStudy.xcodeproj \
  -scheme ChinaTextbookStudy \
  -destination 'platform=iOS Simulator,id=59BBC4A1-B3F8-4401-8A95-0A3F70AD45E1' \
  -derivedDataPath /private/tmp/rd12-derived -parallel-testing-enabled NO \
  -resultBundlePath /private/tmp/rd12-review-hanzi.xcresult \
  -only-testing:ChinaTextbookStudyTests/HanziDecodingTests \
  CODE_SIGNING_ALLOWED=NO build test
```

`ios-hanzi-review.log` 原样摘录构建成功标记及测试段；完整构建输出留在 `/private/tmp/rd12-review-xcodebuild.log`，结果包为 `/private/tmp/rd12-review-hanzi.xcresult`。本轮未重跑完整 iOS 回归，下文原有 6 项失败及基线对照记录继续保留，全局门禁尚未全绿。

## 验收对应

| 验收项 | 证据 |
| --- | --- |
| AC1 | `build-hanzi.log`：生成 100 字；`hanzi-pipeline-tests.log`：缺 source/license 的 CLI 均退出 1，且不改产物。 |
| AC2 | `hanzi-pipeline-tests.log`：22 项通过，包含拼音、三种笔画数不一致、干扰字同音/同形、组词漏字等故意错误。 |
| AC3 | `ios-hanzi-review.log`、`ios-hanzi-review-summary.json`：审阅修正后 `HanziDecodingTests` 6 项通过，遍历最终 seed 全部 100 字并合并共享笔顺，新增未知场景兼容测试。 |
| AC4 | `scripts/hanzi/report-chinese-g1up.md`：每字均为 draft，有来源、缺失项、复核点和逐项勾选清单。 |
| AC5 | `seed-audit.json`：7,438,076 → 7,672,566 字节，增量 234,490 字节；原有 2,624 个条目内容不变，无新增录音。 |
| AC6 | `content/hanzi/strokes/`：100 个笔顺 JSON、APL 全文 LICENSE、来源及转换 README；字卡和代码不嵌入第三方轮廓。seed 内按 `data/hanzi/strokes/` 保持同一目录结构。 |

两个识字单元的完整识字表＋写字表初稿共 100 个去重字，按用户确认的范围执行，保留两类字表归属。并未人工对照纸质课本、教参或笔顺规范；教材版次、园地归属、笔顺规范差异和内容准确性须按生成报告复核，不能把机器通过当作 verified。

## 可重复命令

在仓库根目录：

```sh
npx tsx scripts/hanzi/build-hanzi.ts chinese-g1up
npx tsx --test scripts/hanzi/build-hanzi.test.ts
npm test
npm run type-check --workspace=@cstf/core
bash scripts/build-seed-zip.sh --content-only
```

对应原始输出为 `build-hanzi.log`、`hanzi-pipeline-tests.log`、`core-tests.log`、`core-types.log`。前三者分别为生成成功、22/22、233/233；core 类型检查退出 0。管线三个 TypeScript 文件的严格类型检查亦退出 0。重复生成的 204 个内容文件 SHA-256 一致。

iOS 为隔离共享工作区其他卡片，使用 `/tmp/rd12-ios-validation`（基线加本卡文件）及 XcodeGen 生成的工程；没有包含工作区其他改动。没有生成或配置签名、Team ID、Bundle ID。完整回归命令：

```sh
xcodebuild -project apps/mobile/ChinaTextbookStudy.xcodeproj \
  -scheme ChinaTextbookStudy \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -derivedDataPath /tmp/rd12-derived \
  -resultBundlePath /tmp/rd12-tests-ios18.xcresult \
  CODE_SIGNING_ALLOWED=NO build test
```

原命令只指定 iPhone 16 时，Xcode 默认选择最新 iOS 27，而该机型的本机可用 runtime 是 iOS 18.6，首次退出 70。明确 OS=18.6 后编译成功；完整回归为 **222 项：216 通过、6 失败**（单测 209 项、1 失败；UI 13 项、5 失败），退出 65，**全局门禁尚未全绿**。结构化结果见 `ios-full-summary.json`，测试行原样摘录见 `ios-full-tests.log`。原始完整日志及结果包留在 `/tmp/rd12-xcodebuild-ios18.log` 和 `/tmp/rd12-tests-ios18.xcresult`。

完整回归后更新了拼音按钮复用单字音频地址的最终 seed，再运行：

```sh
xcodebuild -project apps/mobile/ChinaTextbookStudy.xcodeproj \
  -scheme ChinaTextbookStudy \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -derivedDataPath /tmp/rd12-derived -parallel-testing-enabled NO \
  -resultBundlePath /tmp/rd12-final-hanzi.xcresult \
  -only-testing:ChinaTextbookStudyTests/HanziDecodingTests \
  CODE_SIGNING_ALLOWED=NO build test
```

最终 5/5 通过，退出 0。没有内置汉字录音，测试确认单字、拼音、组词和字源均有回退原文，且单字播放进入系统 TTS 队列。此证据不代表人工试听或真机验收；孤立多音字的系统选音仍待试听。

## 范围外回归及基线对照

从同一基线另建 `/tmp/rd12-clean-baseline`，XcodeGen 生成工程，`build-for-testing` 退出 0；使用专用 iPhone 16 / iOS 18.6 模拟器执行相同失败用例，未带入本卡文件。

| 用例 | 本卡完整回归 | 原始基线定向复测 |
| --- | --- | --- |
| `PRFixTests.testImportRestoresTodayXpSoDailyGoalBonusIsNotFarmable` | 失败（347 行） | 同断言失败；测试固定 2026-08-26，而 dailyGoalReached 经 todayXp 读取实际当天 2026-10-20。 |
| `CosmeticsUITests.testUnaffordableCosmeticIsNotGranted` | 失败 | 同样无法计算 `cosmetic-skin_astronaut` 的点击坐标。 |
| `LayoutUITests.testProfileReachesAchievementsAndSettings` | 失败 | 通过；未稳定复现，不能据此认定已定位原因。 |
| `LessonFlowUITests.testAnsweringShowsFeedbackPanel` | 失败（106 行） | 同断言失败。 |
| `LessonFlowUITests.testQuittingMidLessonAsksForConfirmation` | 失败（127 行） | 同断言失败。 |
| `ScreenshotTests.testCaptureMainScreens` | 失败（36 行） | 同断言失败。 |

基线测试的原始测试行见 `ios-baseline-tests.log`、`ios-baseline-ui-remaining.log`，结构化结果见 `ios-baseline-summary.json`、`ios-baseline-ui-remaining-summary.json`。两组均退出 65：第一组 3 项中 1 通过、2 失败，第二组 3 项全部失败。其中五项在无本卡的基线上也失败；导航用例需后续排查。按任务范围未修改这些测试及对应功能，也未把旧截图附件当作 RD-12 界面证据。

## 许可与范围检查

- `content/hanzi/strokes/LICENSE` Git blob 为 `c1aba41d3f5f38b323dbc4234aa3cf83c7a40faf`，与固定上游 commit 的 APL 全文一致。
- APL 原文第 47、52 行自带行尾空格，测试原始日志自带末尾空行，均保留原文；`git diff --cached --check -- . ':!content/hanzi/strokes/LICENSE' ':!docs/redesign-v2/evidence/rd-12/*.log'` 检查代码、内容 JSON 和说明文档。
- 上游原始数据只放 gitignore 缓存；新内容只写根目录 `content/`，不写 `apps/web/public/data/`。
- `origin.forms` 全为空；没有古文字图形、录音、UI 依赖或经济与存档变更。
- 共享工作区已有的 `SeedInstaller.swift` 改动及 `output/` 未跟踪内容不属于本卡，未纳入提交。
