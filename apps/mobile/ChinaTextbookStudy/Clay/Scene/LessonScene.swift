import SwiftUI

/// 课本场景只由教材决定，同一节课不会随题目、旧背景装扮或答题状态切换。
struct LessonScene: View {
    let bookId: String

    enum Kind { case math, chinese, english, science }
    static func kind(for bookId: String) -> Kind {
        if bookId.hasPrefix("chinese-") { return .chinese }
        if bookId.hasPrefix("english-") { return .english }
        if bookId.hasPrefix("science-") { return .science }
        return .math
    }

    var body: some View {
        GeometryReader { geometry in
            let origin = CGPoint(x: (geometry.size.width - 844) / 2, y: geometry.size.height - 390)
            ZStack(alignment: .topLeading) {
                if Self.kind(for: bookId) == .english {
                    SkyLayer()
                } else {
                    MeadowLayer(horizon: 270)
                }
                decorations.frame(width: 844, height: 390).offset(x: origin.x, y: origin.y)
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder private var decorations: some View {
        switch Self.kind(for: bookId) {
        case .math:
            TrainView(x: 790, y: 273, scale: 0.36, cars: [.init(), .init(gradient: .green2)])
            BushView(x: 40, y: 364, scale: 0.7)
            FlowerView(x: 810, y: 374, color: ClayColor.flameCore)
        case .chinese:
            CottageView(x: 790, y: 342, scale: 0.55)
            TreeView(x: 26, y: 350, scale: 0.7)
            FlowerView(x: 460, y: 380)
        case .english:
            LessonBalloon(x: 28, y: 210, gradient: .coral)
            LessonBalloon(x: 805, y: 154, gradient: .gold)
            LessonBalloon(x: 760, y: 350, gradient: .violet2)
            CloudView(x: 420, y: 355, scale: 1.2)
        case .science:
            TreeView(x: 24, y: 324, scale: 1.2)
            TreeView(x: 816, y: 310, scale: 1.3)
            BushView(x: 732, y: 365, scale: 1.1)
            ShroomView(x: 468, y: 383, scale: 0.8)
        }
    }
}

/// RD-03 尚未提供独立气球；仍用相同矢量节点与渐变绘制。
private struct LessonBalloon: View {
    let x: CGFloat
    let y: CGFloat
    let gradient: ClayGradient
    var body: some View {
        SceneSprite(nodes: [
            .shape(scenePath {
                $0.move(to: CGPoint(x: 0, y: 28))
                $0.addCurve(to: CGPoint(x: 0, y: 112), control1: CGPoint(x: -20, y: 60), control2: CGPoint(x: 18, y: 84))
            }, stroke: .color(ClayColor.balloonString), width: 2),
            .shape(sceneEllipse(0, 0, 28, 36), fill: .gradient(gradient)),
            .shape(scenePath {
                $0.addLines([CGPoint(x: 0, y: 32), CGPoint(x: -5, y: 41), CGPoint(x: 5, y: 41)])
                $0.closeSubpath()
            }, fill: .color(ClayColor.balloonKnot)),
            .shape(sceneEllipse(-10, -14, 6, 12), fill: .color(ClayColor.white), opacity: 0.45)
        ], bounds: CGRect(x: -30, y: -38, width: 60, height: 152), x: x, y: y, motion: .bob)
    }
}
