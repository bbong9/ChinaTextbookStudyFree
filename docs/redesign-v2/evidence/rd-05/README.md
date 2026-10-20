# RD-05 验证记录

日期：2026-10-20。开发基线：`eaeff4f43353cfe7aad4ff1e28ef7aa3f6a1c93d`，分支：`codex/rd-05-core-economy`。本卡在 `/private/tmp/rd-05-core-economy` 独立 worktree 完成，未纳入其他并行卡片的改动。

| 检查 | 实测结果 | 证据 |
| --- | --- | --- |
| `TZ=Asia/Shanghai npm test` | 13 个文件、364 项通过；黄金向量文件 221 项；退出码 0 | `npm-test.txt` |
| 根目录 `npm run type-check` | Web、core 均通过，退出码 0 | `type-check.txt` |
| `xcodegen generate` | 通过；工程配置未修改，生成物未提交 | `scope-check.txt` |
| iPhone 16 / iOS 18.6 无签名构建 | 日志出现 `BUILD SUCCEEDED` | `ios-full-regression.txt` |
| 独立运行 `GoldenVectorTests` | 24 项通过，0 失败、0 跳过；`TEST EXECUTE SUCCEEDED`，退出码 0 | `ios-golden-vectors.txt` |
| iOS 全量回归 | 215 项单测中 1 项失败；13 项 UI 测试中 4 项失败；未达到全量通过门禁 | `ios-full-regression.txt` |
| 干净基线定向复现 | 固定日期的原有单测 1 项、1 失败，同一断言复现；进程退出码 73 | `baseline-unit.txt` |
| 范围检查 | 仅本卡代码、向量与证据；存档、备份、旧经济、工程配置、原 UI/回归测试与基线一致 | `scope-check.txt` |
| 收入估算 | 首周常规 822 金币，含首次 3/7 天里程碑 932；阿橘约 4–5 天可得 | `income-estimate.md` |

两端共同读取 `packages/core/spec/golden-vectors.json`；Swift 通过 `#filePath` 定位该文件，没有额外拷贝。新增九组及子组均有非空检查，覆盖等级边界/99 级之后、宠物全部目录与解锁、蛋集齐下架、课程第 6 块饼干、签到跨周期、三个宝箱档位、小游戏第 4 局及周末 XP、重复观看、识字 0–6 题、阅读本地午夜/周界/跨年。

| 分组 | 向量数（含目录条目） |
| --- | --- |
| level | 15 |
| pets | 目录 10、解锁 24、孵化 7 |
| lessonTreats | 8 |
| checkInCycle | 周期 12、周期日奖励 10 |
| studyChests | 目录 3、领取 10 |
| miniGame | 12 |
| idiomWatch | 2 |
| hanziXp | 10 |
| readingLog | 每日 6、每周 11 |

全量回归未通过项：

1. `PRFixTests.testImportRestoresTodayXpSoDailyGoalBonusIsNotFarmable`，`PRFixTests.swift:347`。该测试写入固定的 `2026-08-26`，再调用按真实今天读取的 `dailyGoalReached`；运行日是 `2026-10-20`。在干净基线 `eaeff4f` 定向运行后复现同一断言失败，相关源文件逐字节一致。
2. `CosmeticsUITests.testUnaffordableCosmeticIsNotGranted`：宇航员按钮无法计算有效点击位置。
3. `LessonFlowUITests.testAnsweringShowsFeedbackPanel`，`LessonFlowUITests.swift:106`：未找到「继续」按钮。
4. `LessonFlowUITests.testQuittingMidLessonAsksForConfirmation`，`LessonFlowUITests.swift:127`：未找到「继续」按钮。
5. `ScreenshotTests.testCaptureMainScreens`，`ScreenshotTests.swift:36`：断言失败，课程反馈步骤未完成。

后四项为原有 UI 用例失败，未完成基线 UI 复现，不能据此宣称它们已被基线证实。原 UI、相关存储代码和这些测试未改动；后续由相应卡片处理，本卡保留失败证据并以草稿 PR 交付。

验证环境与尝试记录：

- 本机 Xcode 的 `OS:latest` 是 iOS 27，但现有 iPhone 16 使用 iOS 18.6。原命令按名称选择设备时退出 70；最终创建本卡专用 iPhone 16/iOS 18.6，并按设备 ID 选择。
- 首次完整媒体构建在复制约 2 GB 的既有媒体时报告 `database or disk is full`。最终在本卡 worktree 内使用空的可选 `BundledMedia/audio`、`BundledMedia/story-images` 目录，保留原 seed 数据和全部测试；原媒体未改动。没有配置代码签名、Team ID 或 Bundle ID。
- 全量用例完成后 Xcode 长时间停留于 `Finalize test log`，本卡终止该收尾进程，最终退出 143；全量 `.xcresult` 未封口，不能作为有效结果包。`ios-full-regression.txt` 保存原始输出中的用例/套件状态和失败断言，不把进程终止解释为通过。
- 黄金向量在同一台已启动设备上串行单独执行，复用上述已编译产物，成功退出 0。完整命令和原始输出见 `ios-golden-vectors.txt`，本机有效结果包为 `/private/tmp/rd05-golden-tests.xcresult`。
- 基线首次包含 UI 的定向尝试遇到模拟器启动 `NSMachErrorDomain -308`，停止等待后改用同一台暖机设备仅跑基线单测。`baseline-unit.txt` 保留实际复现结果；基线 UI 未获得结果。

本卡无界面改动，不要求三机截图；这些证据属于本地模拟器验证，不代表真机或发布验收。
