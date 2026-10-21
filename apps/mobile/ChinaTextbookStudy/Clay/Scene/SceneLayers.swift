import SwiftUI

struct SkyLayer: View {
    var sun = CGPoint(x: 560, y: -30)
    var sunRadius: CGFloat = 170
    var body: some View {
        GeometryReader { geometry in
            let origin = CGPoint(x: (geometry.size.width - 844) / 2, y: geometry.size.height - 390)
            ZStack(alignment: .topLeading) {
                ClayColor.skyTop
                ClayGradient.sky.view.frame(height: 390)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                ClayGradient.sunglow.view.frame(width: sunRadius * 2, height: sunRadius * 2)
                    .position(x: sun.x + origin.x, y: sun.y + origin.y)
            }
        }
        .accessibilityHidden(true)
    }
}

/// screens.js meadow(horizon)。天空/山坡合成，三朵云独立更新。
struct MeadowLayer: View {
    var horizon: CGFloat = 210
    var body: some View {
        GeometryReader { geometry in
            let origin = CGPoint(x: (geometry.size.width - 844) / 2, y: geometry.size.height - 390)
            ZStack(alignment: .topLeading) {
            ZStack {
                SkyLayer()
                Canvas { context, _ in
                    var context = context
                    context.translateBy(x: origin.x, y: origin.y)
                    let h = horizon
                    let far = scenePath {
                        $0.move(to: CGPoint(x: 0, y: h - 14))
                        $0.addCurve(to: CGPoint(x: 260, y: h - 30), control1: CGPoint(x: 90, y: h - 60), control2: CGPoint(x: 180, y: h - 58))
                        $0.addCurve(to: CGPoint(x: 520, y: h - 40), control1: CGPoint(x: 340, y: h - 70), control2: CGPoint(x: 440, y: h - 72))
                        $0.addCurve(to: CGPoint(x: 844, y: h - 36), control1: CGPoint(x: 600, y: h - 66), control2: CGPoint(x: 700, y: h - 70))
                        $0.addLine(to: CGPoint(x: 844, y: 390)); $0.addLine(to: CGPoint(x: 0, y: 390)); $0.closeSubpath()
                    }
                    let ridge = scenePath {
                        $0.move(to: CGPoint(x: 0, y: h))
                        $0.addCurve(to: CGPoint(x: 430, y: h - 8), control1: CGPoint(x: 150, y: h - 26), control2: CGPoint(x: 300, y: h - 22))
                        $0.addCurve(to: CGPoint(x: 844, y: h - 22), control1: CGPoint(x: 560, y: h - 26), control2: CGPoint(x: 700, y: h - 32))
                    }
                    var hill = ridge
                    hill.addLine(to: CGPoint(x: 844, y: 390)); hill.addLine(to: CGPoint(x: 0, y: 390)); hill.closeSubpath()
                    SceneNode.shape(far, fill: .gradient(.far)).draw(in: context, accent: ClayColor.white)
                    SceneNode.shape(hill, fill: .gradient(.hill1)).draw(in: context, accent: ClayColor.white)
                    SceneNode.shape(ridge, stroke: .color(ClayColor.hillHighlight), width: 3, opacity: 0.7)
                        .draw(in: context, accent: ClayColor.white)
                }
            }.drawingGroup()
            CloudView(x: origin.x + 170, y: origin.y + 70, scale: 0.8)
            CloudView(x: origin.x + 430, y: origin.y + 46, scale: 0.6, animation: .drift2)
            CloudView(x: origin.x + 690, y: origin.y + 96, scale: 0.5)
            }
        }
        .accessibilityHidden(true)
    }
}

struct PathRoad: View {
    let points: [CGPoint]

    /// art.js smoothPath；控制点和原 JS 一样保留一位小数。
    static func path(points: [CGPoint]) -> Path {
        guard let first = points.first else { return Path() }
        var path = Path(); path.move(to: first)
        func rounded(_ value: CGFloat) -> CGFloat { (value * 10).rounded() / 10 }
        for i in 0..<max(0, points.count - 1) {
            let p0 = points[max(0, i - 1)], p1 = points[i], p2 = points[i + 1]
            let p3 = points[min(points.count - 1, i + 2)]
            path.addCurve(to: p2,
                          control1: CGPoint(x: rounded(p1.x + (p2.x - p0.x) / 6), y: rounded(p1.y + (p2.y - p0.y) / 6)),
                          control2: CGPoint(x: rounded(p2.x - (p3.x - p1.x) / 6), y: rounded(p2.y - (p3.y - p1.y) / 6)))
        }
        return path
    }

    var body: some View {
        let path = Self.path(points: points)
        Canvas { context, _ in
            context.stroke(path.offsetBy(dx: 0, dy: 4), with: .color(ClayColor.roadEdge),
                           style: StrokeStyle(lineWidth: 48, lineCap: .round))
            context.stroke(path, with: .color(ClayColor.roadFace), style: StrokeStyle(lineWidth: 42, lineCap: .round))
            context.stroke(path, with: .color(ClayColor.white.opacity(0.8)),
                           style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 18]))
        }.accessibilityHidden(true)
    }
}

struct FenceView: View {
    let x1: CGFloat, x2: CGFloat, y: CGFloat
    var body: some View {
        Canvas { context, _ in
            guard x2 > x1 else { return }
            var nodes: [SceneNode] = [
                .shape(sceneRect(x1, y - 30, x2 - x1, 8, 4), fill: .gradient(.wood)),
                .shape(sceneRect(x1, y - 14, x2 - x1, 8, 4), fill: .gradient(.wood))
            ]
            for x in stride(from: x1 + 8, to: x2, by: 34) {
                nodes.append(.shape(scenePath {
                    $0.addLines([CGPoint(x: x - 6, y: y), CGPoint(x: x - 6, y: y - 38),
                                 CGPoint(x: x, y: y - 46), CGPoint(x: x + 6, y: y - 38), CGPoint(x: x + 6, y: y)])
                    $0.closeSubpath()
                }, fill: .gradient(.wood)))
            }
            nodes.forEach { $0.draw(in: context, accent: ClayColor.white) }
        }.accessibilityHidden(true)
    }
}
