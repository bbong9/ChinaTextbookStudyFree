#if DEBUG
import SwiftUI

/// 固定数据来自 scrMap；没有 HUD、宠物或业务状态。
struct SceneMapSample: View {
    let layout: StageLayout
    static let points: [CGPoint] = [(20, 300), (112, 286), (172, 280), (232, 272), (292, 262),
        (352, 254), (414, 252), (476, 256), (538, 254), (600, 246), (668, 234), (740, 222), (870, 204)]
        .map { CGPoint(x: $0.0, y: $0.1) }
    private let items: [(String, CharCube.State, Int)] = [("日", .done, 3), ("月", .done, 3), ("水", .done, 2),
        ("火", .done, 3), ("", .game, 0), ("山", .current, 0), ("石", .locked, 0), ("田", .locked, 0), ("禾", .locked, 0)]

    private func artwork(_ nodes: [SceneNode]) -> some View {
        SceneSprite(nodes: nodes, bounds: CGRect(origin: .zero, size: StageLayout.designSize))
    }

    var body: some View {
        let origin = layout.place(x: 0, y: 0)
        ZStack(alignment: .topLeading) {
            ZStack(alignment: .topLeading) {
                // 舞台加高补天空；设计稿坐标不随宽高拉伸。
                SkyLayer(sun: CGPoint(x: 520, y: -30), sunRadius: 180)
                Rectangle().fill(ClayColor.meadowFloor)
                    .frame(height: 60).frame(maxHeight: .infinity, alignment: .bottom)
                staticMap.frame(width: 844, height: 390).offset(x: origin.x, y: origin.y)
            }.drawingGroup()
            map.frame(width: 844, height: 390).offset(x: origin.x, y: origin.y)
        }
    }

    private var staticMap: some View {
        ZStack(alignment: .topLeading) {
            artwork(SceneArtwork.mapFar)
            artwork(SceneArtwork.mapRail)
            TrainView(x: 812, y: 176, scale: 0.4, cars: [.init(), .init(gradient: .green2)])
            artwork(SceneArtwork.mapHills)
            MushroomHouseView(x: 300, y: 216, scale: 0.7)
            BushView(x: 214, y: 220, scale: 0.7)
            BushView(x: 520, y: 222, scale: 0.75)
            BushView(x: 770, y: 212, scale: 0.6)
            FlowerView(x: 200, y: 236)
            FlowerView(x: 372, y: 222, color: ClayColor.flameCore)
            FlowerView(x: 560, y: 232, color: ClayColor.flowerLavender)
            FlowerView(x: 708, y: 214)
            FlowerView(x: 820, y: 230, color: ClayColor.white)
            ShroomView(x: 244, y: 232, scale: 0.7)
            ShroomView(x: 626, y: 220, scale: 0.6)
            artwork(SceneArtwork.mapTree)
            TuftView(x: 110, y: 318)
            TuftView(x: 400, y: 330, scale: 1.2)
            TuftView(x: 640, y: 314)
            StoneView(x: 180, y: 312, scale: 0.8)
            StoneView(x: 560, y: 300, scale: 0.7)
            PathRoad(points: Self.points)
        }
    }

    private var map: some View {
        ZStack(alignment: .topLeading) {
            CloudView(x: 250, y: 58, scale: 0.8)
            CloudView(x: 470, y: 34, scale: 0.6, animation: .drift2)
            CloudView(x: 640, y: 104, scale: 0.45)
            ButterflyView(x: 470, y: 150)
            ButterflyView(x: 150, y: 200, color: ClayColor.flameCore)
            ForEach(items.indices, id: \.self) { index in
                let item = items[index], point = Self.points[index + 1]
                CharCube(x: point.x, y: point.y + 2, label: item.0, state: item.1, stars: item.2)
            }
            GiftView(x: 668, y: 238, scale: 0.85)
            artwork(SceneArtwork.mapLabels)
        }
    }
}

struct ClaySceneGallery: View {
    let layout: StageLayout
    @State private var materials = false
    @State private var selectedCube: CharCube.State?

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let selectedCube {
                MeadowLayer(horizon: 250)
                CharCube(label: selectedCube == .game ? "" : "山", state: selectedCube,
                         stars: selectedCube == .done ? 2 : 0)
                    .frame(width: 1, height: 1).scaleEffect(3)
                    .position(layout.place(x: 422, y: 245))
                Text("字块 · \(selectedCube.label)").font(ClayFont.title).foregroundStyle(ClayColor.ink)
                    .position(layout.place(x: 422, y: 80))
            } else if materials {
                materialsSample
            } else {
                SceneMapSample(layout: layout)
            }
            Text("场景").font(ClayFont.label).foregroundStyle(ClayColor.ink)
                .position(layout.place(x: 422, y: 24))
            controls
        }
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Button("地图") { materials = false; selectedCube = nil }
                .accessibilityIdentifier("clay-scene-map")
            Button("全部素材") { materials = true; selectedCube = nil }
                .accessibilityIdentifier("clay-scene-materials")
            ForEach(CharCube.State.allCases, id: \.self) { state in
                Button(state.label) { selectedCube = state }
                    .accessibilityIdentifier("clay-scene-\(state.rawValue)")
            }
        }
        .font(ClayFont.caption).foregroundStyle(ClayColor.ink)
        .buttonStyle(ScenePreviewButtonStyle())
        .position(layout.place(x: 422, y: 360))
    }

    private var materialsSample: some View {
        ZStack(alignment: .topLeading) {
            MeadowLayer(horizon: 230)
            ZStack(alignment: .topLeading) {
                TreeView(x: 95, y: 235, scale: 0.85)
                BushView(x: 160, y: 240)
                CottageView(x: 245, y: 220, scale: 0.6)
                MushroomHouseView(x: 370, y: 225, scale: 0.6)
                FenceView(x1: 175, x2: 420, y: 252)
                FlowerView(x: 135, y: 265)
                TuftView(x: 320, y: 263)
                StoneView(x: 430, y: 256)
                ShroomView(x: 465, y: 250)
                TrainView(x: 780, y: 195, scale: 0.54, cars: [.init(label: "12"), .init(gradient: .green2, label: "13")])
            }.drawingGroup()
            ButterflyView(x: 300, y: 100)
            ChestView(x: 540, y: 258, scale: 0.65)
            ChestView(x: 635, y: 260, scale: 0.65, open: true)
            GiftView(x: 720, y: 245, scale: 0.8).clayMotion(.bob)
            CoinView(x: 776, y: 225)
            StarView(x: 740, y: 85, radius: 16, twinkle: true)
            StarView(x: 785, y: 85, radius: 16, on: false)
            ForEach(Array(DockIcon.Kind.allCases.enumerated()), id: \.element.id) { index, kind in
                VStack(spacing: 0) {
                    DockIcon(kind: kind, size: 45)
                    Text(kind.label).font(ClayFont.swatch).foregroundStyle(ClayColor.ink)
                }.position(x: 92 + CGFloat(index) * 60, y: 303)
            }
        }
        .frame(width: 844, height: 390)
        .offset(x: layout.place(x: 0, y: 0).x, y: layout.place(x: 0, y: 0).y)
    }
}

private struct ScenePreviewButtonStyle: ButtonStyle {
    @Environment(\.clayStageScale) private var scale
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: max(54, 44 / scale), minHeight: max(44, 44 / scale))
            .background(ClayColor.creamTop.opacity(configuration.isPressed ? 0.7 : 0.94),
                        in: RoundedRectangle(cornerRadius: ClayRadius.smallButton))
    }
}
#endif
