import XCTest
import Combine
@testable import ChinaTextbookStudy

@MainActor
final class PetStateTests: XCTestCase {
    private var savedProgress: Data?
    private var savedPrefs: Data?
    private var store: ProgressStore!
    private let now = Date(timeIntervalSince1970: 1_792_483_200)

    override func setUp() async throws {
        savedProgress = try? Data(contentsOf: PersistenceService.url(for: "progress.json"))
        savedPrefs = try? Data(contentsOf: PersistenceService.url(for: "prefs.json"))
        var fresh = UserProgress(xp: 0, streak: 0, lastActiveDate: "", completedLessons: [:], mistakesBank: [])
        PetState.migrate(&fresh)
        PetState.settleCare(&fresh, now: now)
        store = try boot(fresh)
    }

    override func tearDown() async throws {
        store = nil
        for (name, data) in [("progress.json", savedProgress), ("prefs.json", savedPrefs)] {
            let url = PersistenceService.url(for: name)
            if let data { try data.write(to: url) }
            else if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
        }
    }

    private func boot(_ p: UserProgress, at date: Date? = nil) throws -> ProgressStore {
        try PersistenceService.write(p, to: "progress.json")
        return ProgressStore(now: date ?? now)
    }

    private func seeded(gems: Int = 0, fullness: Double = 50, clean: Double = 50, happy: Double = 50) throws {
        var p = store.progress
        p.gems = gems
        p.petCare = [PetState.starterId: PetCareState(fullness: fullness, clean: clean, happy: happy,
                                                    updatedAt: now.timeIntervalSince1970 * 1000)]
        store = try boot(p)
    }

    func testAdoptionPublishesAndPersistsOwnershipWithDebitTogether() throws {
        let price = try XCTUnwrap(Pets.petById("pet_fox")?.price)
        try seeded(gems: price + 20)
        var observed: [UserProgress] = []
        let subscription = store.$progress.dropFirst().sink { observed.append($0) }
        XCTAssertEqual(store.adopt("pet_fox", now: now), "pet_fox")
        withExtendedLifetime(subscription) {}
        // 订阅所有发布，不能观察到「已扣钱但还没写拥有」的中间状态。
        XCTAssertEqual(observed.count, 1)
        XCTAssertEqual(observed.first?.gems, 20)
        XCTAssertEqual(observed.first?.ownedPets, ["pet_mituan", "pet_fox"])
        let disk = try XCTUnwrap(PersistenceService.read(UserProgress.self, from: "progress.json"))
        XCTAssertEqual(disk, store.progress)
        XCTAssertEqual(store.canAdopt("pet_fox"), .alreadyOwned)
        let after = store.progress
        XCTAssertNil(store.adopt("pet_fox", now: now))
        XCTAssertEqual(store.progress, after)
    }

    func testInsufficientGemsDoesNotMutateOrDebit() throws {
        let price = try XCTUnwrap(Pets.petById("pet_cat")?.price)
        try seeded(gems: price - 1)
        let before = store.progress
        XCTAssertEqual(store.canAdopt("pet_cat"), .insufficientGems)
        XCTAssertNil(store.adopt("pet_cat", now: now))
        XCTAssertEqual(store.progress, before)
        XCTAssertEqual(store.canAdopt("unknown"), .soldOut)
        XCTAssertEqual(store.canAdopt("pet_duck"), .soldOut)
    }

    func testLevelUnlockUsesRD05LevelInfo() throws {
        let required = try XCTUnwrap(Pets.petById("pet_dragon")?.requiredLevel)
        let threshold = Economy.V2.levelXpFactor * required * (required - 1)
        var p = store.progress
        p.xp = threshold - 1
        store = try boot(p)
        XCTAssertEqual(store.canAdopt("pet_dragon"), .insufficientLevel)
        XCTAssertNil(store.adopt("pet_dragon", now: now))
        p.xp = threshold
        store = try boot(p)
        XCTAssertEqual(Level.levelInfo(store.progress.xp).level, required)
        XCTAssertEqual(store.adopt("pet_dragon", now: now), "pet_dragon")
        XCTAssertEqual(store.gems, 0)
    }

    func testStreakUnlockUsesClaimedMilestoneLedger() throws {
        let required = try XCTUnwrap(Pets.petById("pet_owl")?.requiredStreak)
        var p = store.progress
        p.streak = required
        p.claimedStreakRewards = []
        store = try boot(p)
        XCTAssertEqual(store.canAdopt("pet_owl"), .insufficientStreak)
        XCTAssertNil(store.adopt("pet_owl", now: now))
        p.claimedStreakRewards = [required]
        store = try boot(p)
        XCTAssertEqual(store.adopt("pet_owl", now: now), "pet_owl")
        XCTAssertEqual(store.gems, 0)
    }

    func testEggHatchesInFixedOrderAndThenSellsOut() throws {
        let price = try XCTUnwrap(Pets.petById("pet_egg")?.price)
        try seeded(gems: price * 4)
        XCTAssertEqual(store.adopt("pet_egg", now: now), "pet_duck")
        XCTAssertEqual(store.hatchEgg(now: now), "pet_pig")
        XCTAssertEqual(store.hatchEgg(now: now), "pet_sheep")
        XCTAssertFalse(store.ownedPets.contains("pet_egg"))
        XCTAssertEqual(store.ownedPets, ["pet_mituan", "pet_duck", "pet_pig", "pet_sheep"])
        XCTAssertEqual(store.gems, price)
        XCTAssertEqual(store.canAdopt("pet_egg"), .soldOut)
        let after = store.progress
        XCTAssertNil(store.hatchEgg(now: now))
        XCTAssertEqual(store.progress, after)
        store = ProgressStore(now: now)
        XCTAssertEqual(store.canAdopt("pet_egg"), .soldOut)
    }

    func testDoubleTapAdoptionDebitsOnlyOnce() throws {
        let price = try XCTUnwrap(Pets.petById("pet_fox")?.price)
        try seeded(gems: price * 3)
        XCTAssertEqual(store.adopt("pet_fox", now: now), "pet_fox")
        XCTAssertNil(store.adopt("pet_fox", now: now))
        XCTAssertEqual(store.gems, price * 2)
        XCTAssertEqual(store.ownedPets.filter { $0 == "pet_fox" }.count, 1)
    }

    func testDuplicateEggRequestDebitsOnceAndNextConfirmationHatchesNextPet() throws {
        let price = try XCTUnwrap(Pets.petById("pet_egg")?.price)
        try seeded(gems: price * 4)
        let request = UUID()
        XCTAssertEqual(store.adopt("pet_egg", requestId: request, now: now), "pet_duck")
        XCTAssertNil(store.hatchEgg(requestId: request, now: now))
        XCTAssertEqual(store.gems, price * 3)
        XCTAssertFalse(store.ownedPets.contains("pet_pig"))
        XCTAssertEqual(store.hatchEgg(requestId: UUID(), now: now), "pet_pig")
        XCTAssertEqual(store.gems, price * 2)
    }

    func testFeedWithoutTreatDoesNothing() throws {
        try seeded()
        let before = store.progress
        XCTAssertEqual(store.petTreats, 0)
        XCTAssertEqual(store.feedUnavailableReason, "去闯关赚饼干")
        XCTAssertFalse(store.feed(now: now))
        XCTAssertEqual(store.progress, before)
    }

    func testFeedConsumesOneTreatAndCapsCareWithoutChangingEconomy() throws {
        try seeded(gems: 500, fullness: 90, happy: 98)
        var p = store.progress
        p.petTreats = 2
        store = try boot(p)
        let xp = store.progress.xp
        let gems = store.gems
        XCTAssertTrue(store.feed(now: now))
        XCTAssertEqual(store.petTreats, 1)
        let care = store.careState(for: store.activePet, now: now)
        XCTAssertEqual(care.fullness, 100)
        XCTAssertEqual(care.happy, 100)
        XCTAssertEqual(care.clean, 50)
        XCTAssertEqual(store.gems, gems)
        XCTAssertEqual(store.progress.xp, xp)
        store = ProgressStore(now: now)
        XCTAssertEqual(store.petTreats, 1)
        XCTAssertEqual(store.careState(for: store.activePet, now: now), care)
    }

    func testBathCooldownAndClockRollbackSurviveRelaunch() throws {
        try seeded()
        XCTAssertTrue(store.bathe(now: now))
        XCTAssertEqual(store.careState(for: store.activePet, now: now).clean, 100)
        store = ProgressStore(now: now)
        let before = store.progress
        XCTAssertFalse(store.bathe(now: now.addingTimeInterval(-1)))
        XCTAssertFalse(store.bathe(now: now.addingTimeInterval(PetCare.bathCooldown - 1)))
        XCTAssertEqual(store.progress, before)
        XCTAssertTrue(store.bathe(now: now.addingTimeInterval(PetCare.bathCooldown)))
        XCTAssertEqual(store.gems, 0)
    }

    func testPlayCooldownAndClockRollbackSurviveRelaunch() throws {
        try seeded()
        XCTAssertTrue(store.play(now: now))
        XCTAssertEqual(store.careState(for: store.activePet, now: now).happy, 80)
        store = ProgressStore(now: now)
        let before = store.progress
        XCTAssertFalse(store.play(now: now.addingTimeInterval(-1)))
        XCTAssertFalse(store.play(now: now.addingTimeInterval(PetCare.playCooldown - 1)))
        XCTAssertEqual(store.progress, before)
        XCTAssertTrue(store.play(now: now.addingTimeInterval(PetCare.playCooldown)))
        XCTAssertEqual(store.careState(for: store.activePet, now: now.addingTimeInterval(PetCare.playCooldown)).happy, 100)
        XCTAssertEqual(store.gems, 0)
    }

    func testDecayAfterThreeDaysStopsAtFloorAndNeverDropsFurther() {
        var initial = PetCare.initial(now: now)
        initial.fullness = 80
        initial.clean = 80
        initial.happy = 80
        let after = PetCare.decay(initial, now: now.addingTimeInterval(3 * 24 * 3600))
        XCTAssertEqual(after.fullness, 20)
        XCTAssertEqual(after.clean, 20)
        XCTAssertEqual(after.happy, 20)
        let later = PetCare.decay(after, now: now.addingTimeInterval(100 * 24 * 3600))
        XCTAssertEqual(later.fullness, 20)
        XCTAssertEqual(later.clean, 20)
        XCTAssertEqual(later.happy, 20)
    }

    func testDecayUsesSpecifiedRatesFromFullState() {
        let after = PetCare.decay(PetCare.initial(now: now), now: now.addingTimeInterval(3 * 24 * 3600))
        XCTAssertEqual(after.fullness, 20)
        // 按卡片明确速率：干净 / 开心每 12 小时 -10，100 起算 72 小时后为 40。
        XCTAssertEqual(after.clean, 40)
        XCTAssertEqual(after.happy, 40)
    }

    func testDecayIsIndependentOfOpenFrequencyAndKeepsFractionalTime() {
        let initial = PetCare.initial(now: now)
        var frequent = initial
        for minute in 1...900 {
            frequent = PetCare.decay(frequent, now: now.addingTimeInterval(Double(minute) * 60))
        }
        let once = PetCare.decay(initial, now: now.addingTimeInterval(900 * 60))
        XCTAssertEqual(frequent.fullness, once.fullness, accuracy: 0.0000001)
        XCTAssertEqual(frequent.clean, once.clean, accuracy: 0.0000001)
        XCTAssertEqual(frequent.happy, once.happy, accuracy: 0.0000001)
        XCTAssertEqual(frequent.updatedAt, once.updatedAt)
    }

    func testNegativeElapsedTimeLeavesEntireStateUnchanged() {
        let state = PetCare.initial(now: now)
        XCTAssertEqual(PetCare.decay(state, now: now.addingTimeInterval(-3600)), state)
        XCTAssertEqual(PetCare.decay(state, now: now), state)
    }

    func testLaunchSettlesPersistedCareAndReadIsPure() throws {
        let original = store.progress
        let later = now.addingTimeInterval(12 * 3600)
        store = try boot(original, at: later)
        XCTAssertEqual(store.careState(for: store.activePet, now: later).fullness, 85)
        XCTAssertEqual(store.careState(for: store.activePet, now: later).clean, 90)
        XCTAssertEqual(store.progress.petCare?[store.activePet]?.updatedAt, later.timeIntervalSince1970 * 1000)
        let before = store.progress
        _ = store.careState(for: store.activePet, now: later.addingTimeInterval(3600))
        XCTAssertEqual(store.progress, before)
    }

    func testLegacyFixtureLaunchAndMigrationAreIdempotent() throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Fixtures/legacy-progress-eaeff4f.json")
        let data = try Data(contentsOf: url)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        for key in ["ownedPets", "activePet", "petTreats", "treatsFromLessonsDate",
                    "treatsFromLessonsCount", "petCare", "petAccessory", "petsMigrated"] {
            XCTAssertNil(json[key])
        }
        let legacy = try JSONDecoder().decode(UserProgress.self, from: data)
        var migrated = legacy
        PetState.migrate(&migrated)
        let once = migrated
        PetState.migrate(&migrated)
        XCTAssertEqual(migrated, once)
        store = try boot(legacy)
        XCTAssertEqual(store.ownedPets, ["pet_mituan"])
        XCTAssertEqual(store.activePet, "pet_mituan")
        XCTAssertEqual(store.petTreats, 0)
        XCTAssertEqual(store.petAccessory["pet_mituan"], "skin_graduate")
        XCTAssertEqual(store.progress.petsMigrated, true)
        XCTAssertEqual(store.progress.ownedCosmetics, legacy.ownedCosmetics)
        XCTAssertEqual(store.progress.equippedMascotSkin, legacy.equippedMascotSkin)
        XCTAssertEqual(store.progress.gems, legacy.gems)
        XCTAssertEqual(store.progress.lifetimeGems, legacy.lifetimeGems)
        XCTAssertTrue(store.setAccessory(nil, for: "pet_mituan"))
        store = ProgressStore(now: now)
        XCTAssertNil(store.petAccessory["pet_mituan"], "二次启动不能重新戴回旧皮肤")
    }

    func testActivePetAndAccessoryRequireOwnershipAndSkinType() throws {
        try seeded(gems: 1000)
        XCTAssertFalse(store.setActivePet("pet_fox"))
        XCTAssertFalse(store.setAccessory("skin_graduate", for: "pet_mituan"))
        let skin = try XCTUnwrap(Cosmetics.item(id: "skin_graduate"))
        XCTAssertTrue(store.buyCosmetic(skin))
        XCTAssertTrue(store.setAccessory(skin.id, for: "pet_mituan"))
        XCTAssertFalse(store.setAccessory("theme_default", for: "pet_mituan"))
        XCTAssertFalse(store.setAccessory(skin.id, for: "pet_fox"))
        XCTAssertNotNil(store.adopt("pet_fox", now: now))
        XCTAssertTrue(store.setActivePet("pet_fox"))
        XCTAssertTrue(store.setAccessory(skin.id, for: "pet_fox"))
        store = ProgressStore(now: now)
        XCTAssertEqual(store.activePet, "pet_fox")
        XCTAssertEqual(store.petAccessory["pet_fox"], skin.id)
    }

    func testPetEnvironmentFollowsActivePetAccessoryAndCareChanges() throws {
        var p = store.progress
        p.ownedPets = ["pet_mituan", "pet_fox"]
        p.ownedCosmetics = ["skin_graduate", "skin_glasses"]
        p.petAccessory = ["pet_mituan": "skin_graduate", "pet_fox": "skin_glasses"]
        p.petCare = [
            "pet_mituan": PetCare.initial(now: now),
            "pet_fox": PetCareState(fullness: 50, clean: 50, happy: 35,
                                     updatedAt: now.timeIntervalSince1970 * 1000),
        ]
        store = try boot(p)
        XCTAssertEqual(PetEnvironment(progressStore: store, now: now),
                       PetEnvironment(kind: .mituan, accessory: .graduate, mood: .happy))
        XCTAssertTrue(store.setActivePet("pet_fox"))
        XCTAssertEqual(PetEnvironment(progressStore: store, now: now),
                       PetEnvironment(kind: .fox, accessory: .glasses, mood: .sad))
        XCTAssertTrue(store.play(now: now))
        XCTAssertTrue(store.setAccessory(nil, for: "pet_fox"))
        XCTAssertEqual(PetEnvironment(progressStore: store, now: now),
                       PetEnvironment(kind: .fox, accessory: .noAccessory, mood: .happy))
        XCTAssertTrue(store.setActivePet("pet_mituan"))
        XCTAssertEqual(PetEnvironment(progressStore: store, now: now).accessory, .graduate)
    }

    func testPetEnvironmentUsesElapsedCareWithoutMutatingProgress() throws {
        try seeded(happy: 45)
        let before = store.progress
        XCTAssertEqual(PetEnvironment(progressStore: store, now: now).mood, .happy)
        XCTAssertEqual(PetEnvironment(progressStore: store, now: now.addingTimeInterval(12 * 3600)).mood, .sad)
        XCTAssertEqual(store.progress, before, "展示环境只能派生，不能重复结算或保存照顾状态")
    }

    func testSixthLessonTreatIsCappedAndNextDayResetsLedger() {
        for index in 0..<6 {
            let outcome = store.completeLesson(lessonId: "g1up-u1-kp\(index)", correctCount: 4, questionCount: 5, now: now)
            XCTAssertEqual(outcome.treatsGained, index < Economy.V2.lessonTreatDailyCap ? 1 : 0)
        }
        XCTAssertEqual(store.petTreats, Economy.V2.lessonTreatDailyCap)
        XCTAssertEqual(store.progress.treatsFromLessonsCount, Economy.V2.lessonTreatDailyCap)
        let nextDay = now.addingTimeInterval(24 * 3600)
        let low = store.completeLesson(lessonId: "chinese-g1up-u1-kp1", correctCount: 0, questionCount: 5, now: nextDay)
        XCTAssertEqual(low.treatsGained, 0)
        let next = store.completeLesson(lessonId: "english-g1up-u1-kp1", correctCount: 5, questionCount: 5, now: nextDay)
        XCTAssertEqual(next.treatsGained, 1)
        XCTAssertEqual(store.progress.treatsFromLessonsDate, SRS.todayString(now: nextDay))
        XCTAssertEqual(store.progress.treatsFromLessonsCount, 1)
        XCTAssertEqual(store.petTreats, Economy.V2.lessonTreatDailyCap + 1)
    }

    func testLessonRaisesOnlyActivePetHappinessAndCareDoesNotAffectEconomy() throws {
        try seeded(gems: 1000)
        XCTAssertNotNil(store.adopt("pet_fox", now: now))
        XCTAssertTrue(store.setActivePet("pet_fox"))
        var p = store.progress
        p.petCare?["pet_fox"]?.happy = 25
        store = try boot(p)
        let sadOutcome = store.completeLesson(lessonId: "g1up-u1-kp1", correctCount: 5, questionCount: 5, now: now)
        XCTAssertEqual(store.careState(for: "pet_fox", now: now).happy, 35)
        XCTAssertEqual(store.careState(for: "pet_mituan", now: now).happy, 50)
        p.petCare?["pet_fox"]?.happy = 100
        store = try boot(p)
        let happyOutcome = store.completeLesson(lessonId: "g1up-u1-kp1", correctCount: 5, questionCount: 5, now: now)
        XCTAssertEqual(sadOutcome, happyOutcome)
    }

    func testMoodAndHungerMessageThresholds() {
        var state = PetCare.initial(now: now)
        state.happy = 39
        state.fullness = 39
        XCTAssertEqual(PetCare.mood(for: state), .sad)
        XCTAssertEqual(PetCare.message(for: state), "肚子饿啦")
        state.happy = 40
        state.fullness = 40
        XCTAssertEqual(PetCare.mood(for: state), .happy)
        XCTAssertNil(PetCare.message(for: state))
    }

    func testImportedTreatLedgerAndCareCooldownsSurviveRelaunch() throws {
        let fixture = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Fixtures/pet-backup-ts.json")
        let envelope = try Backup.validate(Data(contentsOf: fixture)).get()
        store.importBackup(envelope, now: now)
        XCTAssertEqual(store.progress.petCare, envelope.data.petCare)
        XCTAssertFalse(store.bathe(now: now))
        XCTAssertFalse(store.play(now: now))
        let outcome = store.completeLesson(lessonId: "g1up-u1-kp1", correctCount: 5, questionCount: 5, now: now)
        XCTAssertEqual(outcome.treatsGained, 0, "导入不能清掉当天已领满的课程饼干账本")
        XCTAssertTrue(store.feed(now: now))
        XCTAssertNil(store.feedUnavailableReason)
        store = ProgressStore(now: now)
        XCTAssertEqual(store.activePet, "pet_fox")
        XCTAssertEqual(store.petTreats, 3)
        XCTAssertEqual(store.progress.treatsFromLessonsCount, 5)
        XCTAssertEqual(store.petAccessory, envelope.data.petAccessory)
        XCTAssertFalse(store.bathe(now: now))
        XCTAssertFalse(store.play(now: now))
    }

    func testOldBackupImportPersistsInitialCareClockImmediately() throws {
        let fixture = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Fixtures/legacy-progress-eaeff4f.json")
        let legacy = try JSONDecoder().decode(UserProgress.self, from: Data(contentsOf: fixture))
        store.importBackup(Backup.makeEnvelope(from: legacy, exportedAt: now), now: now)
        XCTAssertEqual(store.progress.petCare?["pet_mituan"]?.updatedAt, now.timeIntervalSince1970 * 1000)
        let later = now.addingTimeInterval(12 * 3600)
        XCTAssertEqual(store.careState(for: "pet_mituan", now: later).fullness, 85)
        XCTAssertEqual(store.careState(for: "pet_mituan", now: later).clean, 90)
    }
}
