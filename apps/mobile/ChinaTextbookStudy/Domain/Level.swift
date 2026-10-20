import Foundation

/// packages/core/src/level.ts 的纯函数镜像；等级从累计 XP 推导，不新增存档字段。
enum Level {
    struct Info: Equatable, Codable {
        let level: Int
        let xpIntoLevel: Int
        /// 从当前实际等级升到下一级所需 XP（不是累计 XP）。
        let xpForNextLevel: Int
    }

    /// 只把显示等级封顶 99；超过后 XP 及升级进度仍按实际等级继续计算。
    static func levelInfo(_ totalXp: Int) -> Info {
        let xp = max(0, totalXp)
        let factor = Economy.V2.levelXpFactor
        let actualLevel = Int(floor((1 + sqrt(1 + 4 * Double(xp) / Double(factor))) / 2))
        return Info(
            level: min(Economy.V2.levelDisplayCap, actualLevel),
            xpIntoLevel: xp - factor * actualLevel * (actualLevel - 1),
            xpForNextLevel: 2 * factor * actualLevel
        )
    }
}
