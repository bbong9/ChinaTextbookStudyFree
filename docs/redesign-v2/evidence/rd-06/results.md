# RD-06 验证摘要

验证日期：2026-10-21（Asia/Shanghai）。独立 worktree：`/private/tmp/rd-06-pet-state`；分支：`codex/rd-06-pet-state`。

## 审阅修正与基线

- PR #7 已于 2026-10-21 合并；本分支已 rebase 到 `origin/redesign/v2` 的 `13120ce`，包含 RD-04、最新 README 和统一模拟器脚本规则。
- 网页实际 `useProgressStore` 原样保存并导出八个可选字段：`ownedPets`、`activePet`、`petTreats`、`treatsFromLessonsDate`、`treatsFromLessonsCount`、`petCare`、`petAccessory`、`petsMigrated`。网页不初始化或迁移宠物，不修改经济规则；导入旧备份时清除上一份备份的宠物数据。
- `PetEnvironment` 由 `ProgressStore.activePet`、对应配饰及 `PetCare.mood(for: careState)` 派生，在 `RootView` 统一注入一次。`PetView` 默认继承照顾表情，页面明确指定的庆祝、思考等情境表情继续生效。切换出战、卸下配饰、玩耍及按经过时间衰减均有验证。
- 不修改 `MainShell`、`HomeView`、页面布局、路由、签名、价格、经济数值或黄金向量。

## 本轮实测结果

| 检查 | 结果 |
| --- | --- |
| `npm run check:pet-backup` | 4 项通过，退出 0；测试实际网页 store 的 iOS 备份回环、localStorage 持久化恢复、不透明字段保留、无宠物字段旧档覆盖 |
| `npm test` | 15 个文件、370 个测试全部通过，退出 0；含 TS 黄金向量 221 个、宠物备份 4 个 |
| `npm run type-check --workspace=china-study-free` | 通过，退出 0 |
| `npm run type-check --workspace=@cstf/core` | 通过，退出 0 |
| `xcodegen generate` | 通过；生成工程不提交 |
| 无签名构建 | `BUILD SUCCEEDED`；`CODE_SIGNING_ALLOWED=NO` |
| 宠物及黄金向量专项 | 统一脚本补跑中 `PetStateTests` 23、`PetBackupTests` 4、`PetRendererTests` 6、`GoldenVectorTests` 24，共 57 个、0 失败；该轮总体因下述基线失败退出 65 |
| 统一脚本首次完整 iOS 回归 | 退出 65；17 个 UI 用例为 11 通过、6 失败；另有单元测试宿主启动错误，单元测试未执行，详见下文 |
| 统一脚本补跑 | 264 个单元测试：263 通过、1 个历史 XP 导入断言失败；3 个 UI 用例：1 通过、2 失败；合计 267 个、264 通过、3 失败，退出 65 |
| 当前基线对照 | 纯 `13120ce` 独立 worktree：3 项 UI 为 1 通过、2 失败，退出 65；装扮点击错误和宠物布局断言均与本分支复跑完全一致 |
| 范围检查 | `git diff --check` 通过；codebase_memory 影响检查及人工差异检查确认改动集中于存档、备份、宠物环境接线和验证 |

早期专项 57 个测试在新增统一脚本规则前通过；本轮已由统一脚本补跑全部单元测试，再次覆盖这 57 项且全部通过。原先直接启动的全量测试已为切换规则主动中断（`TEST INTERRUPTED`，退出 75），不作为回归结论。随后所有模拟器测试均通过 `scripts/redesign/sim-test.sh iphone16` 全机排队执行。仅使用已有普通 `iPhone 16` / iOS 18.6（`59BBC4A1-B3F8-4401-8A95-0A3F70AD45E1`），没有创建模拟器或使用 SE / iPad；启动、排队与结束关机均交由脚本。

首次统一脚本调用在开始测试前因本机 Bash 与 `C.UTF-8` 解析中文标点报 `busy…: unbound variable`，没有执行测试。用不涉及模拟器的最小命令已复现；以 `LC_ALL=C` 调用原脚本可正常排队，不修改脚本或绕过全机锁。首次返回的退出码不作为测试通过证据，以实际测试统计为准。

## AC 对照

- **AC1**：`PetStateTests` 覆盖领养成功/余额不足/等级不足/连签账本不足、固定顺序孵化三次与售完、一次发布同时包含扣款和拥有且磁盘快照一致、喂食无饼干、洗澡/玩耍冷却及重启保持、连续时间衰减/下限/频繁打开/时钟回拨、迁移幂等、每日第六块不发及跨日重置、出战和配饰校验、学习只提升出战宠物开心且不改变经济结果、备份导入后的账本/冷却/计时锚点，以及渲染环境随存档变化。
- **AC2**：`pet-backup-ts.json` 由生产 `buildBackup` 生成；iOS 导入并逐项核对。`pet-backup-ios.json` 来自生产 `Backup.makeEnvelope` / `Backup.encode` 的模拟器实际输出，TS `validateBackup` 校验无修复日志。新增 `scripts/checks/pet-backup.ts` 将这份 iOS 样本送入实际网页 store，再经 JSON 导出逐字段深度比较，且验证持久化恢复后仍一致。未知宠物/配饰 id、重复 id、零值、空集合及 `petsMigrated=false` 均原样保留。
- **AC3**：`legacy-progress-eaeff4f.json` 由 `eaeff4f43353cfe7aad4ff1e28ef7aa3f6a1c93d` 的真实旧版本 `CoreTypes.swift` 编译生成，使用合成数据。启动后拥有/出战米团、饼干为 0，`skin_graduate` 迁移为米团配饰，原金币和装扮所有权保留；重复迁移和再次启动不会重新装备已卸下配饰。来源和生成器位于 `ChinaTextbookStudyTests/Fixtures/`。
- **AC4**：两端黄金向量和本卡 57 项测试通过；264 项单元回归仅历史 `PRFixTests` 第 347 行失败。完整 UI 回归和复跑的失败/异常如实记录如下；宠物预览布局已在纯 `13120ce` 基线以相同数值复现。不宣称全量通过，按提示词记录基线例外。

## 统一脚本首次全量的异常

`review-sim-queued-full.log` / `rd-06-review-script-full.xcresult`：退出 65。结果包原始统计为 `totalTestCount=18`、`passedTests=11`、`failedTests=7`；其中 17 个是 UI 用例，另 1 个是单元测试宿主启动错误，不能当成已执行单元测试。

- `ClayGalleryUITests.testReduceMotionStopsGoButton` 和 `CosmeticsUITests.testUnaffordableCosmeticIsNotGranted`：诊断记录为 `Test crashed with signal kill`，runner 重启；不把这次新失败方式直接归为历史基线。
- `PetGalleryUITests.testPetsAccessoriesAndThreeRepeatableReactions`：第 28 行布局断言 `692.4064 > 708.3501` 失败，已通过下述当前基线对照核实。
- 两项 `LessonFlowUITests` 和 `ScreenshotTests.testCaptureMainScreens`：分别在 106、127、36 行断言失败，与历史记录的断言位置一致。
- `ChinaTextbookStudyTests` 宿主在准备运行时被 `signal kill`，没有完成启动；本轮不能据此宣称单元测试通过。Xcode 随后收集模拟器诊断，等待 600 秒后超时。针对性补跑通过统一脚本传入 `-collect-test-diagnostics never`，保留实际测试结果。

## 统一脚本补跑

`review-sim-followup.log` / `rd-06-review-script-followup.xcresult`：退出 65，结果包统计 `totalTestCount=267`、`passedTests=264`、`failedTests=3`。

- 全部 264 项单元测试完成，唯一失败为 `PRFixTests.testImportRestoresTodayXpSoDailyGoalBonusIsNotFarmable` 第 347 行；宠物/渲染/黄金向量 57 项全部通过。
- `ClayGalleryUITests.testReduceMotionStopsGoButton` 通过。
- `CosmeticsUITests.testUnaffordableCosmeticIsNotGranted` 恢复为历史的宇航员按钮 `Activation point invalid` 失败。
- `PetGalleryUITests.testPetsAccessoriesAndThreeRepeatableReactions` 仍在第 28 行以相同数值失败，下述当前基线也复现相同断言。
- 本次未发生单元宿主启动错误或 runner 被 `signal kill`；首次全量的异常原因没有确定，不能仅凭复跑通过抹去原始记录。

## 当前基线 UI 对照

独立 worktree `/private/tmp/rd-06-review-baseline` 的 HEAD 为 `13120ce2cc4c2345b9e23cf9664805b0b606db2d`，已核实无已跟踪文件改动，不包含 RD-06。对照与本分支使用相同脚本、相同 iPhone 16、相同三个 UI 标识和 `-collect-test-diagnostics never`。

`review-sim-baseline.log` / `rd-06-review-baseline.xcresult`：3 项、1 通过、2 失败，退出 65。

| UI 用例 | RD-06 分支补跑 | 纯 `13120ce` 基线 |
| --- | --- | --- |
| Clay 减少动态效果 | 通过 | 通过 |
| 余额不足的装扮点击 | `Activation point invalid` | 相同按钮、相同错误 |
| 宠物表情/配饰/反应预览 | 第 28 行 `692.4063981042655 > 708.3501184834123` 失败 | 同一行、相同数值失败 |

宠物预览布局问题因此属于当前基线，留待基线修复卡处理。本卡没有修改这三个 UI 测试或预览布局。当前和基线的针对性 UI 对照均未再发生 runner 被 `signal kill`；本分支的单元宿主补跑正常，但首次启动/runner 异常的具体原因仍未确定。

## 已有基线记录

初版 PR（基于 `dabb079`、尚未接 RD-04）的完整回归为 256 个单元测试、1 失败，以及 15 个 UI 测试、4 失败，退出 65。失败清单与提示词和仓库 RD-02/RD-05 证据记录对应；本轮未重跑 `eaeff4f`，不能把历史统计当成本轮结果：

- `PRFixTests.testImportRestoresTodayXpSoDailyGoalBonusIsNotFarmable`：`PRFixTests.swift:347`。
- `CosmeticsUITests.testUnaffordableCosmeticIsNotGranted`：宇航员按钮点击位置无效。
- `LessonFlowUITests.testAnsweringShowsFeedbackPanel`：`LessonFlowUITests.swift:106`。
- `LessonFlowUITests.testQuittingMidLessonAsksForConfirmation`：`LessonFlowUITests.swift:127`。
- `ScreenshotTests.testCaptureMainScreens`：`ScreenshotTests.swift:36`。

## 复现命令与本地中间产物

在 worktree 根目录运行：

```sh
npm run check:pet-backup
npm test
npm run type-check --workspace=china-study-free
npm run type-check --workspace=@cstf/core
LC_ALL=C DERIVED_DATA=/private/tmp/rd-06-derived-data scripts/redesign/sim-test.sh iphone16 -resultBundlePath /private/tmp/rd-06-review-script-full.xcresult -jobs 2
```

补跑命令在同一脚本后使用 `-resultBundlePath /private/tmp/rd-06-review-script-followup.xcresult -collect-test-diagnostics never -jobs 2`，并追加 `-only-testing:ChinaTextbookStudyTests` 及三个 `-only-testing:ChinaTextbookStudyUITests/<测试标识>`：`ClayGalleryUITests/testReduceMotionStopsGoButton`、`CosmeticsUITests/testUnaffordableCosmeticIsNotGranted`、`PetGalleryUITests/testPetsAccessoriesAndThreeRepeatableReactions`。基线对照在 `13120ce` 的独立 worktree 使用相同脚本、相同三个 UI 标识及诊断参数，结果路径为 `/private/tmp/rd-06-review-baseline.xcresult`，DerivedData 为 `/private/tmp/rd-06-review-baseline-derived`。

本地中间日志位于 `/private/tmp/rd-06-pet-state/output/rd-06/`，包含网页/core 检查、早期专项及 `review-sim-queued-full.log`、`review-sim-followup.log`、`review-sim-baseline.log`。结果包包括 `/private/tmp/rd-06-review-script-full.xcresult`、`/private/tmp/rd-06-review-script-followup.xcresult`、`/private/tmp/rd-06-review-baseline.xcresult`，切换前专项结果包为 `/private/tmp/rd06-review-focused.xcresult`。以上日志、结果包与 DerivedData 按 README 在推送/合并后清理，不提交；持久证据为本摘要、夹具及测试源码。

## 后续（本卡只记录，不修改）

以下完成路径没有经过 `ProgressStore.completeLesson`，当前未接课程饼干或 `PetCare.completeLesson`；后续需确定哪些活动算一节及奖励防重口径，再统一接入：

- **故事**：`StoryReaderView.bottomAction`（无题故事的读完按钮）和 `resultPhase`（故事测验完成）调用 `completeReading(id:xp:)`；该方法按阅读 id 只奖励首次完成。
- **课文听读与跟读**：`PassageReaderView.completionButton`、`startFollowup` 也调用 `completeReading(id:xp:)`，分别使用听读和跟读奖励 id。
- **错题复习**：`MistakeReviewRunnerView.check` 逐题调用 `reviewMistake` 更新 SRS；整轮 `summary.onAppear` 调用 `awardReviewXP` 和 `claimReviewHeartIfEligible`，没有调用 `completeLesson`。
- **跳级测试**：`JumpTestView.finish` 通过时调用 `applyJumpUnlock` 批量补标前置课程。当前明确不发 XP/金币、不推进连胜或每日任务；是否增加宠物开心、按测试一轮还是补标课数计算需后续决定，不能逐课补发课程奖励。
- **网页玩法**：本次仅透传宠物备份，网页的 `recordLessonComplete`、`completeReading`、`jumpAheadComplete` 和错题复习结算不新增宠物玩法或迁移。
- 卡片「跨 3 天后停在 20」与初始 100、干净/开心每 12 小时减 10 存在算术差异。按明确速率连续衰减并保留小数：从 100 起算三天为 `20/40/40`，从 80 起算三天三项均到 20，均有测试；任何状态不低于 20。
- 本卡没有布局改动，不要求截图；证据属于本地模拟器与合成时间/数据，不代表真机验收。
