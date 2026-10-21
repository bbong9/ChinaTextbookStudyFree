import SwiftUI

struct DockIcon: View {
    enum Kind: String, CaseIterable, Identifiable {
        case hanzi, math, eng, animal, story, idiom, books, checkin, shop, task, parent, pethouse
        var id: String { rawValue }
        var label: String {
            switch self {
            case .hanzi: return "识字游戏"; case .math: return "数学火车"; case .eng: return "英语气球"
            case .animal: return "看图识物"; case .story: return "故事绘本"; case .idiom: return "成语动画"
            case .books: return "课外书屋"; case .checkin: return "签到"; case .shop: return "宠物店"
            case .task: return "任务"; case .parent: return "家长"; case .pethouse: return "宠物小屋"
            }
        }
        var artwork: [SceneNode] {
            switch self {
            case .hanzi: return SceneArtwork.dockHanzi; case .math: return SceneArtwork.dockMath
            case .eng: return SceneArtwork.dockEng; case .animal: return SceneArtwork.dockAnimal
            case .story: return SceneArtwork.dockStory; case .idiom: return SceneArtwork.dockIdiom
            case .books: return SceneArtwork.dockBooks; case .checkin: return SceneArtwork.dockCheckin
            case .shop: return SceneArtwork.dockShop; case .task: return SceneArtwork.dockTask
            case .parent: return SceneArtwork.dockParent; case .pethouse: return SceneArtwork.dockPethouse
            }
        }
    }
    @ObservedObject private var kai = ClayKaiFontStore.shared
    let kind: Kind
    var size: CGFloat = 60

    var body: some View {
        let text: [SceneNode] = kind == .hanzi
            ? [.text("字", at: CGPoint(x: 30, y: 36), font: ClayFont.kai(size: 29), color: ClayColor.cubeInk)]
            : kind == .idiom
                ? [.text("成", at: CGPoint(x: 30, y: 42), font: ClayFont.kai(size: 26), color: ClayColor.scrollInk)] : []
        SceneSprite(nodes: kind.artwork + text, bounds: CGRect(x: 0, y: 0, width: 60, height: 60),
                    scale: size / 60)
            .frame(width: size, height: size)
            .accessibilityElement(children: .ignore)
            .accessibilityHidden(false)
            .accessibilityLabel(kind.label)
            .accessibilityIdentifier("dock-icon-\(kind.rawValue)")
    }
}
