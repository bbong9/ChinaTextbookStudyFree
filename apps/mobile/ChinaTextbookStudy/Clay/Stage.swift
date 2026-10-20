import SwiftUI

enum StageAnchor: CaseIterable {
    case topLeading, topTrailing, bottomLeading, bottomTrailing, center
}

/// 所有量均以舞台坐标表示；viewport 和输入安全区是设备点。
struct StageLayout {
    static let designSize = CGSize(width: 844, height: 390)
    let size: CGSize
    let scale: CGFloat
    let safeArea: EdgeInsets
    let designSize: CGSize

    init(viewport: CGSize, safeArea: EdgeInsets, designSize: CGSize = Self.designSize) {
        precondition(designSize.width > 0 && designSize.height > 0)
        self.designSize = designSize
        scale = max(0.001, min(viewport.width / designSize.width, viewport.height / designSize.height))
        size = CGSize(width: viewport.width / scale, height: viewport.height / scale)
        self.safeArea = EdgeInsets(top: safeArea.top / scale, leading: safeArea.leading / scale,
                                   bottom: safeArea.bottom / scale, trailing: safeArea.trailing / scale)
    }

    /// 原始 844×390 场景水平居中、贴底；上方补天空，两侧延伸地面。
    func place(x: CGFloat, y: CGFloat) -> CGPoint {
        CGPoint(x: (size.width - designSize.width) / 2 + x,
                y: size.height - designSize.height + y)
    }

    var minimumTapDimension: CGFloat { max(44, 44 / scale) }

    func anchor(_ anchor: StageAnchor, itemSize: CGSize, inset: CGFloat = 16) -> CGPoint {
        let left = safeArea.leading + inset + itemSize.width / 2
        let right = size.width - safeArea.trailing - inset - itemSize.width / 2
        let top = safeArea.top + inset + itemSize.height / 2
        let bottom = size.height - safeArea.bottom - inset - itemSize.height / 2
        switch anchor {
        case .topLeading: return CGPoint(x: left, y: top)
        case .topTrailing: return CGPoint(x: right, y: top)
        case .bottomLeading: return CGPoint(x: left, y: bottom)
        case .bottomTrailing: return CGPoint(x: right, y: bottom)
        case .center:
            return CGPoint(x: (safeArea.leading + size.width - safeArea.trailing) / 2,
                           y: (safeArea.top + size.height - safeArea.bottom) / 2)
        }
    }
}

private struct ClayStageScaleKey: EnvironmentKey { static let defaultValue: CGFloat = 1 }
extension EnvironmentValues {
    var clayStageScale: CGFloat {
        get { self[ClayStageScaleKey.self] }
        set { self[ClayStageScaleKey.self] = newValue }
    }
}

/// 放在页面根部。外层读取真实安全区，内部画布扩展到屏幕四边。
struct Stage<Background: View, Content: View>: View {
    let designSize: CGSize
    let background: (StageLayout) -> Background
    let content: (StageLayout) -> Content

    init(designSize: CGSize = StageLayout.designSize,
         @ViewBuilder background: @escaping (StageLayout) -> Background,
         @ViewBuilder content: @escaping (StageLayout) -> Content) {
        self.designSize = designSize
        self.background = background
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            let safe = geometry.safeAreaInsets
            let viewport = CGSize(width: geometry.size.width + safe.leading + safe.trailing,
                                  height: geometry.size.height + safe.top + safe.bottom)
            let ctx = StageLayout(viewport: viewport, safeArea: safe, designSize: designSize)
            ZStack(alignment: .topLeading) {
                background(ctx)
                    .frame(width: ctx.size.width, height: ctx.size.height)
                    .scaleEffect(ctx.scale, anchor: .topLeading)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                content(ctx)
                    .frame(width: ctx.size.width, height: ctx.size.height, alignment: .topLeading)
                    .environment(\.clayStageScale, ctx.scale)
                    .scaleEffect(ctx.scale, anchor: .topLeading)
            }
            .frame(width: viewport.width, height: viewport.height, alignment: .topLeading)
            .clipped()
            .offset(x: -safe.leading, y: -safe.top)
        }
        // 清除旧 RootView 的圆体设计覆盖，让打包字体保持自身字形。
        .fontDesign(nil)
    }
}

extension Stage where Background == Color {
    init(designSize: CGSize = StageLayout.designSize,
         @ViewBuilder content: @escaping (StageLayout) -> Content) {
        self.init(designSize: designSize, background: { _ in Color.clear }, content: content)
    }
}

extension View {
    func stageAnchor(_ anchor: StageAnchor, in ctx: StageLayout, size: CGSize, inset: CGFloat = 16) -> some View {
        position(ctx.anchor(anchor, itemSize: size, inset: inset))
    }
}
