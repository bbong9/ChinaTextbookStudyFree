# 通用要求(RD-08/14/15/16/17/19/20 共用,各卡提示词引用本文件)

## 必读(按顺序)
1. `AGENTS.md`
2. `docs/redesign-v2/README.md`:第 1 节全局规则、第 2 节 PR 模板、第 5 节已拍板事项
3. 本卡的开发卡 `docs/redesign-v2/cards/RD-XX-*.md`(范围和验收标准以它为准)和对应设计稿 PNG
4. 已合并的底座:`packages/core/src/economyV2.ts`(RD-05)、`Domain/EconomyV2.swift`、`Pets.swift`、`Level.swift`;RD-03 场景组件;RD-04 `PetView`;RD-07 的宠物状态。**奖励数字、局数上限一律从 economyV2 取,不要另写一份**

## 工作目录和分支
**在独立 git worktree 里做,不要用主目录**(把 `XX`/`slug` 换成本卡的):
```
git fetch origin
git worktree add -b codex/rd-XX-slug /private/tmp/rd-XX-slug origin/redesign/v2
cd /private/tmp/rd-XX-slug
mkdir -p apps/mobile/BundledMedia
ln -s /Users/bbong9/Desktop/ChinaTextbookStudyFree/apps/mobile/BundledMedia/audio apps/mobile/BundledMedia/audio
ln -s /Users/bbong9/Desktop/ChinaTextbookStudyFree/apps/mobile/BundledMedia/story-images apps/mobile/BundledMedia/story-images
```
软链接目录被 git 忽略,不要提交。PR 目标分支是 `redesign/v2`,**不是 `main`**。

## 模拟器(重要)
- 同一时间全机只允许一个模拟器在跑。**所有模拟器测试一律通过队列脚本**:`scripts/redesign/sim-test.sh iphone16|se|ipad [参数]`(用法见脚本头部注释)。不要自己 `xcrun simctl boot`,不要新建模拟器,不要并行跑 xcodebuild test。
- 只用现有的 iPhone 16 / iPhone SE (3rd generation) / iPad (A16),iOS 18.6。
- DerivedData 用脚本默认的 `/private/tmp/<分支名>-derived`。
- 只做编译和纯逻辑单测时可以不占模拟器队列,但跑 test 就必须排队。

## 存档与备份(几乎每张卡都会碰)
- 新存档字段**全部 Optional**,读取给缺省值;不改现有字段的名字和含义(金币在存档里仍叫 `gems`)。
- `Backup.swift`、`packages/core/src/backup.ts`、`types.ts` 三处同步改,并补往返测试(规则见 README 1.1)。
- 多张卡会并行改这三个文件的同一块区域,**提 PR 前先 `git fetch` 并 rebase `origin/redesign/v2`**,冲突保留双方字段,不要删别人的。
- 经济相关(金币、饼干、XP)只通过 economyV2 的函数,Swift 镜像要有黄金向量测试。

## 学习时长计时(RD-08 提供)
- `StudyTimer` 由 RD-08 实现。如果 `origin/redesign/v2` 里已有,本卡页面按它的用法接入;**如果还没有,不要自己造**,在 PR「后续」里写「计时接入待 RD-08 合并后补」,我会安排小补丁。

## 证据
- 截图和录屏只提交**摘要和压缩后的图**:单张半分辨率,整个 PR 证据 ≤ 10MB;不提交 xcresult、完整 xcodebuild 日志。放在 `docs/redesign-v2/evidence/RD-XX/`。
- 全量测试结果必须 **0 失败**(基线测试已由 RD-00 修好,不再有「已知失败」)。贴出通过/总数。
- 动了 `packages/core` 要跑 `npm test` 和 `npm run type-check --workspace=@cstf/core`,黄金向量两端都要过。
- 收尾时清理自己的 `/private/tmp/rd-XX-*` 缓存;PR 合并后删除 worktree。

## 其他
- 只做本卡范围内的事。范围外的问题写进 PR「后续」,不要顺手改。不碰 `HomeView` / `MapHomeView` / 首页布局。
- **入口接线(已确认,不用再问)**:RD-01 已在 `Navigation.swift` 预留了各新页面的路由(`.animals`、`.mathTrain`、`.bedtimeStories`、`.readingRoom` 等)。本卡**允许**在 `MainShell.swift` 的 `RouteView` 和 `Navigation.swift` 里只改**本卡自己那一个路由分支**(接上新页面、去掉它的临时页头/占位),其他路由和首页不动。
- 新文件后运行 `cd apps/mobile && xcodegen generate`;不提交 `.xcodeproj`。
- **不要配置任何代码签名、Team ID、Bundle ID**,不要问签名的事。编译用 `CODE_SIGNING_ALLOWED=NO`。
- 提交信息、PR 标题和描述都用中文;PR 描述按 README 第 2 节模板,逐条对应 AC,给出证据。卡片写不清或做不到的地方,在 PR「疑问」一节写明处理方式,不要静默改范围。

完成后提交、推送分支,并发起 PR 到 `redesign/v2`。
