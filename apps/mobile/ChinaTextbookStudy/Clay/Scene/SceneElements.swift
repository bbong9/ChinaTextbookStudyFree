import SwiftUI

// x/y 为 S.* 的原点，scale 为原始 s；所有尺寸和路径保留设计稿坐标。
struct TreeView: View {
    var x: CGFloat = 0, y: CGFloat = 0, scale: CGFloat = 1
    var body: some View {
        SceneSprite(nodes: SceneArtwork.tree, bounds: CGRect(x: -76, y: -180, width: 152, height: 194),
                    x: x, y: y, scale: scale)
    }
}

struct BushView: View {
    var x: CGFloat = 0, y: CGFloat = 0, scale: CGFloat = 1
    var body: some View {
        SceneSprite(nodes: SceneArtwork.bush, bounds: CGRect(x: -44, y: -54, width: 88, height: 60),
                    x: x, y: y, scale: scale)
    }
}

struct TuftView: View {
    var x: CGFloat = 0, y: CGFloat = 0, scale: CGFloat = 1
    var body: some View {
        SceneSprite(nodes: SceneArtwork.tuft, bounds: CGRect(x: -14, y: -26, width: 34, height: 28),
                    x: x, y: y, scale: scale)
    }
}

struct StoneView: View {
    var x: CGFloat = 0, y: CGFloat = 0, scale: CGFloat = 1
    var body: some View {
        SceneSprite(nodes: SceneArtwork.stone, bounds: CGRect(x: -26, y: -13, width: 52, height: 26),
                    x: x, y: y, scale: scale)
    }
}

struct ShroomView: View {
    var x: CGFloat = 0, y: CGFloat = 0, scale: CGFloat = 1
    var body: some View {
        SceneSprite(nodes: SceneArtwork.shroom, bounds: CGRect(x: -22, y: -42, width: 44, height: 44),
                    x: x, y: y, scale: scale)
    }
}

struct MushroomHouseView: View {
    var x: CGFloat = 0, y: CGFloat = 0, scale: CGFloat = 1
    var body: some View {
        SceneSprite(nodes: SceneArtwork.mushHouse, bounds: CGRect(x: -112, y: -200, width: 224, height: 220),
                    x: x, y: y, scale: scale)
    }
}

struct CottageView: View {
    var x: CGFloat = 0, y: CGFloat = 0, scale: CGFloat = 1
    var body: some View {
        SceneSprite(nodes: SceneArtwork.cottage, bounds: CGRect(x: -92, y: -178, width: 184, height: 196),
                    x: x, y: y, scale: scale)
    }
}

struct GiftView: View {
    var x: CGFloat = 0, y: CGFloat = 0, scale: CGFloat = 1
    var body: some View {
        SceneSprite(nodes: SceneArtwork.gift, bounds: CGRect(x: -48, y: -84, width: 96, height: 104),
                    x: x, y: y, scale: scale)
    }
}

struct FlowerView: View {
    var x: CGFloat = 0, y: CGFloat = 0
    var color: Color = ClayColor.flowerPink
    var scale: CGFloat = 1
    var body: some View {
        SceneSprite(nodes: SceneArtwork.flower, bounds: CGRect(x: -12, y: -36, width: 26, height: 38),
                    x: x, y: y, scale: scale, color: color)
    }
}

struct CloudView: View {
    var x: CGFloat = 0, y: CGFloat = 0, scale: CGFloat = 1
    var animation: ClayMotion? = .drift
    var body: some View {
        SceneSprite(nodes: SceneArtwork.cloud, bounds: CGRect(x: -58, y: -36, width: 128, height: 72),
                    x: x, y: y, scale: scale, motion: animation)
    }
}

struct ButterflyView: View {
    var x: CGFloat = 0, y: CGFloat = 0
    var color: Color = ClayColor.butterflyPink
    var body: some View {
        SceneSprite(nodes: SceneArtwork.butterfly, bounds: CGRect(x: -12, y: -11, width: 24, height: 22),
                    x: x, y: y, color: color, motion: .flutter)
    }
}

struct ChestView: View {
    var x: CGFloat = 0, y: CGFloat = 0, scale: CGFloat = 1
    var open = false
    var body: some View {
        SceneSprite(nodes: open ? SceneArtwork.chestOpen : SceneArtwork.chestClosed,
                    bounds: CGRect(x: -86, y: -126, width: 172, height: 146), x: x, y: y, scale: scale)
    }
}
