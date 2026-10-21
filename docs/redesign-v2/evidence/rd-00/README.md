# RD-00 · redesign/v2 基线测试修复

验证日期：2026-10-20 至 2026-10-21。完整前后对照基线为 `13120ce2cc4c2345b9e23cf9664805b0b606db2d`，已含 RD-02、RD-04、RD-05、RD-12。分支 `codex/rd-00-fix-baseline-tests`，PR 目标 `redesign/v2`。独立工作树 `/private/tmp/rd-00-fix-baseline-tests`。

修改六个测试文件、Debug Gallery 的预览重叠 bug 及相关文档。学习流程、经济、存档、core、seed、签名和工程配置无差异，见 `scope-check.json`。主工作区未提交的 `Services/SeedInstaller.swift` 哈希保持一致。

## 根因与修复

| 用例 | 原因 | 修复 |
| --- | --- | --- |
| `PRFixTests.testImportRestoresTodayXpSoDailyGoalBonusIsNotFarmable` | 测试写入固定 2026-08-26，`dailyGoalReached → todayXp` 按真实当天读取。 | 捕获一次 `Date()`，同一个 `today` 注入课程完成、导出、导入及再次完成；保留目标达成和不可重复领奖断言。 |
| `CosmeticsUITests.testUnaffordableCosmeticIsNotGranted` | 宇航员是横向货架第七项，初始 frame `x=790...906`，在 393pt 屏外；`exists` 为真，直接点按无法计算命中点。 | 滚动最内层横向货架，先确认整张卡进入屏幕，再检查命中并点击；仍验证余额不足禁用购买、取消后未装备。 |
| 两个 `LessonFlowUITests` 及 `ScreenshotTests.testCaptureMainScreens` | `99e033a` 更新 seed 后首题正确答案由「对」变「错」；旧测试答错后等不到正确反馈「继续」。 | 按当前 seed 选择「错」；保留反馈、退出确认和后续截图断言。 |
| 新增 `PetGalleryUITests.testPetsAccessoriesAndThreeRepeatableReactions` | 最新 RD-04 预览在默认竖屏构建下，44pt 最小点击区撑高三行按钮；固定 206 舞台点容器将内容居中，按钮 `minY=692.41` 压住信息区 `maxY=708.35`。 | 按三行最小点击区和间距扩展 Debug 宠物页，向上借用天空并同步上移标题；横屏所需高度小于 206 时坐标不变。保留防重叠、点击区和反应回调断言，并在两个用例结束时恢复设备方向。 |
| `LayoutUITests.testProfileReachesAchievementsAndSettings` | RD-12 历史失败附件中设置行 `y=769...847`，与底栏 `y=762...812` 重叠；`isHittable` 提前满足，两次点击均在 `(55.3,839.2)`。 | 在内容 ScrollView 滚动，整行进入导航栏与底栏之间且可命中后再点；删除原地重复点击。 |

已检查 `git log` 和 `git diff 5969787^ 5969787`：该提交修改了退出提示语、选项颜色及底栏布局，没有修改反馈 CTA、商店或个人页。课程失败对应 `99e033a` 的 seed 更新，见 `seed-first-question-history.json`；个人页历史附件的关键行见 `profile-failure-evidence.txt`。

## 前后验证

| 阶段 | iOS 单元测试 | iOS UI 测试 | 合计 | 退出码 |
| --- | --- | --- | --- | --- |
| 干净基线 `13120ce` | 236 通过 / 1 失败 | 12 通过 / 5 失败 | **248 通过 / 6 失败** | 65 |
| 修复后 | 237 通过 / 0 失败 | 17 通过 / 0 失败 | **254 通过 / 0 失败** | 0 |

见 `before-summary.json`、`after-summary.json`。个人页导航本轮基线通过，未把历史偶发失败计入上述六项失败。

两轮全量的用例标识集合完全一致，排序后 SHA-256 见 `test-set-check.json`。均未使用用例筛选、跳过或失败重试；修复后 0 跳过、0 预期失败。

导航专项：同一设备独立重启测试进程 10 次，**10/10 通过**，退出 0，未启用失败重试，见 `profile-repeat-summary.json`。摘要的独立用例计数为 1，设备运行计数为 10。

对照基线的 `npm test`：14 文件、366/366 通过，退出 0，见 `core-131-summary.json`。

宠物预览专项：iPhone SE (3rd gen)、iPhone 16、iPad (A16) 横屏各 **2/2 通过**，0 跳过、0 预期失败，见 `gallery-summary.json`。仅截图专项对 iPhone 传 `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone=UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight`；全量使用基线默认构建，不传方向覆盖。

## RD-06 合入后的最终集成验证

前后对照完成后，`redesign/v2` 合入 RD-06。本分支已同步到 `edda0947d92dca45ebfe072f5e37f070b1fa2cff`，七个修复源码文件 SHA-256 与上述验证逐字一致。重新执行 XcodeGen 后，确认 `PetStateTests`、`PetBackupTests` 和备份 fixtures 已进入生成工程，再用正式队列补跑默认构建全量。

- **281/281 通过**：单元 264，UI 17；退出 0，0 跳过、0 预期失败，见 `final-after-summary.json`。
- 原有 254 个用例标识全部保留，新增 27 项（`PetStateTests`、`PetBackupTests`）全部通过；核对见 `test-set-check.json`。
- `npm test`：**15 文件、370/370 通过**，退出 0，见 `core-summary.json`；core 相对最终集成基线无改动。
- 导航 10/10 和三机型专项来自上面的 `13120ce`；最终集成全量再次通过相同的 17 项 UI 测试。两轮范围和源码哈希见 `scope-check.json`。

最终集成命令与下方全量命令相同，只将产物前缀改为 `/private/tmp/rd00-edda-after`。没有重新运行 `edda094` 修复前全量；原缺陷的前后因果对照使用已完整执行的 `13120ce` 两轮，最终集成结果另列。

## 环境与复现命令

Xcode 27.0（27A266a），既有 iPhone 16 / iOS 18.6（22G86），UDID `59BBC4A1-B3F8-4401-8A95-0A3F70AD45E1`。未配置签名。两轮全量和导航重复均使用仓库全机锁队列，关闭并行测试。

按 README 将 `BundledMedia/audio`、`story-images` 软链接到主目录既有媒体，并在 `apps/mobile` 执行 `xcodegen generate`。未重建 seed 或下载教材。复用与当前锁文件完全相同的主目录 `node_modules` 运行 core 测试。

```sh
LC_ALL=C DERIVED_DATA=/private/tmp/rd00-derived \
  scripts/redesign/sim-test.sh iphone16 \
  -resultBundlePath /private/tmp/rd00-latest-before.xcresult \
  -collect-test-diagnostics never -jobs 2 CODE_SIGNING_REQUIRED=NO \
  > /private/tmp/rd00-latest-before.log 2>&1
```

脚本设置 `CODE_SIGNING_ALLOWED=NO`。修复后只将 `before` 换为 `after`。`-collect-test-diagnostics never` 禁用失败后的整机诊断采集，保留测试断言、结果和附件。

导航专项使用同一入口，增加 `-only-testing:ChinaTextbookStudyUITests/LayoutUITests/testProfileReachesAchievementsAndSettings -test-iterations 10 -test-repetition-relaunch-enabled YES`，结果名为 `rd00-latest-profile-repeat`。专项筛选不影响上述全量运行。

仓库仅提交摘要和必要证据。摘要中的 `.xcresult`、日志路径为采集时路径；按 README 在 PR 推送后清理本任务结果包及中间日志，合并后再清理整个临时工作树。逐项结果、排序用例标识及源文件清单在清理前已导出并核对，摘要保留计数、失败信息、设备和哈希。

## 历史与中断记录

- 初始基线 `eaeff4f`：修复前 212 通过 / 5 失败，修复后 217/217，导航重复 10/10。
- 过渡基线 `dabb079`：修复前 241 通过 / 5 失败，修复后 246/246。首次导航重复 **9/10**；失败发生在首页点按「我的」后，尚未进入设置行。录屏仍为学习页，点击位置在个人页按钮内。当时存在并行模拟器测试和高负载，无法据此确认产品 bug；未增加超时或失败重试，未将该轮记作全绿。
- `f1cbb6b` 的一次运行未取得全机锁，与其他任务共用模拟器发生冲突后主动中止。它属于环境中断，不计入源码基线。此前另有一次编译中断，退出 143，同样未计入。
- 以上历史结果与本轮 `13120ce` 前后对照分列，最终表格只使用正式队列中的完整运行。

Debug Gallery 的三机型横屏截图及 iPhone 16 竖屏前后对照在 `screenshots/`。仅截图专项构建为 iPhone 传入横屏方向覆盖；全量和导航重复使用基线默认方向，未修改 `project.yml`。所有 iOS 结果均为模拟器证据。
