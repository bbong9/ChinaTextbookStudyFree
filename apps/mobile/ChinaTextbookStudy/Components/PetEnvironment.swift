import SwiftUI

/// rawValue 与 RD-05 的跨端目录一致；artKey 对应设计稿 PET_ART 的键。
enum PetKind: String, CaseIterable, Identifiable {
    case mituan = "pet_mituan", fox = "pet_fox", cat = "pet_cat"
    case penguin = "pet_penguin", owl = "pet_owl", dragon = "pet_dragon"
    case egg = "pet_egg", duck = "pet_duck", pig = "pet_pig", sheep = "pet_sheep"

    var id: String { rawValue }
    var artKey: String { String(rawValue.dropFirst(4)) }
    var name: String { Pets.petById(rawValue)?.name ?? rawValue }

    /// 一只宠物一组数据，所有配饰共用。坐标均为 120×130 画布坐标。
    var anchors: PetAnchors {
        switch self {
        case .mituan: return .init(head: .init(x: 60, y: 32), eyes: .init(x: 60, y: 76), neck: .init(x: 60, y: 108), scale: 0.92)
        case .fox: return .init(head: .init(x: 60, y: 32), eyes: .init(x: 60, y: 70), neck: .init(x: 60, y: 108), scale: 0.96)
        case .cat: return .init(head: .init(x: 60, y: 32), eyes: .init(x: 60, y: 74), neck: .init(x: 60, y: 108), scale: 0.96)
        case .penguin: return .init(head: .init(x: 60, y: 18), eyes: .init(x: 60, y: 62), neck: .init(x: 60, y: 100), scale: 0.82)
        case .owl: return .init(head: .init(x: 60, y: 32), eyes: .init(x: 60, y: 65), neck: .init(x: 60, y: 108), scale: 0.96)
        case .dragon: return .init(head: .init(x: 60, y: 32), eyes: .init(x: 60, y: 70), neck: .init(x: 60, y: 110), scale: 0.92)
        case .egg: return .init(head: .init(x: 60, y: 16), eyes: .init(x: 60, y: 78), neck: .init(x: 60, y: 109), scale: 0.82)
        case .duck: return .init(head: .init(x: 46, y: 26), eyes: .init(x: 47, y: 48), neck: .init(x: 48, y: 79), scale: 0.58)
        case .pig: return .init(head: .init(x: 60, y: 32), eyes: .init(x: 60, y: 70), neck: .init(x: 60, y: 110), scale: 1)
        case .sheep: return .init(head: .init(x: 60, y: 46), eyes: .init(x: 60, y: 74), neck: .init(x: 60, y: 102), scale: 0.6)
        }
    }
}

struct PetAnchors {
    let head: CGPoint
    let eyes: CGPoint
    let neck: CGPoint
    let scale: CGFloat
}

/// 保留旧皮肤 ID，既有购买、价格和存档由 RD-06/RD-07 接续处理。
enum PetAccessory: String, CaseIterable, Identifiable {
    case noAccessory = "skin_default", graduate = "skin_graduate", glasses = "skin_glasses"
    case party = "skin_party", crown = "skin_crown", wizard = "skin_wizard"
    case astronaut = "skin_astronaut", sunglasses = "skin_sunglasses", pirate = "skin_pirate"
    case headphones = "skin_headphones", laurel = "skin_laurel", bowtie = "skin_bowtie"

    var id: String { rawValue }
    var name: String { self == .noAccessory ? "无配饰" : Cosmetics.mascotSkins.first { $0.id == rawValue }?.name ?? rawValue }
    static var decorations: [Self] { allCases.filter { $0 != .noAccessory } }

    var isHeadwear: Bool { [.graduate, .party, .crown, .wizard, .pirate].contains(self) }

    /// 帽子的原始上边界；需要时整体等比缩小并下移，避免把企鹅的帽子单独缩得过小。
    func topOverflow(for anchors: PetAnchors) -> CGFloat {
        let minimumY: CGFloat
        switch self {
        case .graduate: minimumY = 2
        case .party: minimumY = -11
        case .crown: minimumY = 3
        case .wizard: minimumY = -8
        case .pirate: minimumY = 4
        default: return 0
        }
        return max(0, (32 - minimumY) * anchors.scale - anchors.head.y)
    }
}

/// 根视图从存档派生展示环境；页面可显式覆盖情境表情或预览配饰。
struct PetEnvironment: Equatable {
    var kind: PetKind = .mituan
    var accessory: PetAccessory = .noAccessory
    var mood: MascotMood = .happy
}

extension PetEnvironment {
    @MainActor init(progressStore: ProgressStore, now: Date = Date()) {
        let id = progressStore.activePet
        self.init(
            kind: PetKind(rawValue: id) ?? .mituan,
            accessory: progressStore.petAccessory[id].flatMap(PetAccessory.init(rawValue:)) ?? .noAccessory,
            mood: PetCare.mood(for: progressStore.careState(for: id, now: now))
        )
    }
}

private struct PetEnvironmentKey: EnvironmentKey { static let defaultValue = PetEnvironment() }
private struct PetAnimationsPausedKey: EnvironmentKey { static let defaultValue = false }

extension EnvironmentValues {
    var petEnvironment: PetEnvironment {
        get { self[PetEnvironmentKey.self] }
        set { self[PetEnvironmentKey.self] = newValue }
    }

    /// 预览网格可暂停 80 个样本；系统减少动态效果始终优先。
    var petAnimationsPaused: Bool {
        get { self[PetAnimationsPausedKey.self] }
        set { self[PetAnimationsPausedKey.self] = newValue }
    }
}
