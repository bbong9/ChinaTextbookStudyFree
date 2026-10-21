import SwiftUI

/// 农场沿用 screens.js 的 meadow(230)、谷仓、栅栏和池塘坐标。
struct PictureWordScene: View {
    let scene: PictureScene
    let layout: StageLayout

    var body: some View {
        ZStack(alignment: .topLeading) {
            if scene == .mirror {
                ClayColor.petWall
                ClayGradient.wood.view.frame(height: 160).frame(maxHeight: .infinity, alignment: .bottom)
            } else {
                MeadowLayer(horizon: scene == .road ? 260 : 230)
            }
            decorations.frame(width: 844, height: 390).position(layout.place(x: 422, y: 195))
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder private var decorations: some View {
        switch scene {
        case .farm:
            Canvas { context, _ in
                var barn = context
                barn.translateBy(x: 720, y: 230)
                let nodes: [SceneNode] = [
                    .shape(scenePath {
                        $0.addLines([.init(x: -80, y: 0), .init(x: -80, y: -90), .init(x: 0, y: -150),
                                     .init(x: 80, y: -90), .init(x: 80, y: 0)]); $0.closeSubpath()
                    }, fill: .gradient(.red)),
                    .shape(scenePath {
                        $0.addLines([.init(x: -90, y: -86), .init(x: 0, y: -158), .init(x: 90, y: -86)])
                    }, stroke: .color(ClayColor.white), width: 10),
                    .shape(sceneRect(-34, -74, 68, 74, 4), fill: .color(ClayColor.bookPage)),
                    .shape(scenePath {
                        $0.move(to: .init(x: -34, y: -74)); $0.addLine(to: .init(x: 34, y: 0))
                        $0.move(to: .init(x: 34, y: -74)); $0.addLine(to: .init(x: -34, y: 0))
                    }, stroke: .color(ClayColor.balloonKnot), width: 7),
                    .shape(sceneEllipse(0, -112, 14, 14), fill: .color(ClayColor.bookPage))
                ]
                nodes.forEach { $0.draw(in: barn, accent: ClayColor.white) }
                SceneNode.shape(sceneEllipse(150, 320, 112, 36), fill: .gradient(.water))
                    .draw(in: context, accent: ClayColor.white)
                context.fill(sceneEllipse(130, 312, 40, 8), with: .color(ClayColor.white.opacity(0.35)))
            }
            FenceView(x1: 0, x2: 600, y: 250)
            FlowerView(x: 620, y: 350, color: ClayColor.flameCore)
            TuftView(x: 260, y: 380)
            TuftView(x: 580, y: 380)
        case .forest:
            TreeView(x: 48, y: 292, scale: 1.2)
            TreeView(x: 760, y: 300, scale: 1.5)
            TreeView(x: 650, y: 285, scale: 0.9)
            BushView(x: 550, y: 355)
            ShroomView(x: 55, y: 365)
        case .water:
            ClayGradient.water.view.clipShape(Ellipse())
                .frame(width: 760, height: 155).position(x: 400, y: 306)
            StoneView(x: 76, y: 345, scale: 1.5)
            StoneView(x: 580, y: 340, scale: 1.2)
            TuftView(x: 660, y: 370)
        case .orchard:
            TreeView(x: 40, y: 300, scale: 1.3)
            TreeView(x: 760, y: 320, scale: 1.4)
            FenceView(x1: 40, x2: 810, y: 255)
            FlowerView(x: 600, y: 365)
        case .road:
            PathRoad(points: [.init(x: -80, y: 255), .init(x: 380, y: 270), .init(x: 900, y: 255)])
            PathRoad(points: [.init(x: -80, y: 340), .init(x: 380, y: 350), .init(x: 900, y: 340)])
            TreeView(x: 774, y: 245, scale: 0.6)
        case .mirror:
            RoundedRectangle(cornerRadius: ClayRadius.pictureCard)
                .fill(ClayColor.windowFrame).frame(width: 755, height: 258).position(x: 420, y: 241)
            RoundedRectangle(cornerRadius: ClayRadius.card)
                .fill(ClayColor.windowGlass)
                .overlay { ClayGradient.sky.view }
                .clipShape(RoundedRectangle(cornerRadius: ClayRadius.card))
                .frame(width: 735, height: 238).position(x: 420, y: 241)
            Canvas { context, _ in
                let shine = scenePath {
                    $0.addLines([.init(x: 80, y: 140), .init(x: 160, y: 140),
                                 .init(x: 340, y: 350), .init(x: 260, y: 350)]); $0.closeSubpath()
                }
                context.fill(shine, with: .color(ClayColor.white.opacity(0.2)))
            }
        }
    }
}
