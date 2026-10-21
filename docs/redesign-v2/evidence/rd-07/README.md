# RD-07 宠物家族、商店、小屋验收证据

日期：2026-10-21。独立 worktree：`/private/tmp/rd-07-pet-screens`，分支：`codex/rd-07-pet-screens`。
所有截图来自 iOS 18.6 共用模拟器和真实 UI 操作；不代表真机验收。单张截图缩至原始像素的 1/2；对比图和孵化拼图进一步缩放，不引入产品位图素材。
本目录共 32 张 PNG 和一份结果摘要，约 8.94 MiB，低于 10 MB 限额。

## 验收与截图索引

| 标准 | 证据 | 结论 |
| --- | --- | --- |
| AC1 三页与设计稿对比 | `compare-family.png`、`compare-shop.png`、`compare-home.png` | 草地石台图鉴、聚光灯与双层货架、暖色小屋；价格与技能采用 RD-05 目录 |
| AC2 五种商店状态 | `iphone16-state-available.png`、`iphone16-state-insufficient.png`、`iphone16-state-locked.png`、`iphone16-state-owned.png`、`iphone16-state-sold-out.png` | 可领养、还差金币、条件未达、已领养、已孵完 |
| AC3 完整孵化流程与顺序 | `iphone16-egg-storyboard.png`、`iphone16-egg-hatched-1.png`、`iphone16-egg-hatched-2.png` | 三次左右晃动、三道裂纹、破壳、揭晓；小黄鸭 → 噜噜 → 咩咩 |
| AC4 喂食与冷却 | `iphone16-feed-before.png`、`iphone16-feed-after.png`、`iphone16-care-cooldowns.png` | 饼干 3 → 2，饱饱 30 → 55；洗澡和玩耍禁用并实时倒计时 |
| AC5 出战跨页 | `iphone16-adopted-home.png`、`iphone16-switched-home-pending-rd09.png`、`iphone16-switched-course.png`、`iphone16-switched-result.png` | 部分完成，详见下面的范围限制 |
| AC6 领养扣款与可切换列表 | `iphone16-adopted-celebration.png`、`iphone16-adopted-home.png` | 启动参数给 2000 金币；连点领养后余额 1550；阿橘进入小屋列表并可与米团切换 |

三机型三页与未孵出的问号蛋：`iphone16-`、`se-`、`ipad-` 前缀各有 `family.png`、`family-eggs.png`、`shop.png`、`home.png`。
`family.png` 同屏展示彩色米团与去饱和、透明度 0.55 的动物剪影；`family-eggs.png` 展示未孵出伙伴的问号蛋。
已购主题/背景切换见 `iphone16-legacy-owned-settings.png`。

## 数据与流程

- 正式页面的价格、技能、解锁门槛和孵化顺序均来自 RD-05；不改经济、core、存档结构和签名配置。
- 商店下架主题与背景，已有装扮保持生效，设置仅列出已拥有项目供切换；配饰在小屋购买并按宠物佩戴。护盾和补满红心使用原接口、原价格，放在宠物商店底部。
- 领养首次点击即进入处理中；普通宠物按拥有权幂等，蛋按每次确认的 UUID 幂等。余额和拥有权一次发布、一次保存。
- 目录的 10 位包含消耗品神秘蛋。孵出任一蛋系伙伴后把蛋位计为“已发现”，不把消耗蛋写入 `ownedPets`；集齐九只可出战伙伴时图鉴为 10/10。
- 页面时钟集中注入，冷却与台词使用同一个 `now`；照顾特效、孵化、庆祝和宠物循环动画遵从减少动态效果。
- 孵化拼图由 DEBUG 的 `-uitest-egg-steps` 逐帧推进同一阶段枚举截取，正式版本自动播放，固定顺序不随机。

## AC5 范围限制与后续

- 正常选书路径的旧首页没有宠物展示位。本卡提示词禁止修改 `HomeView`，因此首页截图保留真实现状；首页宠物展示及该文件的固定名字文案由 RD-09 接线，AC5 不勾选为全部完成。
- 课程讲解和结算的 `pet-fox` 组件均经过真实完整课程 UI 测试断言。旧结算横屏首幕布局会裁切宠物上半部分，截图如实保留；由 RD-11 调整布局，本卡没有修改 `LessonResultView`。

## 测试结果

全部模拟器测试通过 `scripts/redesign/sim-test.sh` 全机排队执行，使用脚本默认 DerivedData，关闭并行测试和代码签名。
本次 RD-10 rebase 后重跑 iPhone 16 全量；SE 和 iPad 的结果及截图为首轮交付证据，本轮未重跑。

| 设备 | 执行范围 | 结果 |
| --- | --- | --- |
| iPhone 16 / iOS 18.6 | 全量单元测试与 UI 测试 | 315/315 通过（279 单测、36 UI），0 失败 |
| iPhone 16 / iOS 18.6 | rebase 后出战跨页单项回归 | `PetScreensUITests/testSwitchFollowsHomeLessonAndResult` 1/1 通过，0 失败 |
| iPhone SE (3rd gen) / iOS 18.6 | `PetScreensUITests/testCapturePetScreens` | 1/1 通过，0 失败 |
| iPad (A16) / iOS 18.6 | `PetScreensUITests/testCapturePetScreens` | 1/1 通过，0 失败 |

执行命令：

```sh
scripts/redesign/sim-test.sh iphone16 -collect-test-diagnostics never -resultBundlePath /private/tmp/rd-07-rebase-full-fixed.xcresult
scripts/redesign/sim-test.sh iphone16 -only-testing:ChinaTextbookStudyUITests/PetScreensUITests/testSwitchFollowsHomeLessonAndResult -collect-test-diagnostics never -resultBundlePath /private/tmp/rd-07-rebase-switch-fixed.xcresult
scripts/redesign/sim-test.sh se -only-testing:ChinaTextbookStudyUITests/PetScreensUITests/testCapturePetScreens -collect-test-diagnostics never -resultBundlePath /private/tmp/rd-07-se-final.xcresult
scripts/redesign/sim-test.sh ipad -only-testing:ChinaTextbookStudyUITests/PetScreensUITests/testCapturePetScreens -collect-test-diagnostics never -resultBundlePath /private/tmp/rd-07-ipad-final.xcresult
```

关键输出（iPhone 16 全量）：

```text
Test Suite 'ChinaTextbookStudyTests.xctest' passed.
Executed 279 tests, with 0 failures (0 unexpected)
Test Suite 'ChinaTextbookStudyUITests.xctest' passed.
Executed 36 tests, with 0 failures (0 unexpected)
** TEST SUCCEEDED **
```

新增 `PetScreenLogicTests` 6 项覆盖五状态文案、注入时钟冷却、七种台词、成长门槛、孵化阶段和消耗蛋图鉴计数；`PetStateTests` 新增 2 项验证重复领养、重复孵化请求只扣一次。
`PetScreensUITests` 8 项覆盖三页与动作命中区、领养扣款和切换、图鉴导航、照顾及实时冷却、五状态、三次完整孵化、出战跨课程/结算和历史装扮设置。三机型截图用例断言四个照顾按钮可点击，实际命中区均 ≥44pt（容许像素舍入）。

`git diff --check` 和已暂存差异检查通过。已运行 XcodeGen，生成工程不提交。主目录状态与开工快照一致，`SeedInstaller.swift` SHA-256 未变；本卡不改 `packages/core`、经济目录、存档结构、`HomeView`、`LessonResultView` 或签名配置。
集成基线为 `9b89401`（已合并 PR #9 / RD-10）；本次已 fetch、rebase。`codebase_memory.detect_changes` 与 Git 核对本卡源码及测试改动共 23 个文件，另附本目录的截图和结果摘要。

## RD-10 冲突处理

- `IntroCardView.swift` 与 RD-10 完全一致，气泡沿用 `\(pet.kind.name)：\(current.bubble)`。
- `LessonRunnerView.swift` 完整保留 RD-10 布局和注释，只在 `MascotTriggers.pickBubble` 调用中传入出战宠物名；两个文件均无写死的「聪聪」或「米团」文案。
- 出战跨页 UI 用例适配 RD-10 的选项与数字键盘，完成全部 12 题，并检查讲解和每次正确反馈都以「阿橘：」开头。课程截图来自本轮通过的出战跨页单项回归，已同步为 rebase 后的实际页面。
- RD-10 固定回放故意在第 1、4 题答错以验证扣心；本卡回放改用这两题的正确答案（错、B），逐题验证正确反馈，未放宽宠物名断言。
