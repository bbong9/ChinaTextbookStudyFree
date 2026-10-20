# RD-06 验证摘要

验证日期：2026-10-21（Asia/Shanghai）。开发基线：`dabb079adc1fd2468621fbebf6ab4df877560468`；独立 worktree：`/private/tmp/rd-06-pet-state`；分支：`codex/rd-06-pet-state`。

## 实测结果

| 检查 | 结果 |
| --- | --- |
| `npm test` | 15 个文件、370 个测试全部通过，退出 0；其中 TS 黄金向量 221 个、宠物备份测试 4 个 |
| `npm run type-check --workspace=@cstf/core` | 通过，退出 0 |
| `xcodegen generate` | 通过；未修改工程配置或提交 `.xcodeproj` |
| iPhone 16 / iOS 18.6 无签名构建 | `BUILD SUCCEEDED` |
| `PetStateTests` | 21 个通过，0 失败 |
| `PetBackupTests` | 4 个通过，0 失败 |
| `GoldenVectorTests` | 24 个通过，0 失败 |
| 上述三个套件的独立串行运行 | 共 49 个、0 失败；`TEST SUCCEEDED`，退出 0 |
| 完整单元测试套件 | 256 个，1 个已知失败；新增的 25 个宠物测试全部通过 |
| 完整 UI 测试套件 | 15 个，4 个已知失败；`ClayGalleryUITests`、`LayoutUITests` 全部通过 |
| 完整 `xcodebuild build test` | 已正常结束，退出 65（上述 5 个基线失败）；结果包 `/private/tmp/rd-06-serial-full.xcresult` |
| 范围检查 | `git diff --check` 通过；未修改价格、解锁条件、饼干奖励规则或黄金向量 |

完整回归没有全绿，**与 eaeff4f 基线一致**。失败项及位置：

- `PRFixTests.testImportRestoresTodayXpSoDailyGoalBonusIsNotFarmable`：`PRFixTests.swift:347`，固定历史日期与真实今天的断言。
- `CosmeticsUITests.testUnaffordableCosmeticIsNotGranted`：宇航员装扮按钮的点击位置无效。
- `LessonFlowUITests.testAnsweringShowsFeedbackPanel`：`LessonFlowUITests.swift:106`，反馈面板断言。
- `LessonFlowUITests.testQuittingMidLessonAsksForConfirmation`：`LessonFlowUITests.swift:127`。
- `ScreenshotTests.testCaptureMainScreens`：`ScreenshotTests.swift:36`。

这些失败与 RD-06 提示词的基线例外、既有 `rd-02/tests-baseline-failures.txt` 和 `rd-05/README.md` 记录对应；本次没有另跑 eaeff4f 基线，也没有修改这些测试或对应 UI。AC4 的「原有测试全部通过」仍受这些已知失败限制。

## AC 对照

- **AC1**：`PetStateTests` 覆盖领养成功/余额不足/等级不足/连签账本不足、固定顺序孵化三次与售完、一次发布同时包含扣款和拥有且磁盘快照一致、喂食无饼干、洗澡/玩耍冷却及重启保持、连续时间衰减/下限/频繁打开/时钟回拨、迁移幂等、每日第六块不发及跨日重置、出战和配饰校验、学习只提升出战宠物开心且不改变经济结果、备份导入后的账本/冷却/计时锚点。
- **AC2**：`pet-backup-ts.json` 由生产 `buildBackup` 生成；iOS `PetBackupTests` 导入并逐项核对。`pet-backup-ios.json` 来自模拟器中生产 `Backup.makeEnvelope` / `Backup.encode` 的实际输出，TS `validateBackup` 校验并完整保留八个新增字段。两个夹具均位于 `apps/mobile/ChinaTextbookStudyTests/Fixtures/`；提交的 iOS 夹具与专项测试实际输出按 JSON 对象比较一致。
- **AC3**：`legacy-progress-eaeff4f.json` 使用真实旧版本模型编译生成的合成进度，无真实用户数据。启动后拥有/出战米团、饼干为 0，`skin_graduate` 迁移为米团配饰，原金币和装扮所有权保留；重复迁移和再次启动不会重新装备已卸下配饰。生成器与来源说明同在 `Fixtures/`。
- **AC4**：两端黄金向量和 core 全部通过；完整 iOS 回归仅有上述已知基线失败，未宣称全量通过。

## 命令和本地证据

使用专用设备 `RD-06 iPhone 16`（型号 iPhone 16，iOS 18.6，`163779A8-9CEA-4491-B625-E0B515EF8496`），关闭并行测试，避免与其他卡片的模拟器混用。未配置签名、Team ID 或 Bundle ID。

```sh
npm test
npm run type-check --workspace=@cstf/core
cd apps/mobile && xcodegen generate
```

在仓库根运行的完整 iOS 命令：

```sh
xcodebuild -project apps/mobile/ChinaTextbookStudy.xcodeproj -scheme ChinaTextbookStudy -destination 'platform=iOS Simulator,name=RD-06 iPhone 16,OS=18.6' -derivedDataPath /private/tmp/rd-06-derived-data -resultBundlePath /private/tmp/rd-06-serial-full.xcresult -parallel-testing-enabled NO -jobs 2 CODE_SIGNING_ALLOWED=NO build test
```

独立专项使用相同配置，结果包为 `/private/tmp/rd-06-pet-tests.xcresult`，另加三个 `-only-testing:ChinaTextbookStudyTests/<套件名>` 参数：`PetStateTests`、`PetBackupTests`、`GoldenVectorTests`。

完整日志只留本地，不提交：

- `/private/tmp/rd-06-pet-state/output/rd-06/npm-test.log`
- `/private/tmp/rd-06-pet-state/output/rd-06/type-check.log`
- `/private/tmp/rd-06-pet-state/output/rd-06/xcode-pet-tests.log`
- `/private/tmp/rd-06-pet-state/output/rd-06/xcode-serial-full.log`
- 本地额外导出样本：`/private/tmp/rd-06-pet-state/output/rd-06/ios-pet-backup.json`（未跟踪、不提交；提交的是 `Fixtures/` 中的样本）。

## 范围与后续

- 新存档字段全部 Optional；`gems` 及既有字段含义保持原样。
- 领养在同一份进度副本内扣款、写拥有后仅调用一次 `save()`；未复用先保存扣款的 `spendGems`。
- `Navigation.swift` 仅为 `LessonOutcome` 新增 `treatsGained`；路由、`MainShell`、`HomeView`、宠物页和商店布局均未修改。
- 提 PR 前再次 fetch 后，`origin/redesign/v2` 仍为上述基线，未找到 `PetEnvironment`。**接线待 RD-04 合并后补**；没有创建替代环境对象。
- 卡片「跨 3 天后停在 20」与初始 100、干净/开心每 12 小时减 10 存在算术差异。实现按明确速率连续衰减并保留小数；从 100 起算三天为 `20/40/40`，从 80 起算三天三项均到 20，并有对应测试。任何状态都不会衰减低于 20。
- 本卡没有界面，不要求截图；证据限本地模拟器与合成时间/数据，不代表真机验收。
