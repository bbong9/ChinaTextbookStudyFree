import SwiftUI

/// 室内新增物件沿用 RD-03 的路径、材质和场景绘制器。
struct PetRoomBackdrop: View {
    let layout: StageLayout
    var body: some View {
        ZStack(alignment: .topLeading) {
            ClayColor.petWall
            ClayGradient.wood.view
                .frame(height: layout.size.height - layout.place(x: 0, y: 250).y)
                .frame(maxHeight: .infinity, alignment: .bottom)
            room.frame(width: 844, height: 390).position(layout.place(x: 422, y: 195))
        }
    }

    private var room: some View {
        ZStack(alignment: .topLeading) {
            Canvas { context, _ in
                for row in 0..<5 {
                    for column in 0..<12 {
                        context.fill(sceneEllipse(CGFloat(column * 74 + (row % 2) * 37 + 20), CGFloat(row * 54 + 20), 5, 5),
                                     with: .color(ClayColor.petWallDot))
                    }
                }
                for y in [280.0, 314, 352] {
                    let path = scenePath { $0.move(to: .init(x: 0, y: y)); $0.addLine(to: .init(x: 844, y: y)) }
                    context.stroke(path, with: .color(ClayColor.petFloorLine.opacity(0.35)), lineWidth: 2)
                }
                let nodes: [SceneNode] = [
                    .shape(sceneRect(0, 236, 844, 14), fill: .color(ClayColor.petSkirting)),
                    .shape(sceneRect(596, 58, 150, 128, 64), fill: .color(ClayColor.petFloorLine)),
                    .shape(sceneRect(606, 68, 130, 110, 56), fill: .gradient(.sky)),
                    .shape(scenePath { $0.move(to: .init(x: 671, y: 68)); $0.addLine(to: .init(x: 671, y: 178));
                        $0.move(to: .init(x: 606, y: 124)); $0.addLine(to: .init(x: 736, y: 124)) },
                           stroke: .color(ClayColor.petFloorLine), width: 6),
                    .shape(scenePath { $0.addLines([.init(x: 572, y: 50), .init(x: 580, y: 50), .init(x: 600, y: 200), .init(x: 572, y: 200)]); $0.closeSubpath() }, fill: .gradient(.coral)),
                    .shape(scenePath { $0.addLines([.init(x: 762, y: 50), .init(x: 770, y: 50), .init(x: 770, y: 200), .init(x: 742, y: 200)]); $0.closeSubpath() }, fill: .gradient(.coral)),
                    .shape(sceneRect(210, 70, 84, 74, 10), fill: .gradient(.wood)),
                    .shape(sceneRect(218, 78, 68, 58, 6), fill: .color(ClayColor.petPicture)),
                    .shape(scenePath { $0.addLines([.init(x: 40, y: 236), .init(x: 48, y: 196), .init(x: 92, y: 196), .init(x: 100, y: 236)]); $0.closeSubpath() }, fill: .gradient(.coral)),
                    .shape(sceneEllipse(58, 176, 22, 22), fill: .gradient(.canopy)),
                    .shape(sceneEllipse(80, 168, 22, 22), fill: .gradient(.canopy)),
                    .shape(sceneEllipse(70, 148, 20, 20), fill: .gradient(.canopy)),
                    .shape(sceneEllipse(422, 312, 200, 40), fill: .color(ClayColor.petRug)),
                    .shape(sceneEllipse(422, 300, 104, 26), fill: .gradient(.violet2)),
                    .shape(sceneEllipse(422, 294, 86, 18), fill: .color(ClayColor.petBed)),
                    .shape(sceneEllipse(580, 296, 34, 10), fill: .color(ClayColor.petClean)),
                    .shape(sceneEllipse(580, 292, 30, 8), fill: .color(ClayColor.petBowl)),
                    .shape(sceneEllipse(572, 286, 10, 6), fill: .gradient(.wood)),
                    .shape(sceneEllipse(270, 300, 16, 16), fill: .gradient(.coral))
                ]
                nodes.forEach { $0.draw(in: context, accent: ClayColor.white) }
                context.stroke(sceneEllipse(422, 312, 170, 30), with: .color(ClayColor.white),
                               style: .init(lineWidth: 4, lineCap: .round, dash: [2, 12]))
            }
            PetView(kind: .egg, size: 46, accessory: .noAccessory)
                .position(x: 252, y: 109).environment(\.petAnimationsPaused, true)
            CloudView(x: 660, y: 112, scale: 0.3, animation: nil)
        }
    }
}

struct PetShopBackdrop: View {
    let layout: StageLayout
    var body: some View {
        ZStack(alignment: .topLeading) {
            ClayColor.petShop
            Canvas { context, size in
                for index in 0..<Int(ceil(size.width / 60)) {
                    context.fill(sceneRect(CGFloat(index) * 60, 0, 60, 48, 16),
                                 with: .color(index.isMultiple(of: 2) ? ClayColor.petCoral : ClayColor.white))
                }
                context.translateBy(x: layout.place(x: 0, y: 0).x, y: layout.place(x: 0, y: 0).y)
                let nodes: [SceneNode] = [
                    .shape(scenePath { $0.addLines([.init(x: 110, y: 40), .init(x: 238, y: 40), .init(x: 300, y: 290), .init(x: 48, y: 290)]); $0.closeSubpath() }, fill: .color(ClayColor.white.opacity(0.35))),
                    .shape(sceneEllipse(174, 290, 120, 24), fill: .color(ClayColor.petPlatform)),
                    .shape(sceneEllipse(174, 284, 110, 20), fill: .gradient(.cream)),
                    .shape(sceneRect(320, 164, 490, 16, 6), fill: .gradient(.woodD)),
                    .shape(sceneRect(320, 280, 490, 16, 6), fill: .gradient(.woodD))
                ]
                nodes.forEach { $0.draw(in: context, accent: ClayColor.white) }
            }
        }
    }
}
