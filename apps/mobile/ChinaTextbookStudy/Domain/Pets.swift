import Foundation

/// packages/core/src/pets.ts 的镜像；仅目录与资格判断，不扣款、不写存档。
enum Pets {
    enum Acquisition: String, Codable {
        case starter, purchase, streak, level, egg
    }

    struct Pet: Equatable, Codable {
        let id: String
        let name: String
        let acquisition: Acquisition
        /// 孵化伙伴没有售价，不能把 nil 当作免费购买。
        let price: Int?
        let skill: String
        var floweringLevel: Int? = nil
        var requiredStreak: Int? = nil
        var requiredLevel: Int? = nil
    }

    struct UnlockContext: Codable {
        let gems: Int
        let level: Int
        let claimedStreakRewards: [Int]
        let owned: [String]
    }

    static let pets = Economy.V2.pets

    static func petById(_ id: String) -> Pet? {
        pets.first { $0.id == id }
    }

    /// D4：按固定顺序返回首个未拥有的孵化伙伴；集齐后返回 nil。
    static func nextEggHatch(_ owned: [String]) -> String? {
        Economy.V2.eggHatchOrder.first { !owned.contains($0) }
    }

    static func canUnlock(_ pet: Pet?, ctx: UnlockContext) -> Bool {
        guard let pet else { return false }
        // 蛋是消耗品，允许重复购买，直到三只孵化伙伴都已拥有。
        if pet.id == "pet_egg" {
            guard let price = pet.price else { return false }
            return ctx.gems >= price && nextEggHatch(ctx.owned) != nil
        }
        guard !ctx.owned.contains(pet.id) else { return false }
        switch pet.acquisition {
        case .starter: return true
        case .purchase:
            guard let price = pet.price else { return false }
            return ctx.gems >= price
        case .streak:
            guard let required = pet.requiredStreak else { return false }
            return ctx.claimedStreakRewards.contains(required)
        case .level:
            guard let required = pet.requiredLevel else { return false }
            return ctx.level >= required
        case .egg: return false
        }
    }
}
