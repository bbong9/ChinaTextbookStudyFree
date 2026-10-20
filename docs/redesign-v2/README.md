# 课本乐园 v2 · iOS 改版开发卡

这批卡片把 `design/` 里的横屏黏土风设计稿落到 iOS App(`apps/mobile`)。
**开发:Codex。审阅:Claude。** 每张卡一个分支、一个 PR,审阅通过才合并。

- 设计稿(可交互):[design/index.html](design/index.html),双击打开,需联网加载字体
- 设计稿(静态图,2x):[design/png/](design/png/),文件名 `NN-<屏幕id>.png`,卡片里用屏幕 id 引用
- 单屏渲染:`design/shot.html?id=<屏幕id>`,画布 844×390,和 png 一致

---

## 0. 开工前(只做一次)

1. ✅ `ui/iphone-polish` 上的未提交改动(TTS 兜底、`SpeechTextIndex.swift`、seed 包等)已提交。
2. ✅ 已从 `ui/iphone-polish` 切出集成分支 `redesign/v2`(本目录也在这个分支里)。
3. 每张卡从 `redesign/v2` 切 `codex/rd-XX-<slug>`,PR 目标分支是 `redesign/v2`,**不是 `main`**。
4. 工程由 XcodeGen 生成,`*.xcodeproj` 不进 Git。改工程配置只改 `apps/mobile/project.yml`,然后 `cd apps/mobile && xcodegen generate`。

## 1. 全局规则(每张卡都适用,审阅时逐条检查)

### 1.1 经济与存档
- **经济黄金向量规则不变**:`Domain/Economy.swift` 是 `packages/core/src/economy.ts` 的镜像。任何数值或规则的增改,必须**同时**改 core、Swift 和 `packages/core/spec/golden-vectors.json`,两端测试都要过(`npm test`、`GoldenVectorTests`)。新经济规则一律先进 core,不允许只写在 Swift 里。
- `UserProgress` 新字段一律 **Optional**,老存档能直接解码。存档备份要两端兼容:改 `Domain/Backup.swift` 的同时改 `packages/core/src/backup.ts`,保证 iOS 导出的备份 Web 能读,反过来也一样。
- 只有一种货币,存档字段仍叫 `gems`。新 UI 一律显示为「金币」并用金币图标(D2 已定)。
- 不加任何真钱购买、广告、外链跳转、账号体系。

### 1.2 界面
- **只做横屏**(iPhone);iPad 用同一套横屏界面。见 RD-01。
- **舞台坐标**:设计稿坐标是 844×390 的「舞台」。实现用统一的 `Stage` 容器(RD-02):
  - 缩放 `s = min(可用宽/844, 可用高/390)`;
  - 舞台尺寸 `(宽/s, 高/s)`,场景贴底,多出的高度补天空,多出的宽度向两侧延伸地面;
  - HUD 按钮贴安全区边缘,场景背景铺满全屏(忽略安全区)。
- **文字较多的面板**(家长中心、书单、设置)在舞台区域内用普通 SwiftUI 布局,并支持动态字体到 `xxLarge`。游戏场景内的文字可以不跟随动态字体。
- 所有插画用 SwiftUI 矢量绘制(Shape / Canvas / 渐变),**不引入位图插画**,不引入第三方 UI 依赖。新增 SPM 依赖必须先在 PR 里说明理由,审阅同意后才能加。
- `accessibilityReduceMotion` 打开时,停止所有循环动画(上下浮动、云飘、闪烁),只保留必要的状态切换。
- 点击区域 ≥ 44×44pt;每个可点元素有中文 `accessibilityLabel` 和稳定的 `accessibilityIdentifier`(UI 测试用)。
- 颜色、字号、圆角、阴影只从 RD-02 的设计令牌取,不在业务页面里写裸色值。

### 1.3 内容与版权
- **新内容放哪里**:现有课程数据 `apps/web/public/data/` 是从 Release 下载的,已被 gitignore,**不要往里写新内容**。本次新增的手写内容(汉字包、英语词表、成语剧本、书单、故事拼音)一律放仓库根目录的 `content/`(纳入 git),由 `scripts/build-seed-zip.sh` 复制进 seed 包的 `data/` 下。卡片里写的 `content/...` 路径都指这里。
- **新录音**:`scripts/tts/` 生成的音频落在 `apps/web/public/audio/`(同样不进 git),要跟下一次资源 Release 一起发布。所以**每个用到新录音的功能都必须在没有录音文件时用系统 TTS 正常工作**,PR 里要演示无录音的情况。
- 不复制参考 App 的任何素材。设计稿是自己画的,可以照着移植。
- 古文字字形、笔顺数据、书目封面等任何第三方内容,必须在数据里带 `source` 和 `license` 字段;来源不清的内容不进包。
- 不做假评分:没有真实语音评测时,「说」只算完成跟读,不显示「发音准确率」之类的数字。

### 1.4 质量
- 单元测试放 `ChinaTextbookStudyTests/`,UI 测试放 `ChinaTextbookStudyUITests/`。纯逻辑(经济、等级、宠物状态、计时、题目生成、笔画判定)必须有单元测试。
- 每个 PR 必须能在模拟器编译通过,并且原有测试全部通过。
- 截图证据:每个涉及界面的 PR,附以下三个模拟器的横屏截图:**iPhone SE (3rd gen)**、**iPhone 16**、**iPad (A16)**。放在 `docs/redesign-v2/evidence/rd-XX/`。
- 证据只提交截图和结果摘要(测试名、通过数、关键输出几行),完整 xcodebuild / 测试日志留在本地,不要提交。
- 每张卡在独立的 git worktree 里开发,不要用主目录。`apps/mobile/BundledMedia/audio`、`story-images` 被 gitignore,新 worktree 里从主目录软链接过来(不提交)。
- 已知基线失败(PRFixTests、CosmeticsUITests、LessonFlowUITests、ScreenshotTests、LayoutUITests,在 eaeff4f 上可复现)等 RD-00 修复;在此之前 PR 注明「与基线一致」即可,但新增或换了失败方式的要说明。

## 2. PR 模板(Codex 每个 PR 必须照填)

```
## RD-XX <卡片标题>
### 做了什么
- …
### 验收标准逐条对照
- [x] AC1 … 证据:截图/测试名/命令输出
- [ ] AC2 … 没做到的原因
### 和卡片/设计稿不一致的地方
- …(没有就写「无」)
### 测试
- `xcodebuild test …` 结果:N 个测试,0 失败
- `npm test`(动了 core 时)结果
### 截图
- docs/redesign-v2/evidence/rd-XX/…
```

## 3. 审阅流程(Claude 怎么审)

1. 先看 PR 描述:每条验收标准都要有证据,没证据按「未完成」处理。
2. 拉分支本地编译、跑测试;动了 core 的卡同时跑 `npm test`。
3. 截图和 `design/png/` 对照:布局、层级、颜色令牌、文字。像素级差异不卡,结构性偏差要改。
4. 检查第 1 节的全局规则,尤其是经济镜像、存档兼容、无障碍标识、减少动态效果。
5. 审阅结论写在 PR 里:**通过** / **要改**(编号列出,每条写清楚改哪里、为什么)。要改的,Codex 改完在同一个 PR 追加提交,不另开 PR。
6. 审阅结论同步到下面的状态表。

## 4. 卡片总表与依赖

| 卡 | 标题 | 依赖 | 状态 |
| --- | --- | --- | --- |
| **A 地基** | | | |
| [RD-01](cards/RD-01-landscape-shell.md) | 横屏外壳与路由 | — | 开发中(PR #4) |
| [RD-02](cards/RD-02-clay-design-system.md) | 黏土设计系统与舞台容器 | — | ✅ 已合并(PR #3) |
| [RD-03](cards/RD-03-scene-kit.md) | 场景素材库 | RD-02 | 可开工 |
| [RD-04](cards/RD-04-pet-renderer.md) | 宠物渲染组件,替换熊猫 | RD-02 | 可开工 |
| **B 经济与宠物** | | | |
| [RD-05](cards/RD-05-core-economy.md) | core 经济扩展(等级/宠物/饼干/时长宝箱/小游戏奖励) | — | ✅ 已合并(PR #2) |
| [RD-06](cards/RD-06-pet-state.md) | 宠物存档与状态 | RD-05 | 可开工 |
| [RD-07](cards/RD-07-pet-screens.md) | 宠物家族、商店、小屋 | RD-03 RD-04 RD-06 | 待开发 |
| [RD-08](cards/RD-08-checkin-study-time.md) | 签到与学习时长宝箱 | RD-03 RD-05 RD-06 | 待开发 |
| **C 主线闯关** | | | |
| [RD-09](cards/RD-09-home-map.md) | 首页闯关地图 | RD-01 RD-03 RD-04 RD-05 | 待开发 |
| [RD-10](cards/RD-10-lesson-shell.md) | 课本关卡横屏改版(8 种题型) | RD-02 RD-03 RD-04 | 待开发 |
| [RD-11](cards/RD-11-result.md) | 闯关结算 | RD-05 RD-06 RD-10 | 待开发 |
| [RD-12](cards/RD-12-hanzi-content.md) | 汉字内容包与数据管线 | — | ✅ 已合并(PR #1) |
| [RD-13](cards/RD-13-hanzi-five-steps.md) | 识字五步关卡(玩认练写说 + 字源卡) | RD-09 RD-11 RD-12 | 待开发 |
| **D 游戏与内容** | | | |
| [RD-14](cards/RD-14-math-train.md) | 数学小火车 | RD-03 RD-05 | 待开发 |
| [RD-15](cards/RD-15-english-balloons.md) | 英语单词气球 | RD-03 RD-05 | 待开发 |
| [RD-16](cards/RD-16-animals.md) | 幼儿看图识物 | RD-03 RD-04 | 待开发 |
| [RD-17](cards/RD-17-idiom-player.md) | 成语动画:播放器 + 守株待兔 | RD-03 RD-05 | 待开发 |
| [RD-18](cards/RD-18-idiom-picker.md) | 成语动画:选择转盘 + 另外两个成语 | RD-17 | 待开发 |
| [RD-19](cards/RD-19-bedtime-story.md) | 睡前绘本 | RD-03 | 待开发 |
| [RD-20](cards/RD-20-reading-room.md) | 课外书屋 | RD-03 RD-05 | 待开发 |
| **E 家长与收尾** | | | |
| [RD-21](cards/RD-21-parent-center.md) | 家长中心与家长门 | RD-02 RD-08 | 待开发 |
| [RD-22](cards/RD-22-legacy-landscape.md) | 旧页面横屏适配 | RD-01 RD-02 | 待开发 |
| [RD-23](cards/RD-23-release-gate.md) | 发版验收:截图测试、性能、无签名 ipa | 全部 | 待开发 |

**可以并行的组合**:RD-01、RD-02、RD-05、RD-12 互不依赖,可以同时开工。RD-02 合并后,RD-03 和 RD-04 可以并行。同一时间改同一批文件的卡不要并行(比如 RD-09 和 RD-22 都动 `MainShell.swift`)。

## 5. 已拍板(2026-10-20 定稿,按审阅者建议执行)

| # | 问题 | 结论 | 影响的卡 |
| --- | --- | --- | --- |
| D1 | 宠物价格。设计稿是 1200/1500/2000/800,按现在的收入(正常学一天约 70–90 金币)要攒 2–4 周 | **定**:450 / 600 / 800 / 300(阿橘/奶糖/冰冰/神秘蛋) | RD-05 |
| D2 | 「宝石」改叫「金币」 | **定**:改。只改 iOS 显示文字和图标,存档字段 `gems` 不变 | RD-05 RD-07 |
| D3 | 设计稿里奶糖的技能「识字闯关 +10% 金币」、博博的「读书挑战双倍经验」会让两端经济不一致 | **定**:宠物技能只给不影响经济的效果(多一次提示、专属台词),见 RD-05 | RD-05 |
| D4 | 神秘蛋「随机孵化」是给孩子的抽卡 | **定**:不随机,固定顺序孵出小黄鸭 → 噜噜 → 咩咩 | RD-05 RD-06 |
| D5 | 笔顺数据来源。最现成的是 Make Me a Hanzi,图形数据是 Arphic Public License(带传染条款) | **定**:接受 APL。笔顺数据单独放 `content/hanzi/strokes/`,附 APL 全文,数据本身按 APL 分发;App 代码仍是 MIT。做法同 Hanzi Writer(代码 MIT,`hanzi-writer-data` 按 APL)。「关于」页列出来源 | RD-12 RD-13 |
| D6 | 古文字字形(甲骨文/金文/小篆)没有现成的可用授权数据 | **定**:第一版不放古文字字形,字源卡只显示楷书 + 文字讲解 | RD-12 RD-13 |
| D7 | 课外书屋只能放书名和自写导读,不能放正文和真实封面 | **定**:只放书名和自写导读,书单用统编版「快乐读书吧」书目 | RD-20 |
| D8 | 主题、背景两类装扮和宠物商店定位重叠 | **定**:商店下架主题和背景,已拥有的继续可用;熊猫皮肤迁移成宠物配饰(RD-06),不退款也不作废 | RD-06 RD-07 |
