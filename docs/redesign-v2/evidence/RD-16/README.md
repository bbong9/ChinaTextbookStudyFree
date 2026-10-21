# RD-16 幼儿看图识物验收证据

日期：2026-10-21。初始基线：`9fee6e1`；最终 rebase 基线：`origin/redesign/v2` 的 `3e16966`（已含 RD-19）。最终被测源码提交：`e54020d`。独立 worktree：`/private/tmp/rd-16-animals`，分支：`codex/rd-16-animals`。

## 实现与验收对应

| 验收项 | 实现与证据 |
| --- | --- |
| AC1 农场 | 复用 RD-03 草地、栅栏和 RD-04 鸭、猪、羊；谷仓、池塘沿用 `scrAnimals()` 坐标。字卡位于右侧，四分类与三个场景按钮按卡片补入。见三机型 `*-farm-overview.jpg`（全景）与 `*-farm.jpg`（选中羊）。 |
| AC2 分类与场景 | 动物农场、森林、水边；水果果园、交通马路、身体镜子房。见各设备截图矩阵与 `testCaptureCategoriesThreeHabitatsAndAlbum`。 |
| AC3 50 条数据 | [完整词表](word-table.md)，动物 20、水果 10、交通 10、身体 10；7 种既有黏土造型，其余 emoji。PR 描述附整张表，供审阅逐条核对。 |
| AC4 图鉴持久化 | 已见 ID 去重计数，未来 ID 透传；未见条目显示剪影。`testAlbumSurvivesActualProcessRelaunch` 终止 App 后移除测试参数，按正常生产读档再启动；另有真实 `ProgressStore` 重建、Swift/core/Web 双向备份与持久化恢复检查。 |
| AC5 名字与点击区 | 50 个词条逐个检查真实无障碍树中的中文标签、可点击性、至少 64×64 物理点的目标，以及点击后的字卡和计数。汉字至少 72pt、拼音至少 24pt；小屏按 Stage 缩放补偿。 |

所有发现动作只更新 `pictureWordsSeen` 并保存。单测比较发现前后整个 `UserProgress`，除图鉴字段外保持相同，未触发金币、XP、分数或对错反馈。

## 截图

图片由 XCTest 原始屏幕附件宽高各减半，以 JPEG 质量 85 压缩并保留横屏方向信息；单张不得再次当作原始分辨率测量点数。场景与字卡的物理点击尺寸由 UI 测试验证。

| 设备 / iOS 18.6 | 农场 | 森林 | 水边 | 水果 | 交通 | 身体 | 多字字卡 | 图鉴 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| iPhone 16 | [图](iphone16-farm.jpg) | [图](iphone16-forest.jpg) | [图](iphone16-water.jpg) | [图](iphone16-fruit.jpg) | [图](iphone16-transport.jpg) | [图](iphone16-body.jpg) | [图](iphone16-body-card.jpg) | [图](iphone16-album.jpg) |
| iPhone SE 3 | [图](se-farm.jpg) | [图](se-forest.jpg) | [图](se-water.jpg) | [图](se-fruit.jpg) | [图](se-transport.jpg) | [图](se-body.jpg) | [图](se-body-card.jpg) | [图](se-album.jpg) |
| iPad A16 | [图](ipad-farm.jpg) | [图](ipad-forest.jpg) | [图](ipad-water.jpg) | [图](ipad-fruit.jpg) | [图](ipad-transport.jpg) | [图](ipad-body.jpg) | [图](ipad-body-card.jpg) | [图](ipad-album.jpg) |

补充截图：农场全景显示未选中时的谷仓、池塘和栅栏；三字名、长英文用于核对字卡完整显示。

| 设备 | 农场全景 | 猫头鹰字卡 | 草莓字卡 | 50/50 计数 |
| --- | --- | --- | --- | --- |
| iPhone 16 | [图](iphone16-farm-overview.jpg) | [图](iphone16-owl-card.jpg) | [图](iphone16-strawberry-card.jpg) | [图](iphone16-all-fifty-seen.jpg) |
| iPhone SE 3 | [图](se-farm-overview.jpg) | [图](se-owl-card.jpg) | [图](se-strawberry-card.jpg) | [图](se-all-fifty-seen.jpg) |
| iPad A16 | [图](ipad-farm-overview.jpg) | [图](ipad-owl-card.jpg) | [图](ipad-strawberry-card.jpg) | [图](ipad-all-fifty-seen.jpg) |

[真实进程重启后的图鉴](iphone16-relaunched-album.jpg)。

## 备份与音频

- 新字段在 `UserProgress`、Swift `Backup.DataPayload`、core `BackupData` / `UserProgress` 中均为 Optional；Web store 同步导入、导出和 persist。旧档缺失仍为 nil/undefined，空数组保留，字段坏类型忽略，数组内坏类型丢弃，字符串 ID 原样保留。
- `picture-words-ts.json` 由生产 `buildBackup` 生成；iOS 夹具由生产 `Backup.makeEnvelope` / `Backup.encode` 输出。生成方法见测试夹具目录的 README。
- 200 条新音频路径均无录音文件；`SpeechTextIndex` 注册中文名字、普通话读音、拟声或介绍、英文。点击物品按顺序走中文 TTS；英文只由独立喇叭触发。拼音读音映射到对应汉字，避免系统把拼音当英文读。
- 离页、切换分类/场景、打开图鉴和进入后台会停止音频。Reduce Motion 关闭本页单次弹动，`PetView` 自身遵循既有减少动态效果逻辑。

## 范围、差异与后续

- 用户明确授权最小入口连接：`MainShell.swift` 只将已有 `.animals` 分支接到本页；`Navigation.swift` 只取消本页临时页头。其他路由与首页未改。
- “猫头鹰”保留完整常用三字名，是卡片 1–2 字约定的唯一例外；其余 49 条为 1–2 字。七种所需黏土造型全部已存在，没有改宠物渲染器。
- 三机型安全区、64pt 目标和分类按钮需要的空间不同于静态设计稿；字卡与物品做响应式布局，多字卡可滚动，英文按钮放在英文词旁。小屏选中后的字卡会遮住谷仓，另附未选中词条的农场全景，场景元素未删除。
- 楷体复用 RD-02 的 `ClayKaiFontStore`：系统字体未安装或尚在下载时，沿用既有 PingFang 回退，下载完成后自动重绘；截图中可能先显示回退字体。
- iPad 初次截图检查发现图鉴按钮下沿裁到了计数，已修正为大屏至少保留 64 个舞台点的高度；最终三机型截图使用修正后源码重新生成。
- 当前远端未找到 `StudyTimer`：计时接入待 RD-08 合并后补。
- 词表为模型逐条自校，不能代替真人内容审校。已检查无障碍标签和 TTS 兜底路径，尚未进行真人 VoiceOver 听音、真实设备发音或幼儿使用验收；不将模拟器与静态检查表述为这些验收。
- 主目录已有的 `SeedInstaller.swift` 修改及 `output/` 产物保留。本 PR 不包含生成的工程、完整日志或 xcresult。

## 回归过程记录

- 首轮 iPhone 16 完整运行 348/349，`MapHomeUITests.testDailyRewardCloudRestoreAndLeagueOverlays` 等待 `cloud-restore-accept` 20 秒未出现。该轮不是全量通过，也未证实根因。
- 保持首轮 `9fee6e1` 开发基线，在统一队列重跑该单项：1/1、0 失败；云恢复按钮出现且完成每日奖励、云恢复和联赛覆盖流程。未修改首页、RootView 或该测试，不将首次失败武断归为基线缺陷。
- 首轮截图发现单字介绍和多字英文按钮被裁切，已加高单字卡、压缩内边距并调整多字卡横排；截图与完整回归使用修正后的源码重新验证。

## 已完成的跨端与逻辑验证

- 最终 `npm test`：16 个文件，374/374、0 失败，包含 core 黄金向量 221/221。
- `npm run type-check --workspace=@cstf/core` 与 `npm run type-check --workspace=china-study-free` 均退出 0。
- `tsx --tsconfig scripts/checks/tsconfig.json scripts/checks/picture-words-backup.ts`：真实 Web store 的 iOS 回环、持久化恢复、空图鉴、未来 ID、旧档覆盖 5/5。
- 最终 iPhone 16 的 iOS 单元测试 304/304、0 失败，包含 Swift 黄金向量 24/24、本卡 12/12。完整 UI 门禁另以最终完整运行结果为准。
- 提交的 iOS 备份夹具与本轮生产编码输出 `cmp` 相同；完整词表的 ID、汉字、拼音、英文、介绍与生产数据 50/50 逐项一致。
- codebase-memory 按最终源码刷新；`detect_changes` 对比 `3e16966` 返回 21 个代码/测试文件，与 Git 变更清单一致。`discoverPictureWord` 的直接调用仅为 `save()`，另由整个进度比较测试验证没有奖励或其他字段副作用。

- 最终集成源码完整回归：iPhone 16 362/362，0 失败、0 跳过、0 运行时警告；其中单测 304、UI 58，云恢复原失败用例在本次完整运行中通过。最终源码未改首页、RootView 或该测试。

## 最终门禁与复现

正式结果摘录见 [test-results.json](test-results.json)。以下三机型均使用源码提交 `e54020d`，共用 iOS 18.6 模拟器，通过统一队列串行运行，使用默认 DerivedData 与 `CODE_SIGNING_ALLOWED=NO`。

| 验证 | 通过 / 总数 | 失败 | 跳过 | 运行时警告 |
| --- | --- | --- | --- | --- |
| iPhone 16 完整测试（304 单元 + 58 UI） | 362 / 362 | 0 | 0 | 0 |
| iPhone SE 3 分类截图与全部 50 词条 | 2 / 2 | 0 | 0 | 0 |
| iPad A16 分类截图与全部 50 词条 | 2 / 2 | 0 | 0 | 0 |
| core 单测（16 文件） | 374 / 374 | 0 | — | — |

```sh
npm test
npm run type-check --workspace=@cstf/core
npm run type-check --workspace=china-study-free
./node_modules/.bin/tsx --tsconfig scripts/checks/tsconfig.json scripts/checks/picture-words-backup.ts
LC_ALL=C scripts/redesign/sim-test.sh iphone16 -collect-test-diagnostics never
LC_ALL=C scripts/redesign/sim-test.sh se -only-testing:ChinaTextbookStudyUITests/PictureWordsUITests/testCaptureCategoriesThreeHabitatsAndAlbum -only-testing:ChinaTextbookStudyUITests/PictureWordsUITests/testEveryWordHasNamedAccessibleSixtyFourPointTargetAndCanBeCollected -collect-test-diagnostics never
LC_ALL=C scripts/redesign/sim-test.sh ipad -only-testing:ChinaTextbookStudyUITests/PictureWordsUITests/testCaptureCategoriesThreeHabitatsAndAlbum -only-testing:ChinaTextbookStudyUITests/PictureWordsUITests/testEveryWordHasNamedAccessibleSixtyFourPointTargetAndCanBeCollected -collect-test-diagnostics never
```

主目录 `git diff --binary` 和 `git status --porcelain=v1 -z` 的 SHA-256 与开工快照一致，原有改动和未跟踪文件完整保留。完整日志、xcresult、原始附件及构建缓存不进入 PR；本卡只提交这份摘要、词表、结果 JSON 和 37 张半分辨率 JPEG。
