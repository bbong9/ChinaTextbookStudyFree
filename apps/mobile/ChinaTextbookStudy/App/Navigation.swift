import Foundation

/// 根导航栈的全部目的地，由 MainShell 中的 RouteView 统一解析。
enum AppRoute: Hashable {
    #if DEBUG
    case clayGallery
    #endif
    case league
    case bookList(grade: Int)
    case bookDetail(bookId: String)
    case lesson(bookId: String, lessonId: String)
    case lessonResult(LessonRunResult)
    case review
    case reviewRunner
    case achievements
    case stories(bookId: String)
    case storyReader(bookId: String, storyId: String)
    case reading(bookId: String)
    case passageReader(bookId: String, passageId: String)
    case shop
    case profile
    case settings
    /// 单元知识手册（Wave E2）：聚合该单元各课 knowledge 的左右滑卡片页。
    case guide(bookId: String, unitNumber: Int)
    /// 跳级测试（Wave E2）：锁定单元 banner「⚡ 跳到这里」入口。
    case jumpTest(bookId: String, unitNumber: Int)

    // RD-01：只接通路由，实际内容由后续开发卡替换。
    case petFamily
    case petHome
    case petShop
    case checkIn
    case quests
    case parentCenter
    case hanziMap(bookId: String)
    case hanziLesson(bookId: String, char: String)
    case mathTrain
    case englishBalloons
    case animals
    case idiomPicker
    case idiomPlayer(id: String)
    case bedtimeStories
    case readingRoom

    struct Placeholder {
        let id: String
        let title: String
    }

    var placeholder: Placeholder? {
        switch self {
        case .petFamily: return .init(id: "pet-family", title: "宠物家族")
        case .petHome: return .init(id: "pet-home", title: "宠物小屋")
        case .petShop: return .init(id: "pet-shop", title: "宠物店")
        case .checkIn: return .init(id: "check-in", title: "签到")
        case .quests: return .init(id: "quests", title: "任务")
        case .parentCenter: return .init(id: "parent-center", title: "家长中心")
        case .hanziMap: return .init(id: "hanzi-map", title: "识字地图")
        case .hanziLesson: return .init(id: "hanzi-lesson", title: "识字关卡")
        case .mathTrain: return .init(id: "math-train", title: "数学小火车")
        case .englishBalloons: return .init(id: "english-balloons", title: "英语单词气球")
        case .animals: return .init(id: "animals", title: "看图识物")
        case .idiomPicker: return .init(id: "idiom-picker", title: "成语选择")
        case .idiomPlayer: return .init(id: "idiom-player", title: "成语动画")
        case .bedtimeStories: return .init(id: "bedtime-stories", title: "睡前绘本")
        case .readingRoom: return .init(id: "reading-room", title: "课外书屋")
        default: return nil
        }
    }

    /// 临时入口的参数只用于验证路由，不加载或生成新内容。
    static func temporaryRoutes(bookId: String) -> [AppRoute] {
        [.petFamily, .petHome, .petShop, .checkIn, .quests, .parentCenter,
         .hanziMap(bookId: bookId), .hanziLesson(bookId: bookId, char: "日"),
         .mathTrain, .englishBalloons, .animals, .idiomPicker,
         .idiomPlayer(id: "shou-zhu-dai-tu"), .bedtimeStories, .readingRoom]
    }

    /// 沉浸页面已有自己的退出操作，其余页面由外壳提供临时页头。
    var shellTitle: String? {
        if let placeholder { return placeholder.title }
        switch self {
        case .league: return "排行"
        case .bookList(let grade): return "\(grade) 年级"
        case .bookDetail: return "课本"
        case .review: return "错题本"
        case .reviewRunner: return "错题复习"
        case .achievements: return "成就墙"
        case .stories: return "故事"
        case .storyReader: return "故事阅读"
        case .reading: return "课文阅读"
        case .passageReader: return "阅读"
        case .shop: return "商店"
        case .profile: return "我的"
        case .settings: return "设置"
        case .guide: return "单元知识手册"
        default: return nil
        }
    }
}

/// Result of committing a finished lesson to the store — single source of
/// truth for the XP/streak numbers the result screen celebrates.
struct LessonOutcome: Hashable {
    var xpGained: Int = 0
    var stars: Int = 1
    var streakBefore: Int = 0
    var streakAfter: Int = 0
    var dailyGoalReachedNow: Bool = false
    var gemsGained: Int = 0
    var newAchievements: [Achievement] = []
    /// Streak-milestone gems banked by this lesson (0 = no milestone hit).
    var milestoneGems: Int = 0
    /// Whether the weekend ×2 multiplier was applied to `xpGained`.
    var weekendDoubled: Bool = false
    /// Streak shields consumed covering missed days (ios-economy-6) — the
    /// result screen shows「❄️ 护盾保住了你的连胜」when > 0.
    var freezesConsumed: Int = 0
    /// Whether the unit-challenge ×2 multiplier was applied to `xpGained`
    /// (Wave E1) — the result screen shows the「⚔️ 挑战双倍 ×2」badge.
    var examDoubled: Bool = false
    /// RD-06：本次课程实际发放的饼干（达到每日上限时为 0）。
    var treatsGained: Int = 0
    var streakIncreased: Bool { streakAfter > streakBefore }
}

/// Snapshot pushed onto the navigation stack after a lesson finishes.
struct LessonRunResult: Hashable {
    let bookId: String
    let lessonId: String
    let lessonTitle: String
    let questionCount: Int
    let correctCount: Int
    var outcome: LessonOutcome = LessonOutcome()
    var accuracy: Double {
        guard questionCount > 0 else { return 0 }
        return Double(correctCount) / Double(questionCount)
    }
    var stars: Int { Economy.starsFromAccuracy(accuracy) }
}
