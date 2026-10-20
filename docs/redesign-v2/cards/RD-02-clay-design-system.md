# RD-02 黏土设计系统与舞台容器

> 先读 [README](../README.md) 第 1 节全局规则。

**依赖**:无 · **可并行**:RD-01、RD-05、RD-12

## 目标
建一套新的设计令牌和基础组件,后面所有新页面都只用它们。旧的 `DesignSystem/Duo*` 暂时保留给旧页面用,不删除。

## 设计稿
- 参照全部 20 张 png,尤其是 [03-l0](../design/png/03-l0.png)(按钮、步骤条)、[02-map](../design/png/02-map.png)(药丸、描边字、头像)、[09-result](../design/png/09-result.png)(大按钮、缎带)。
- 精确数值以 [design/index.html](../design/index.html) 里的 CSS 为准:`.cbtn`、`.seg`、`.pill`、`.olabel`、`.title-ribbon`、`.btn.cream`、`.btn.orange`、`.bubble`、`.say`、`.go`、`.avatar`。
- 渐变令牌以 [design/art.js](../design/art.js) 的 `DEFS` 为准。

## 范围
新建目录 `apps/mobile/ChinaTextbookStudy/Clay/`。

### 1. 令牌 `ClayTokens.swift`
- **颜色**:
  - 奶油 `#FFFDF6 → #FFF0D3`,奶油边 `#F0D3A2`;
  - 主橙 `#FF8A00`,深橙 `#D66A00`,亮橙 `#FFAE1F`;
  - 墨色 `#3A2A1A`;
  - 深色药丸 `rgba(26,32,44,.78)`;
  - 描边字橙 `#E0700F`;
  - 完成绿点 `#5FC23E`。
- **渐变**:把 `DEFS` 里全部 `g-*` 和 `p-*` 渐变移植成 `ClayGradient` 枚举。线性渐变用 `LinearGradient`;径向渐变用 `RadialGradient`,中心点和半径按 `rg()` 的参数换算。
- **阴影**:`f-sh` 对应 `y:4, radius:4, 颜色 #1D3B53 透明度 .22`。
- **圆角**:按钮 15,小按钮 13,卡片 26–28,药丸用胶囊形。

### 2. 字体 `ClayFont.swift`
- 打包 **ZCOOL KuaiLe**(标题、按钮、步骤条)和 **Nunito 800/900**(数字、拼音)。两者都是 OFL 授权,许可证文件放 `Resources/Fonts/OFL-*.txt`。字体文件总大小 ≤ 8MB,ZCOOL KuaiLe 可以按 GB2312 子集化。
- **楷体**(汉字展示)不打包。优先用系统可下载字体「Kaiti SC」:用 `CTFontDescriptorMatchFontDescriptorsWithProgressHandler` 首次启动后台下载,下载完成前回退到 PingFang SC。要有 `ClayFont.kai(size:)` 的统一入口。
- 角色:`title`(ZCOOL 26)、`button`(ZCOOL 18)、`label`(ZCOOL 14,白字 + 橙色描边)、`number`(Nunito 900 16)、`pinyin`(Nunito 900 26)、`body`(PingFang 16 粗)。

### 3. 组件
| 组件 | 对应 CSS | 说明 |
| --- | --- | --- |
| `ClayIconButton` | `.cbtn` / `.cbtn.sm` | 48×48 / 40×40,奶油渐变,底部 4pt 内阴影边,按下下沉 2pt |
| `ClayButton(style: .cream / .orange)` | `.btn` | 大按钮,高 52 |
| `StepBar(steps:current:completed:onTap:)` | `.seg` | 深色药丸,每格 44×44;当前格橙色字 + 下划线 + 发光,已完成格浅黄字 + 右上角绿点 |
| `StatPill(icon:text:)` | `.pill` | 白色半透明胶囊,高 34 |
| `OutlinedLabel` | `.olabel` | 白字 + 8 方向 2pt 橙色描边 + 下投影。用 8 个偏移的文字叠加实现,不要用 stroke |
| `TitleRibbon(color: .orange / .green / .blue)` | `.title-ribbon` | 页面标题缎带 |
| `SpeechBubble(tail: .left / .right)` | `.bubble` | 白底气泡,带三角尾巴 |
| `SayButton` | `.say` | 橙色朗读胶囊(喇叭 + 可选拼音) |
| `GoButton` | `.go` | 82pt 圆形「闯关」,径向渐变 + 白边 + 呼吸动画 |
| `AvatarBadge` | `.avatar` | 圆形头像框 + 蓝色 Lv 角标 |
| `ClayIcon` | `IC` | back、pause、help、gu(古)、left、right、speaker、mic、redo、play、close、heart、flame、lock。按 `art.js` 的 `IC` 路径移植成 `Shape` |

### 4. 舞台容器 `Stage.swift`
- 按 README 1.2 的规则实现:`Stage(designSize: 844×390) { ctx in … }`。
- `ctx` 提供:
  - 舞台尺寸;
  - 缩放比;
  - 安全区换算后的四个边距;
  - `place(x:y:)`,按设计稿坐标放置。
- 提供 `StageAnchor`:`.topLeading`、`.topTrailing`、`.bottomLeading`、`.bottomTrailing`、`.center`。HUD 按钮用锚点贴边,不写死 x 坐标,这样在 SE 和 Pro Max 上都贴边。
- 背景层用 `.ignoresSafeArea()` 铺满全屏;前景按钮遵守安全区。

### 5. 组件预览页
- 新增 Debug 专用路由 `clayGallery`,只在 `#if DEBUG` 下从首页长按头像进入。
- 页面上把以上所有组件和所有渐变各摆一份,方便审阅对照。

## 不做
- 不改任何业务页面。不删除旧 `Duo*`。

## 验收标准
- AC1 组件预览页在 iPhone 16 上和设计稿对应元素视觉一致:颜色、圆角、内阴影、描边字。附预览页截图和 [03-l0.png](../design/png/03-l0.png) 局部的对比。
- AC2 `StepBar` 三种状态(未到 / 当前 / 已完成)都对,点击回调能拿到步骤序号。
- AC3 `Stage` 在 iPhone SE、iPhone 16、iPhone 16 Pro Max、iPad 四种尺寸下,四角锚点按钮都贴安全区,背景铺满无白边。附 4 张截图。
- AC4 楷体下载流程:首次启动开始下载,下载前显示 PingFang,下载后自动切到楷体,不需要重启。断网时不报错。
- AC5 打包字体有 OFL 许可证文件,`Info.plist` 注册了 `UIAppFonts`(通过 `project.yml`)。
- AC6 减少动态效果打开时,`GoButton` 不呼吸。

## 测试
- 单元测试 `StageLayoutTests`:给 4 组屏幕尺寸和安全区,断言缩放比、舞台尺寸、锚点坐标。

## 审阅重点
- 渐变的色标和中心点是否照 `DEFS` 换算,不要凭感觉取色。
- `OutlinedLabel` 在白色和蓝天背景上都清晰。
