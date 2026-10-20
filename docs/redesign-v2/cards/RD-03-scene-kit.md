# RD-03 场景素材库

> 先读 [README](../README.md) 第 1 节全局规则。

**依赖**:RD-02 · **可并行**:RD-04

## 目标
把设计稿里反复出现的场景元素移植成 SwiftUI 矢量组件,后面每个页面用它们拼背景。

## 设计稿
- 源码:[design/art.js](../design/art.js) 里的 `S` 对象、`smoothPath()`、`cube()`、`DOCK`,以及 [design/screens.js](../design/screens.js) 里的 `meadow()`、`skyBase()`。
- 效果:[02-map](../design/png/02-map.png)、[03-l0](../design/png/03-l0.png)、[13-math](../design/png/13-math.png)、[15-animals](../design/png/15-animals.png)。

## 范围
新建 `Clay/Scene/`。每个元素一个 `View`,参数和 `art.js` 函数参数一一对应(位置、缩放、颜色、状态),坐标在舞台坐标系里。

### 1. 元素清单
| 元素 | art.js | 备注 |
| --- | --- | --- |
| `SkyLayer` | `skyBase` + `g-sunglow` | 天空渐变 + 太阳光晕 |
| `MeadowLayer(horizon:)` | `meadow()` | 远山 + 近坡 + 高光线 + 3 朵云 |
| `CloudView` | `S.cloud` | 支持 `drift` 慢速左右飘 |
| `TreeView` / `BushView` / `FlowerView(color:)` / `TuftView` / `StoneView` / `ShroomView` | 同名 | |
| `MushroomHouseView` | `S.mushHouse` | |
| `CottageView` | `S.cottage` | |
| `TrainView(cars:)` | `S.train` | 车厢可带数字标签(RD-14 用) |
| `FenceView` | `S.fence` | |
| `ChestView(open:)` | `S.chest` | 关 / 开两态 |
| `GiftView` | `S.gift` | |
| `CoinView` / `StarView(on:)` | `S.coin` / `S.star` | 星星有亮 / 灰两态 |
| `ButterflyView` | `S.butterfly` | 扑翅动画 |
| `PathRoad(points:)` | `smoothPath` + 地图里三层描边 | 底层 `#CFC4DE` 宽 48、面层 `#F1ECF7` 宽 42、白色虚线 |
| `CharCube(label:state:stars:)` | `cube()` | 状态:`done`(青色 + 星星)/ `current`(亮白发光)/ `locked`(灰 + 锁)/ `game`(紫色 + 宫格图标)。`label` 可以是汉字(楷体)或数字(Nunito) |
| `DockIcon(kind:)` | `DOCK` | hanzi、math、eng、animal、story、idiom、books、checkin、shop、task、parent、pethouse |

### 2. 动画
- 统一放在 `Clay/Motion.swift`:`bob`(上下浮动)、`drift`(云)、`twinkle`(星星闪)、`flutter`(蝴蝶)、`pulse`(发光)。
- 时长和幅度参照 `index.html` 里同名 `@keyframes`。
- 全部受 `accessibilityReduceMotion` 控制。

### 3. 性能
- 静态背景层(天空、山坡、草丛、花)合成一层,用 `Canvas` 或 `.drawingGroup()` 缓存,不要每帧重算。
- 动画元素(云、蝴蝶、宠物)单独一层。

### 4. 场景样张
- 在 RD-02 的 Debug 组件预览页加一个「场景」分页。
- 用本卡组件**原样拼出** [02-map](../design/png/02-map.png) 的背景:不含 HUD、宠物和字块状态,字块用固定示例数据。

## 不做
- 宠物(RD-04)。业务逻辑。

## 验收标准
- AC1 场景样张在 iPhone 16 上和 02-map.png 的背景并排对比,元素种类、位置、层级、配色一致。附对比图。
- AC2 `CharCube` 四种状态各一张截图,和 02-map.png 中的字块一致。
- AC3 iPhone SE 模拟器上场景样张页滚动/动画无明显掉帧。PR 里附 Xcode 的 FPS 读数或 Instruments 截图,任一即可。
- AC4 减少动态效果打开时,所有循环动画停止。
- AC5 不含任何位图资源。

## 审阅重点
- 路径是否从 `art.js` 照搬(允许整理成 `Path` 构造),而不是重新凭感觉画。
- 组件参数是否足够通用,后面的卡不需要复制粘贴改坐标。
