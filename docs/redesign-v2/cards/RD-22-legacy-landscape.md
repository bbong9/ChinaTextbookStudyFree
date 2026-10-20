# RD-22 旧页面横屏适配

> 先读 [README](../README.md) 第 1 节全局规则。

**依赖**:RD-01、RD-02 · **不要和 RD-09 并行**(都改 `MainShell.swift` 和导航)

## 目标
RD-01 之后,旧页面在横屏下只保证「能用」。本卡把它们统一换成黏土风格的横屏布局,让整个 App 看起来是同一个产品。**只改外观和布局,不改业务逻辑。**

## 范围
按页面逐个适配。每个页面套用同一个外壳 `ClayPageScaffold`(本卡新建):
- 返回按钮 + 标题缎带;
- 可选的右上角按钮;
- 内容区是舞台内的圆角白卡;
- 背景是对应主题的渐变。

| 页面 | 文件 | 横屏布局 |
| --- | --- | --- |
| 首次引导 | `Features/Onboarding/OnboardingView.swift` | 左边是宠物和说明,右边是选项卡片。年级、教材、每日目标的选择逻辑不变 |
| 选书 | `bookList(grade:)` | 横向书架,一行 4–6 本。科目用颜色区分 |
| 书本详情 | `Features/Book/BookDetailView.swift` | 左边是书封面和统计,右边是单元列表 |
| 单元讲解 | `Features/Guide/UnitGuideView.swift` | 双栏:知识点列表 + 讲解内容 |
| 错题本 | `Features/Review/ReviewView.swift` | 左边按科目筛选,右边是错题卡网格 |
| 成就 | `Features/Achievements/AchievementsView.swift` | 徽章网格,每行 5–6 个 |
| 排行 | `Features/League/LeagueView.swift` | 左边是本周段位和倒计时,右边是榜单 |
| 我的 | `Features/Profile/ProfileView.swift` | 左边是头像、出战宠物、等级;右边是统计卡 |
| 设置 | `Features/Settings/SettingsView.swift` | RD-21 瘦身后剩下的部分 |
| 课文 | `reading(bookId:)` 和 `Features/Reading/PassageReaderView.swift` | 课文列表是横向卡片;读课文页正文居中,最大宽度 640pt,跟读录音按钮在右侧 |

- 已经被新页面替代的不在本卡范围:首页(RD-09)、课程和跳级测试(RD-10)、结算(RD-11)、商店(RD-07)、故事(RD-19)。
- 弹层和 sheet(开始课程弹层、补签、宝箱等)如果不属于以上任何一张卡,也归本卡。开工前先列一张清单,写在 PR 描述里。
- 文字较多的页面(单元讲解、错题本、设置、课文)支持动态字体到 `xxLarge`。

## 不做
- 不改任何数据、经济、存档逻辑。
- 不新增功能。

## 验收标准
- AC1 上表每个页面在 iPhone SE、iPhone 16、iPad 上各一张截图,放进 `evidence/rd-22/`。
- AC2 全局搜索 `DuoColors.`,业务页面里不再出现(只允许在兼容层里)。如果做不到,PR 里列出剩下的位置和原因。
- AC3 现有 UI 测试全部通过。为了新布局改 `accessibilityIdentifier` 时,同步改测试,不能删测试。
- AC4 动态字体 `xxLarge` 下单元讲解和错题本的截图,没有被裁切的文字。

## 审阅重点
- 逐页对比改版前后的功能入口,一个都不能少。PR 里附「改版前 → 改版后」入口对照表。
