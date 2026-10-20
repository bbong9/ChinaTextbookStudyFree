# RD-04 宠物渲染组件,替换熊猫

> 先读 [README](../README.md) 第 1 节全局规则。

**依赖**:RD-02 · **可并行**:RD-03

## 目标
用新的黏土风宠物替换熊猫聪聪 `MascotView`。宠物的表情、反应和配饰沿用现有接口的含义,全 App 统一换掉。

## 设计稿
- [01-pets.png](../design/png/01-pets.png):7 只宠物的造型。
- 源码:[design/art.js](../design/art.js) 的 `PET_ART`,共 10 种:mituan、fox、cat、penguin、owl、dragon、egg、duck、pig、sheep;以及 `eyes`、`blush`、`mouth`、`spec`、`shadow`、`feet` 这些通用部件。

## 范围
### 1. `PetKind` 枚举
10 种,对应 `PET_ART` 的键。中文名:米团、阿橘、奶糖、冰冰、博博、云宝、神秘蛋、小黄鸭、噜噜、咩咩。

### 2. `PetView(kind:mood:size:reactTo:accessory:)`
- 照 `PET_ART` 移植,画布 120×130,`size` 是宽。
- `mood` 复用现有 `MascotMood`(happy、cheer、sad、think、wave、surprise、proud、embarrassed)。至少要把眼睛和嘴巴做出区别:
  - happy / cheer / proud:眯眼笑;
  - sad / embarrassed:八字眉 + 小嘴;
  - think:眼睛看一侧;
  - surprise:圆眼 + O 形嘴;
  - wave:happy 的样子再加挥手。
- `reactTo` 复用 `MascotReaction`:
  - correct:跳一下;
  - wrong:左右轻摇;
  - levelup:跳 + 旋转一圈。
- 常驻动画:呼吸缩放 + 眨眼,和现在 `MascotView` 一样。受减少动态效果控制。
- 米团有第二形态「开花」(头顶新芽变成小花),参数 `bloom: Bool`。
- 神秘蛋有「裂纹」参数 `crack: 0...3`,孵化动画要用(RD-07)。

### 3. 配饰
- 现有 12 个熊猫皮肤里,除 `skin_default`(原版聪聪)之外的 11 个是头饰或脸饰:学士帽、圆框眼镜、派对帽、皇冠、法师帽、宇航员头盔、墨镜、海盗帽、耳机、桂冠、领结。把它们改成**宠物配饰**:
  - 每种宠物定义锚点(头顶中心、眼睛中线、脖子),配饰按锚点和缩放画上去;
  - 配饰图形可以从 `MascotView.drawAccessory` 移植,再按新造型调整。

### 4. 替换
- 以下 16 个文件里的 `MascotView` 全部换成 `PetView`,宠物种类取「当前出战宠物」:App/MainShell、Features/Shop/ShopView、Features/Review/MistakeReviewRunnerView、Features/Settings/SettingsView、Features/Home/HomeView、Features/Guide/UnitGuideView、Features/League/LeagueView、Features/Profile/ProfileView、Features/Lesson/LessonRunnerView、Features/Lesson/IntroCardView、Features/Onboarding/OnboardingView、Features/Stories/StoryReaderView、Features/Jump/JumpTestView、Features/Review/ReviewView、Features/Lesson/LessonResultView、Components/ShareCardView。
- 本卡还没有宠物存档(RD-06),先用一个临时的 `PetEnvironment` 环境值,默认 `.mituan`。RD-06 接上存档。
- 删除 `Components/MascotView.swift`。文案里的「聪聪」暂时改为「米团」(RD-07 再改成随出战宠物变化)。

## 不做
- 宠物购买、喂养、存档(RD-06、RD-07)。

## 验收标准
- AC1 Debug 预览页新增「宠物」分页:10 种宠物 × 8 种表情的网格,外加米团开花形态、神秘蛋 0–3 裂纹。截图和 01-pets.png 对比,造型一致。
- AC2 11 种配饰在米团、阿橘、冰冰三只宠物上各截一张图,位置正确,不穿模、不歪。
- AC3 全工程搜索不到 `MascotView`。原来出现熊猫的页面都显示米团,答对、答错、升级三种反应能触发。
- AC4 减少动态效果打开时没有呼吸和眨眼以外的循环动画。眨眼可以保留。
- AC5 原有测试通过。依赖「聪聪」文案的 UI 测试已同步更新。

## 审阅重点
- 造型照 `PET_ART` 的路径和渐变,特别是高光 `spec` 和腮红,这是「黏土感」的关键。
- 配饰锚点是数据驱动的(每种宠物一组参数),不是每种宠物 × 每个配饰写一遍。
