# RD-01 横屏外壳与路由

> 先读 [README](../README.md) 第 1 节全局规则。

**依赖**:无 · **可并行**:RD-02、RD-05、RD-12

## 目标
App 在 iPhone 和 iPad 上都只用横屏,去掉底部 Tab 栏和 iPad 分栏,改成「首页地图 + 全屏子页面」的结构。这张卡只搭骨架,新页面先放占位,具体界面由后面的卡来做。

## 设计稿
- [02-map.png](../design/png/02-map.png):首页是唯一的根页面。顶部右侧 4 个入口(签到 / 宠物店 / 任务 / 家长),底部 7 个玩法入口,右下角「闯关」。

## 范围
1. `apps/mobile/project.yml`:
   - `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone` 改为 `UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight`;
   - iPad 同样只保留两个横屏方向;
   - 加 `INFOPLIST_KEY_UIRequiresFullScreen: YES`(iPad 不参与分屏,避免出现竖窄窗口);
   - 改完运行 `xcodegen generate`。
2. `App/MainShell.swift`:
   - 删除 compact/regular 两套布局、`BottomTabBar` 和 `NavigationSplitView`;
   - 改成一个 `NavigationStack(path:)`,根页面是首页(本卡先用现有 `HomeView` 占位,RD-09 再替换);
   - 全部页面隐藏系统导航栏,返回按钮由各页面自己画(RD-02 的奶油返回按钮)。
3. `App/Navigation.swift`:新增以下路由,本卡先接一个占位页(标题 + 返回按钮 + 「建设中」),后续卡片替换:
   `petFamily`、`petHome`、`petShop`、`checkIn`、`quests`、`parentCenter`、`hanziMap(bookId:)`、`hanziLesson(bookId:char:)`、`mathTrain`、`englishBalloons`、`animals`、`idiomPicker`、`idiomPlayer(id:)`、`bedtimeStories`、`readingRoom`
4. 原来 Tab 栏里的「排行 / 错题本 / 商店 / 我的」和 iPad 侧栏的「成就墙 / 按年级」必须仍然能进:
   - 本卡在占位首页上放一排临时按钮通到这些页面;
   - RD-09 会把它们收进头像菜单和「任务」面板。
5. 首次引导完成后自动进第一课的逻辑(`startFirstLessonAfterOnboarding`)和 toast 保留,行为不变。
6. 删除 `Components/BottomTabBar.swift` 以及只服务于 Tab 栏的代码。`AppTab` 若还有别处使用,改为不再依赖它。

## 不做
- 不改任何页面的视觉,这是 RD-09 / RD-22 的事。
- 旧页面在横屏下排版难看可以接受,但**不能出现内容被裁切到点不到、按钮被遮住、崩溃**。

## 验收标准
- AC1 iPhone 和 iPad 模拟器上 App 只能横屏显示,旋转设备不会变成竖屏。
- AC2 首页没有底部 Tab 栏;iPad 没有侧栏。
- AC3 第 3 步列出的 15 个新路由都能从临时入口打开,并能返回。
- AC4 排行、错题本、商店、我的、成就墙、换年级/换书,横屏下都能打开,核心操作能点到(各附一张 iPhone SE 截图)。
- AC5 新用户走完引导后仍然自动进第一课。
- AC6 原有单元测试全部通过。`LayoutUITests` / `ScreenshotTests` 里依赖竖屏或 Tab 栏的用例:更新为横屏;无法更新的标 `XCTSkip("RD-23 重写")` 并在 PR 里列出。

## 测试
- 新增 UI 测试 `ShellUITests`:启动后断言横屏(窗口宽 > 高)、不存在 Tab 栏标识、能进入任意 3 个新路由并返回。

## 审阅重点
- `project.yml` 是否真的只剩横屏方向,`xcodeproj` 有没有误提交。
- 删掉 Tab 栏后,原来挂在 Tab 切换上的逻辑(切换时清空路由栈 `path.removeAll()`)是否有遗漏的副作用。
