import SwiftUI

struct StarView: View {
    var x: CGFloat = 0, y: CGFloat = 0, radius: CGFloat = 11
    var on = true
    var twinkle = false

    /// S.starPath 的 0.48 内半径与 toFixed(1)，包括 0.22r 的圆角描边。
    static func path(x: CGFloat = 0, y: CGFloat = 0, radius: CGFloat) -> Path {
        scenePath { path in
            for i in 0..<10 {
                let a = -CGFloat.pi / 2 + CGFloat(i) * .pi / 5
                let r = i.isMultiple(of: 2) ? radius : radius * 0.48
                let p = CGPoint(x: ((x + cos(a) * r) * 10).rounded() / 10,
                                y: ((y + sin(a) * r) * 10).rounded() / 10)
                if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.closeSubpath()
        }
    }

    static func nodes(radius r: CGFloat, on: Bool) -> [SceneNode] {
        let face = path(radius: r), edge = path(y: r * 0.12, radius: r)
        let edgePaint: ScenePaint = .color(on ? ClayColor.starEdge : ClayColor.starOffEdge)
        let facePaint: ScenePaint = on ? .gradient(.gold) : .color(ClayColor.starOffFace)
        var nodes: [SceneNode] = [
            .shape(edge, fill: edgePaint, stroke: edgePaint, width: r * 0.22, join: .round),
            .shape(face, fill: facePaint, stroke: facePaint, width: r * 0.22, join: .round)
        ]
        if on { nodes.append(.shape(sceneEllipse(-r * 0.25, -r * 0.3, r * 0.22, r * 0.12),
                                    fill: .color(ClayColor.white), opacity: 0.8)) }
        return nodes
    }

    var body: some View {
        SceneSprite(nodes: Self.nodes(radius: radius, on: on),
                    bounds: CGRect(x: -radius * 1.2, y: -radius * 1.2, width: radius * 2.4, height: radius * 2.5),
                    x: x, y: y, motion: twinkle ? .twinkle : nil)
    }
}

struct CoinView: View {
    var x: CGFloat = 0, y: CGFloat = 0, radius: CGFloat = 12
    var body: some View {
        let emblem = StarView.path(y: -radius * 0.06, radius: radius * 0.5)
        SceneSprite(nodes: [
            .shape(sceneEllipse(0, 0, radius, radius), fill: .color(ClayColor.coinEdge)),
            .shape(sceneEllipse(0, -radius * 0.08, radius * 0.86, radius * 0.86), fill: .gradient(.gold)),
            .shape(emblem, fill: .color(ClayColor.coinEmblem), stroke: .color(ClayColor.coinEmblem),
                   width: radius * 0.5 * 0.22, join: .round)
        ], bounds: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), x: x, y: y)
    }
}

struct CharCube: View {
    enum State: String, CaseIterable {
        case done, current, locked, game
        var label: String {
            switch self { case .done: return "已完成"; case .current: return "当前"; case .locked: return "未解锁"; case .game: return "小游戏" }
        }
        var artwork: [SceneNode] {
            switch self {
            case .done: return SceneArtwork.cubeDone
            case .current: return SceneArtwork.cubeCurrent
            case .locked: return SceneArtwork.cubeLocked
            case .game: return SceneArtwork.cubeGame
            }
        }
    }
    @ObservedObject private var kai = ClayKaiFontStore.shared
    var x: CGFloat = 0, y: CGFloat = 0
    let label: String
    let state: State
    var stars = 0

    var body: some View {
        let font = Double(label) != nil ? ClayFont.nunito(size: 29) : ClayFont.kai(size: 29)
        let nodes = state.artwork + (state == .game ? [] : [
            .text(label, at: CGPoint(x: 0, y: -10), font: font,
                  color: state == .locked ? ClayColor.cubeLockedInk : ClayColor.cubeInk)
        ])
        ZStack(alignment: .topLeading) {
            if state == .current {
                SceneSprite(nodes: [.shape(sceneEllipse(0, -14, 52, 40), fill: .gradient(.glow))],
                            bounds: CGRect(x: -52, y: -54, width: 104, height: 80), x: x, y: y, motion: .pulse)
            }
            SceneSprite(nodes: nodes, bounds: CGRect(x: -34, y: -48, width: 68, height: 68), x: x, y: y)
            if stars > 0 {
                ForEach(0..<3) { index in
                    StarView(x: x - 15 + CGFloat(index) * 15, y: y - 52 - (index == 1 ? 4 : 0),
                             radius: 6.5, on: index < min(3, stars))
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label.isEmpty ? "字块" : label)，\(state.label)" + (stars > 0 ? "，\(min(3, stars))星" : ""))
        .accessibilityIdentifier("char-cube-\(state.rawValue)-\(label)")
    }
}
