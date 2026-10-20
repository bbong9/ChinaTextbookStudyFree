import Foundation

/// packages/core/src/economyV2.ts 的纯函数镜像；不读写存档，不读取当前时钟。
extension Economy {
    struct Reward: Equatable, Codable {
        let gems: Int
        let xp: Int
    }

    struct StudyChest: Equatable, Codable {
        /// 同时作为每日领取账本中的档位标识。
        let minutes: Int
        let gems: Int
        let treats: Int
    }

    /// 新增数值集中于此，逐项镜像 core ECONOMY_V2；已有首答 XP、周末倍率沿用 Economy。
    enum V2 {
        static let levelXpFactor = 50
        static let levelDisplayCap = 99
        // D1：设计稿旧价为 1200 / 1500 / 2000 / 800，以下为定稿价格。
        static let pets: [Pets.Pet] = [
            .init(id: "pet_mituan", name: "米团", acquisition: .starter, price: 0,
                  skill: "学习陪伴；Lv5 起开花形态", floweringLevel: 5),
            .init(id: "pet_fox", name: "阿橘", acquisition: .purchase, price: 450,
                  skill: "数学小火车每局多 1 次提示"),
            .init(id: "pet_cat", name: "奶糖", acquisition: .purchase, price: 600,
                  skill: "识字闯关「练」每关多 1 次提示"),
            .init(id: "pet_penguin", name: "冰冰", acquisition: .purchase, price: 800,
                  skill: "英语气球里用英语鼓励你"),
            .init(id: "pet_owl", name: "博博", acquisition: .streak, price: 0,
                  skill: "课外书屋每日导读由博博朗读", requiredStreak: 7),
            .init(id: "pet_dragon", name: "云宝", acquisition: .level, price: 0,
                  skill: "成语动画专属解说开场", requiredLevel: 10),
            .init(id: "pet_egg", name: "神秘蛋", acquisition: .purchase, price: 300,
                  skill: "按固定顺序孵出小黄鸭 → 噜噜 → 咩咩"),
            .init(id: "pet_duck", name: "小黄鸭", acquisition: .egg, price: nil, skill: "无"),
            .init(id: "pet_pig", name: "噜噜", acquisition: .egg, price: nil, skill: "无"),
            .init(id: "pet_sheep", name: "咩咩", acquisition: .egg, price: nil, skill: "无"),
        ]
        static let eggHatchOrder = ["pet_duck", "pet_pig", "pet_sheep"]
        static let lessonTreatMinStars = 2
        static let lessonTreatReward = 1
        static let lessonTreatDailyCap = 5
        // 下标为周期日，0 留空；金币签到继续沿用 dailyRewardForStreak。
        static let checkInTreats = [0, 0, 0, 1, 0, 0, 1, 3]
        static let studyChests = [
            StudyChest(minutes: 10, gems: 10, treats: 0),
            StudyChest(minutes: 20, gems: 15, treats: 0),
            StudyChest(minutes: 30, gems: 20, treats: 2),
        ]
        static let miniGameGoodAccuracy = 0.8
        static let miniGameDailyRounds = 3
        static let miniGameGood = Reward(gems: 8, xp: 10)
        static let miniGameBase = Reward(gems: 3, xp: 5)
        static let idiomWatch = Reward(gems: 10, xp: 10)
        static let hanziChoiceQuestions = 6
        static let hanziWriteXp = 10
        static let hanziSpeakXp = 10
        static let readingMinutes = 15
        static let readingDaily = Reward(gems: 5, xp: 10)
        static let readingWeeklyDays = 5
        static let readingWeeklyGems = 30
    }

    static let studyChests = V2.studyChests

    /// 入参账本由调用方按本地日期取出，本函数不修改账本。
    static func lessonTreatReward(stars: Int, treatsFromLessonsToday: Int) -> Int {
        let received = max(0, treatsFromLessonsToday)
        guard stars >= V2.lessonTreatMinStars else { return 0 }
        return min(V2.lessonTreatReward, max(0, V2.lessonTreatDailyCap - received))
    }

    static func checkInCycleDay(_ effectiveStreak: Int) -> Int {
        ((max(1, effectiveStreak) - 1) % (V2.checkInTreats.count - 1)) + 1
    }

    /// 入参是周期日（1–7）；有效连胜应先经 checkInCycleDay 转换。
    static func checkInTreats(_ cycleDay: Int) -> Int {
        V2.checkInTreats.indices.contains(cycleDay) ? V2.checkInTreats[cycleDay] : 0
    }

    /// claimedToday 是本地当天已领取的分钟档位，例如 [10, 20]。
    static func claimableStudyChests(minutesToday: Double, claimedToday: [Int]) -> [StudyChest] {
        studyChests.filter { minutesToday >= Double($0.minutes) && !claimedToday.contains($0.minutes) }
    }

    /// 每个游戏、本地当天分别计数；XP 同时计入总 XP、今日 XP 与联赛。
    /// 周末只加倍 XP，金币不翻倍；isWeekend 由调用方按本地日期提供。
    static func miniGameReward(accuracy: Double, rewardedRoundsToday: Int, isWeekend: Bool = false) -> Reward {
        guard accuracy.isFinite, max(0, rewardedRoundsToday) < V2.miniGameDailyRounds else {
            return Reward(gems: 0, xp: 0)
        }
        let reward = accuracy >= V2.miniGameGoodAccuracy ? V2.miniGameGood : V2.miniGameBase
        return Reward(gems: reward.gems, xp: reward.xp * (isWeekend ? weekendXpMultiplier : 1))
    }

    /// 只在完整播放结束时调用，alreadyWatched 指该成语是否已领过首次观看奖励。
    static func idiomFirstWatchReward(alreadyWatched: Bool) -> Reward {
        alreadyWatched ? Reward(gems: 0, xp: 0) : V2.idiomWatch
    }

    /// 识字关卡基础 XP；星级、金币继续调用 starsFromAccuracy、lessonGemDrip。
    static func hanziLessonXp(firstTryCorrect: Int, wrote: Bool, spoke: Bool) -> Int {
        let correct = min(V2.hanziChoiceQuestions, max(0, firstTryCorrect))
        return correct * xpPerCorrect + (wrote ? V2.hanziWriteXp : 0) + (spoke ? V2.hanziSpeakXp : 0)
    }

    /// 日期键复用 Week（与 SRS.todayString 一致），now 显式传入。
    static func readingLogReward(minutesRead: Double, loggedDateKeys: [String], now: Date) -> Reward {
        guard minutesRead.isFinite, minutesRead >= Double(V2.readingMinutes),
              !loggedDateKeys.contains(Week.dateKey(now)) else { return Reward(gems: 0, xp: 0) }
        return V2.readingDaily
    }

    /// 本地周一至周日计数，去重并忽略周外及未来记录；claimedWeekKeys 是已领取周键。
    static func weeklyReadingChallengeReward(loggedDateKeys: [String], claimedWeekKeys: [String], now: Date) -> Int {
        let week = Week.weekStartKey(now)
        guard !claimedWeekKeys.contains(week) else { return 0 }
        let today = Week.dateKey(now)
        let weekDays = Set(Week.weekDateKeys(week))
        let recorded = Set(loggedDateKeys.filter { weekDays.contains($0) && $0 <= today })
        return recorded.count >= V2.readingWeeklyDays ? V2.readingWeeklyGems : 0
    }
}
