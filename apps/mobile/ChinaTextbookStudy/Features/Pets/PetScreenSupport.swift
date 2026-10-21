import SwiftUI

/// 页面时钟集中注入；台词、照顾和倒计时共用同一时刻。
enum PetScreenClock {
    static func now() -> Date {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uitest"),
           let value = PetScreenTestSeed.value("-uitest-pet-now"), let seconds = Double(value) {
            return Date(timeIntervalSince1970: seconds)
        }
        #endif
        return Date()
    }
}

enum PetScreenCopy {
    /// 神秘蛋是消耗品；孵出过任一伙伴即点亮蛋的图鉴位，不把蛋写入拥有列表。
    static func discoveredEgg(_ owned: [String]) -> Bool {
        Economy.V2.eggHatchOrder.contains { owned.contains($0) }
    }

    static func collectionCount(_ owned: [String]) -> Int {
        Pets.pets.filter { owned.contains($0.id) || ($0.id == "pet_egg" && discoveredEgg(owned)) }.count
    }

    static func condition(_ pet: Pets.Pet) -> String {
        if let level = pet.requiredLevel { return "Lv\(level) 解锁" }
        if let days = pet.requiredStreak { return "连签 \(days) 天" }
        switch pet.acquisition {
        case .starter: return "初始伙伴"
        case .egg: return "神秘蛋孵出"
        default: return "\(pet.price ?? 0) 金币"
        }
    }

    static func adoptionTitle(_ pet: Pets.Pet, status: PetAdoptionStatus, gems: Int) -> String {
        switch status {
        case .available: return pet.id == "pet_egg" ? "\(pet.price ?? 0) 金币 · 孵化" : "\(pet.price ?? 0) 金币 · 领养"
        case .alreadyOwned: return "已领养 · 去看看"
        case .soldOut: return "已孵完"
        case .insufficientGems: return "还差 \(max(0, (pet.price ?? 0) - gems)) 金币"
        case .insufficientLevel, .insufficientStreak: return condition(pet)
        }
    }

    static func introduction(_ id: String) -> String {
        switch id {
        case "pet_fox": return "爱跑步的小狐狸"
        case "pet_cat": return "温柔好奇的小猫咪"
        case "pet_penguin": return "爱说英语的小企鹅"
        case "pet_owl": return "爱读书的小博士"
        case "pet_dragon": return "腾云驾雾的故事伙伴"
        case "pet_egg": return "下一位伙伴在蛋里等你"
        default: return "一起学习，一起长大"
        }
    }

    static func remaining(last: Double?, cooldown: TimeInterval, now: Date) -> Int {
        guard let last else { return 0 }
        let seconds = ceil(last / 1000 + cooldown - now.timeIntervalSince1970)
        return Int(min(Double(Int.max / 2), max(0, seconds)))
    }

    static func countdown(_ seconds: Int) -> String {
        let seconds = max(0, seconds)
        if seconds >= 3600 {
            return String(format: "%d:%02d:%02d", seconds / 3600, seconds / 60 % 60, seconds % 60)
        }
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    static func message(care: PetCareState, progress: UserProgress, now: Date) -> String {
        if care.fullness < 40 { return "肚子饿啦，想吃一块饼干！" }
        if care.clean < 40 { return "洗个香香澡，再一起冒险吧！" }
        if care.happy < 40 { return "陪我玩一会儿球，好吗？" }
        let today = SRS.todayString(now: now)
        let lessons = progress.completedLessons.values.filter { result in
            guard let date = ISO8601DateFormatter().date(from: result.completedAt) else { return false }
            return SRS.todayString(now: date) == today
        }.count
        if lessons > 0 { return "今天学了 \(lessons) 节课，我好开心！" }
        if let last = care.lastBathAt, now.timeIntervalSince1970 * 1000 - last < 60_000 {
            return "香喷喷的，谢谢你照顾我！"
        }
        if let last = care.lastPlayAt, now.timeIntervalSince1970 * 1000 - last < 60_000 {
            return "和你玩球最开心啦！"
        }
        return "今天也一起去学点新知识吧！"
    }

    static func growth(_ pet: Pets.Pet, xp: Int) -> String {
        let level = Level.levelInfo(xp)
        if let bloom = pet.floweringLevel, level.level < bloom {
            let threshold = Economy.V2.levelXpFactor * bloom * (bloom - 1)
            return "再得 \(max(0, threshold - xp)) 经验 → 开花形态"
        }
        return "再得 \(level.xpForNextLevel - level.xpIntoLevel) 经验 → Lv\(level.level + 1)"
    }
}

struct PetPortrait: View {
    let kind: PetKind
    var size: CGFloat
    var unavailable = false
    var unknownEgg = false
    var body: some View {
        PetView(kind: unknownEgg ? .egg : kind, size: size, accessory: .noAccessory)
            .saturation(unavailable ? 0 : 1)
            .opacity(unavailable ? 0.55 : 1)
            .overlay {
                if unknownEgg { Text("？").font(ClayFont.title).foregroundStyle(ClayColor.ink) }
            }
    }
}

struct PetCoin: View {
    var size: CGFloat = 22
    var body: some View {
        ClayGradient.gold.view.clipShape(Circle())
            .overlay { Circle().strokeBorder(ClayColor.coinEdge, lineWidth: 1) }
            .overlay { Image(systemName: "star.fill").font(ClayFont.nunito(size: size * 0.55)).foregroundStyle(ClayColor.coinEmblem) }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct PetBalance: View {
    let gems: Int
    var body: some View {
        HStack(spacing: 7) {
            PetCoin()
            Text(gems.formatted()).font(ClayFont.nunito(size: 18))
        }
        .foregroundStyle(ClayColor.statText)
        .padding(.horizontal, 10).frame(height: 34)
        .background(ClayColor.white.opacity(0.94), in: Capsule())
        .clayShadow(.stat)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("金币余额")
        .accessibilityValue(String(gems))
        .accessibilityIdentifier("pet-balance")
    }
}

#if DEBUG
/// 仅在 -uitest 下生效，测试数值通过启动参数提供，不写入正式存档结构。
enum PetScreenTestSeed {
    static func value(_ key: String) -> String? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.lastIndex(of: key), args.indices.contains(index + 1) else { return nil }
        return args[index + 1]
    }

    static func apply(to progress: inout UserProgress, now: Date) {
        guard ProcessInfo.processInfo.arguments.contains("-uitest") else { return }
        let instant = value("-uitest-pet-now").flatMap(Double.init).map(Date.init(timeIntervalSince1970:)) ?? now
        if let gems = value("-uitest-pet-gems").flatMap(Int.init) { progress.gems = max(0, gems) }
        if let treats = value("-uitest-pet-treats").flatMap(Int.init) { progress.petTreats = max(0, treats) }
        if let owned = value("-uitest-pet-owned") {
            progress.ownedPets = [PetState.starterId] + owned.split(separator: ",").map(String.init).filter {
                $0 != PetState.starterId && $0 != "pet_egg" && Pets.petById($0) != nil
            }
        }
        if let id = value("-uitest-pet-active"), progress.ownedPets?.contains(id) == true { progress.activePet = id }
        if value("-uitest-pet-care") == "hungry" {
            progress.petCare = Dictionary(uniqueKeysWithValues: (progress.ownedPets ?? []).map {
                ($0, PetCareState(fullness: 30, clean: 60, happy: 70, updatedAt: instant.timeIntervalSince1970 * 1000))
            })
        } else { PetState.settleCare(&progress, now: instant) }
        if value("-uitest-pet-legacy") == "owned" {
            progress.ownedCosmetics = ["theme_sakura", "backdrop_forest"]
            progress.equippedTheme = "theme_sakura"
            progress.equippedBackdrop = "backdrop_forest"
        }
    }
}
#endif
