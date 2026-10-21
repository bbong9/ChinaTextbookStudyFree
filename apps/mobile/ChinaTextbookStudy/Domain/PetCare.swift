import Foundation

struct PetCareState: Codable, Hashable {
    /// 保留小数，避免每次启动舍掉不足一个衰减周期的时间。
    var fullness: Double
    var clean: Double
    var happy: Double
    /// 时间戳一律为 Unix 毫秒；nil 表示从未洗澡 / 玩耍。
    var updatedAt: Double
    var lastBathAt: Double?
    var lastPlayAt: Double?

    /// 备份字段级容错；损坏的单只宠物状态不影响其他宠物和整个备份。
    var validatedForBackup: PetCareState? {
        guard fullness.isFinite, clean.isFinite, happy.isFinite,
              updatedAt.isFinite, updatedAt >= 0 else { return nil }
        var state = self
        state.fullness = min(100, max(0, fullness))
        state.clean = min(100, max(0, clean))
        state.happy = min(100, max(0, happy))
        state.lastBathAt = lastBathAt.flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
        state.lastPlayAt = lastPlayAt.flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
        return state
    }
}

/// 只影响表情和台词，不读写存档、时钟、通知或经济数值。
enum PetCare {
    static let bathCooldown: TimeInterval = 4 * 3600
    static let playCooldown: TimeInterval = 3600

    static func initial(now: Date) -> PetCareState {
        PetCareState(fullness: 100, clean: 100, happy: 100,
                     updatedAt: now.timeIntervalSince1970 * 1000)
    }

    static func decay(_ state: PetCareState, now: Date) -> PetCareState {
        let nowMs = now.timeIntervalSince1970 * 1000
        let elapsedHours = (nowMs - state.updatedAt) / 3_600_000
        // 时钟回拨时连锚点也不改，回到原时间后才继续衰减。
        guard elapsedHours > 0 else { return state }
        var next = state
        next.fullness = max(20, state.fullness - elapsedHours * 10 / 8)
        next.clean = max(20, state.clean - elapsedHours * 10 / 12)
        next.happy = max(20, state.happy - elapsedHours * 10 / 12)
        next.updatedAt = nowMs
        return next
    }

    static func feed(_ state: PetCareState, now: Date) -> PetCareState {
        var next = decay(state, now: now)
        next.fullness = min(100, next.fullness + 25)
        next.happy = min(100, next.happy + 5)
        return next
    }

    static func bathe(_ state: PetCareState, now: Date) -> PetCareState? {
        let nowMs = now.timeIntervalSince1970 * 1000
        if let last = state.lastBathAt, nowMs - last < bathCooldown * 1000 { return nil }
        var next = decay(state, now: now)
        next.clean = 100
        next.lastBathAt = nowMs
        return next
    }

    static func play(_ state: PetCareState, now: Date) -> PetCareState? {
        let nowMs = now.timeIntervalSince1970 * 1000
        if let last = state.lastPlayAt, nowMs - last < playCooldown * 1000 { return nil }
        var next = decay(state, now: now)
        next.happy = min(100, next.happy + 30)
        next.lastPlayAt = nowMs
        return next
    }

    static func completeLesson(_ state: PetCareState, now: Date) -> PetCareState {
        var next = decay(state, now: now)
        next.happy = min(100, next.happy + 10)
        return next
    }

    static func mood(for state: PetCareState) -> MascotMood {
        state.happy < 40 ? .sad : .happy
    }

    static func message(for state: PetCareState) -> String? {
        state.fullness < 40 ? "肚子饿啦" : nil
    }
}
