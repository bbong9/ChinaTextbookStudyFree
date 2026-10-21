import Foundation

enum PetState {
    static let starterId = "pet_mituan"

    /// 迁移只补缺省值和米团配饰；金币、旧装扮所有权及旧装备字段原样保留。
    static func migrate(_ progress: inout UserProgress) {
        guard progress.petsMigrated != true else { return }
        if progress.ownedPets == nil { progress.ownedPets = [starterId] }
        if progress.activePet == nil { progress.activePet = starterId }
        if progress.petTreats == nil { progress.petTreats = 0 }
        var accessories = progress.petAccessory ?? [:]
        if let skin = progress.equippedMascotSkin,
           skin != Cosmetics.defaultEquipped.mascotSkin,
           accessories[starterId] == nil {
            accessories[starterId] = skin
        }
        progress.petAccessory = accessories
        progress.petsMigrated = true
    }

    /// 启动时结算所有已拥有宠物，首次出现的状态从此刻开始计时。
    static func settleCare(_ progress: inout UserProgress, now: Date) {
        var care = progress.petCare ?? [:]
        for id in progress.ownedPets ?? [starterId] {
            care[id] = care[id].map { PetCare.decay($0, now: now) } ?? PetCare.initial(now: now)
        }
        progress.petCare = care
    }
}

enum PetAdoptionStatus: Equatable {
    case available, insufficientGems, insufficientLevel, insufficientStreak, alreadyOwned, soldOut

    var reason: String? {
        switch self {
        case .available: return nil
        case .insufficientGems: return "金币不足"
        case .insufficientLevel: return "未达等级"
        case .insufficientStreak: return "未满 7 天"
        case .alreadyOwned: return "已拥有"
        case .soldOut: return "已售完"
        }
    }
}
