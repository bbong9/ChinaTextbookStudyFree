# Clay 基础组件

本目录对应 RD-02。旧页面继续使用 `DesignSystem/Duo*`。

```swift
Stage(background: { ctx in
    ClayGradient.sky.view
}) { ctx in
    Text("山").clayKaiFont(size: 92)
        .position(ctx.place(x: 422, y: 200))
    ClayIconButton(icon: .back, id: "lesson-back") { /* 返回 */ }
        .stageAnchor(.topLeading, in: ctx,
                     size: CGSize(width: max(48, ctx.minimumTapDimension),
                                  height: max(48, ctx.minimumTapDimension)))
}
```

- `StageLayout.size` 是全屏换算后的舞台大小；`safeArea` 已除以缩放比。`place` 的输入是设计稿坐标，场景贴底且水平居中。普通面板可在这个区域内使用 VStack / Grid 等布局。
- Stage 的背景闭包填满扩展后的舞台；前景 HUD 使用 `stageAnchor`。组件从环境读取缩放比，保证缩小后点击区域仍至少 44×44 设备点。
- 每个操作组件都要求稳定的 `id`；图标自动提供中文标签，可用 `label` 覆盖。`StepBar` 的 current / completed / 回调序号均从 **0** 开始。
- `ClayGradient` 的 43 个 `g-*` / `p-*` 保留 SVG 原始名称、色标、透明度和几何参数。`petCream` 对应 `p-cream`，`cream` 对应 `g-cream`；`buttonCream` 对应 CSS 按钮奶油色，两者不能混用。
- SVG 径向渐变使用单位正方形再分别缩放宽高，保留 objectBoundingBox 的椭圆形状。CSS 渐变额外提供 7 项，共 50 项。
- `ClayFont.kai(size:)` 统一决定楷体或 PingFang。需要下载后原地刷新的文本使用 `.clayKaiFont(size:)`，由修饰器观察 `ClayKaiFontStore`；不需要重启，不重建页面状态。
- App 启动时触发一次系统楷体匹配/下载，失败保持 PingFang；下次启动重新尝试。打包字体来源、许可、大小、哈希见 `Resources/Fonts/FONT-SOURCES.md`。
- `GoButton` 读取系统 `accessibilityReduceMotion`；`pausesAnimation` 还能局部暂停，用于 Debug 预览。系统开启减少动态效果时无法被局部恢复。
- Debug 首页右上角头像长按进入 `clayGallery`。底部左右按钮切换组件、渐变、图标与字体三页；右上暂停按钮可验证局部减少动态效果。Release 无此入口和路由。
