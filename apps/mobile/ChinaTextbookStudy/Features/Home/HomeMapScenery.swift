import SwiftUI

/// screens.js scrMap 的天空、远山；重复三块静态画布，只平移合成层。
struct HomeMapHorizon: View {
    let offset: CGFloat
    let reduceMotion: Bool
    let size: CGSize
    var body: some View {
        let shift = reduceMotion ? 0 : (offset * 0.3).truncatingRemainder(dividingBy: 844)
        ZStack(alignment: .topLeading) {
            SkyLayer()
            ForEach(-1...2, id: \.self) { tile in
                HomeMapFarTile().equatable()
                .offset(x: CGFloat(tile) * 844 + shift, y: size.height - 390)
            }
            CloudView(x: 250, y: size.height - 390 + 58, scale: 0.8).offset(x: shift)
            CloudView(x: 470, y: size.height - 390 + 34, scale: 0.6, animation: .drift2).offset(x: shift)
            CloudView(x: 640, y: size.height - 390 + 104, scale: 0.45).offset(x: shift)
        }.accessibilityHidden(true)
    }
}

private struct HomeMapFarTile: View, Equatable {
    var body: some View {
        Canvas { context, _ in
            let far = scenePath {
                $0.move(to: CGPoint(x: 0, y: 196))
                $0.addCurve(to: CGPoint(x: 250, y: 178), control1: CGPoint(x: 80, y: 150), control2: CGPoint(x: 170, y: 150))
                $0.addCurve(to: CGPoint(x: 500, y: 170), control1: CGPoint(x: 330, y: 140), control2: CGPoint(x: 420, y: 138))
                $0.addCurve(to: CGPoint(x: 760, y: 168), control1: CGPoint(x: 580, y: 146), control2: CGPoint(x: 680, y: 140))
                $0.addCurve(to: CGPoint(x: 844, y: 196), control1: CGPoint(x: 800, y: 156), control2: CGPoint(x: 830, y: 160))
                $0.addLine(to: CGPoint(x: 844, y: 390)); $0.addLine(to: CGPoint(x: 0, y: 390))
                $0.closeSubpath()
            }
            SceneNode.shape(far, fill: .gradient(.far)).draw(in: context, accent: ClayColor.white)
        }
        .frame(width: 844, height: 390)
        .drawingGroup()
    }
}

/// 每单元的静态中景合成缓存，编号决定花草排列，相邻段不同。
struct HomeMapMiddle: View, Equatable {
    let unit: Int
    let width: CGFloat
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.unit == rhs.unit && lhs.width == rhs.width }
    var body: some View {
        ZStack(alignment: .topLeading) {
            Canvas { context, _ in
                let ridge = scenePath {
                    $0.move(to: CGPoint(x: -200, y: 222))
                    $0.addCurve(to: CGPoint(x: width / 2, y: 214), control1: CGPoint(x: 150, y: 196), control2: CGPoint(x: 300, y: 200))
                    $0.addCurve(to: CGPoint(x: width + 200, y: 222), control1: CGPoint(x: width - 284, y: 196), control2: CGPoint(x: width - 144, y: 190))
                }
                var hill = ridge
                hill.addLine(to: CGPoint(x: width + 200, y: 390)); hill.addLine(to: CGPoint(x: -200, y: 390))
                hill.closeSubpath()
                SceneNode.shape(hill, fill: .gradient(.hill1)).draw(in: context, accent: ClayColor.white)
                SceneNode.shape(ridge, stroke: .color(ClayColor.hillHighlight), width: 3, opacity: 0.7)
                    .draw(in: context, accent: ClayColor.white)
                let foreground = scenePath {
                    $0.move(to: CGPoint(x: -200, y: 330))
                    $0.addCurve(to: CGPoint(x: width + 200, y: 330), control1: CGPoint(x: 240, y: 312), control2: CGPoint(x: 540, y: 306))
                    $0.addLine(to: CGPoint(x: width + 200, y: 390)); $0.addLine(to: CGPoint(x: -200, y: 390)); $0.closeSubpath()
                }
                SceneNode.shape(foreground, fill: .gradient(.hill2)).draw(in: context, accent: ClayColor.white)
            }
            BushView(x: unit.isMultiple(of: 2) ? 180 : 214, y: 220, scale: 0.7)
            BushView(x: 520, y: 222, scale: 0.75)
            BushView(x: width - 74, y: 212, scale: 0.6)
            FlowerView(x: 200, y: 236)
            FlowerView(x: unit.isMultiple(of: 2) ? 410 : 372, y: 222, color: ClayColor.flameCore)
            FlowerView(x: 560, y: 232, color: ClayColor.flowerLavender)
            FlowerView(x: width - 136, y: 214)
            ShroomView(x: 244, y: 232, scale: 0.7)
            if unit > 1 { TreeView(x: unit.isMultiple(of: 2) ? 310 : 680, y: 215, scale: 0.7) }
        }
        .frame(width: width, height: 390)
        .drawingGroup()
        .accessibilityHidden(true)
    }
}

struct HomeMapForeground: View, Equatable {
    let width: CGFloat
    var body: some View {
        ZStack(alignment: .topLeading) {
            TuftView(x: 110, y: 318)
            TuftView(x: 400, y: 330, scale: 1.2)
            TuftView(x: width - 204, y: 314)
            StoneView(x: 180, y: 312, scale: 0.8)
            StoneView(x: 560, y: 300, scale: 0.7)
        }.frame(width: width, height: 390).drawingGroup().accessibilityHidden(true)
    }
}

/// scrMap 最左边的大树，树洞作为书屋地标。
struct HomeMapTree: View {
    var body: some View {
        Canvas { context, _ in
            let trunk = scenePath {
                $0.move(to: CGPoint(x: -40, y: 312))
                $0.addCurve(to: CGPoint(x: 10, y: 130), control1: CGPoint(x: -6, y: 292), control2: CGPoint(x: 6, y: 230))
                $0.addCurve(to: CGPoint(x: 6, y: -10), control1: CGPoint(x: 12, y: 70), control2: CGPoint(x: 8, y: 30))
                $0.addLine(to: CGPoint(x: 94, y: -10))
                $0.addCurve(to: CGPoint(x: 88, y: 130), control1: CGPoint(x: 90, y: 30), control2: CGPoint(x: 86, y: 80))
                $0.addCurve(to: CGPoint(x: 128, y: 306), control1: CGPoint(x: 92, y: 220), control2: CGPoint(x: 104, y: 280))
                $0.closeSubpath()
            }
            let door = scenePath {
                $0.move(to: CGPoint(x: 32, y: 294)); $0.addLine(to: CGPoint(x: 32, y: 250))
                $0.addCurve(to: CGPoint(x: 74, y: 250), control1: CGPoint(x: 32, y: 222), control2: CGPoint(x: 74, y: 222))
                $0.addLine(to: CGPoint(x: 74, y: 294)); $0.closeSubpath()
            }
            let nodes: [SceneNode] = [
                .shape(trunk, fill: .gradient(.trunk)), .shape(door, fill: .gradient(.woodD)),
                .shape(sceneEllipse(65, 268, 3, 3), fill: .color(ClayColor.flameCore)),
                .shape(sceneEllipse(54, 160, 17, 17), fill: .color(ClayColor.woodDark)),
                .shape(sceneEllipse(54, 160, 13, 13), fill: .color(ClayColor.windowLight)),
                .shape(scenePath { $0.move(to: CGPoint(x: 54, y: 147)); $0.addLine(to: CGPoint(x: 54, y: 173));
                    $0.move(to: CGPoint(x: 41, y: 160)); $0.addLine(to: CGPoint(x: 67, y: 160)) },
                       stroke: .color(ClayColor.woodDark), width: 3),
                .shape(sceneEllipse(-6, -6, 74, 74), fill: .gradient(.canopy2)),
                .shape(sceneEllipse(80, -30, 62, 62), fill: .gradient(.canopy)),
                .shape(sceneEllipse(146, -14, 40, 40), fill: .gradient(.canopy2))
            ]
            nodes.forEach { $0.draw(in: context, accent: ClayColor.white) }
        }.frame(width: 200, height: 320).drawingGroup().accessibilityHidden(true)
    }
}

/// 滚动只移动合成层，不重复构造静态曲线。
struct HomeMapRoad: View, Equatable {
    let points: [CGPoint]
    var body: some View { PathRoad(points: points).drawingGroup() }
}
