import XCTest
@testable import ChinaTextbookStudy

final class PetScreenLogicTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_792_483_200)

    func testShopCopiesAllFiveStatesUsingCatalogPrice() throws {
        let fox = try XCTUnwrap(Pets.petById("pet_fox"))
        XCTAssertEqual(PetScreenCopy.adoptionTitle(fox, status: .available, gems: 1000), "\(fox.price!) 金币 · 领养")
        XCTAssertEqual(PetScreenCopy.adoptionTitle(fox, status: .insufficientGems, gems: fox.price! - 7), "还差 7 金币")
        XCTAssertEqual(PetScreenCopy.adoptionTitle(fox, status: .alreadyOwned, gems: 0), "已领养 · 去看看")
        let dragon = try XCTUnwrap(Pets.petById("pet_dragon"))
        XCTAssertEqual(PetScreenCopy.adoptionTitle(dragon, status: .insufficientLevel, gems: 0), "Lv\(dragon.requiredLevel!) 解锁")
        XCTAssertEqual(PetScreenCopy.adoptionTitle(Pets.petById("pet_egg")!, status: .soldOut, gems: 1000), "已孵完")
    }

    func testCooldownUsesInjectedTimeAndCeilsPartialSecond() {
        let last = now.timeIntervalSince1970 * 1000
        XCTAssertEqual(PetScreenCopy.remaining(last: last, cooldown: PetCare.playCooldown, now: now), Int(PetCare.playCooldown))
        XCTAssertEqual(PetScreenCopy.remaining(last: last, cooldown: PetCare.playCooldown, now: now.addingTimeInterval(PetCare.playCooldown - 0.1)), 1)
        XCTAssertEqual(PetScreenCopy.remaining(last: last, cooldown: PetCare.playCooldown, now: now.addingTimeInterval(PetCare.playCooldown)), 0)
        XCTAssertEqual(PetScreenCopy.remaining(last: nil, cooldown: PetCare.bathCooldown, now: now), 0)
        XCTAssertEqual(PetScreenCopy.countdown(3661), "1:01:01")
        XCTAssertEqual(PetScreenCopy.countdown(59), "00:59")
    }

    func testCareDialogueHasSevenContextualBranchesAndLocalDayBoundary() {
        var progress = UserProgress(xp: 0, streak: 0, lastActiveDate: "", completedLessons: [:], mistakesBank: [])
        var care = PetCare.initial(now: now)
        var messages: Set<String> = []
        messages.insert(PetScreenCopy.message(care: care, progress: progress, now: now))
        care.fullness = 30
        messages.insert(PetScreenCopy.message(care: care, progress: progress, now: now))
        care.fullness = 100; care.clean = 30
        messages.insert(PetScreenCopy.message(care: care, progress: progress, now: now))
        care.clean = 100; care.happy = 30
        messages.insert(PetScreenCopy.message(care: care, progress: progress, now: now))
        care.happy = 100; care.lastBathAt = now.timeIntervalSince1970 * 1000
        messages.insert(PetScreenCopy.message(care: care, progress: progress, now: now))
        care.lastBathAt = nil; care.lastPlayAt = now.timeIntervalSince1970 * 1000
        messages.insert(PetScreenCopy.message(care: care, progress: progress, now: now))
        progress.completedLessons = ["today": LessonResult(lessonId: "today", stars: 3, accuracy: 1,
            completedAt: ISO8601DateFormatter().string(from: now))]
        let learned = PetScreenCopy.message(care: care, progress: progress, now: now)
        XCTAssertTrue(learned.contains("1 节课"))
        messages.insert(learned)
        XCTAssertEqual(messages.count, 7)
        XCTAssertFalse(PetScreenCopy.message(care: care, progress: progress, now: now.addingTimeInterval(86400)).contains("1 节课"))
    }

    func testGrowthUsesLevelThresholdAndOnlyMituanFlowers() throws {
        let mituan = try XCTUnwrap(Pets.petById(PetState.starterId))
        let threshold = Economy.V2.levelXpFactor * mituan.floweringLevel! * (mituan.floweringLevel! - 1)
        XCTAssertEqual(PetScreenCopy.growth(mituan, xp: threshold - 1), "再得 1 经验 → 开花形态")
        XCTAssertFalse(PetScreenCopy.growth(mituan, xp: threshold).contains("开花"))
        XCTAssertTrue(PetScreenCopy.growth(Pets.petById("pet_fox")!, xp: 0).contains("Lv2"))
    }

    func testHatchingHasThreeShakesThenThreeCracksBreakAndReveal() {
        XCTAssertEqual(EggHatchPhase.allCases.prefix(6).map(\.angle), [-12, 12, -12, 12, -12, 12])
        XCTAssertEqual([EggHatchPhase.crack1, .crack2, .crack3].map(\.crack), [1, 2, 3])
        XCTAssertEqual(Array(EggHatchPhase.allCases.suffix(2)), [.broken, .revealed])
    }

    func testConsumedEggCatalogSlotIsDiscoveredWithoutOwningAnEgg() {
        XCTAssertEqual(PetScreenCopy.collectionCount([PetState.starterId]), 1)
        XCTAssertEqual(PetScreenCopy.collectionCount([PetState.starterId, "pet_duck"]), 3)
        let allCompanions = Pets.pets.filter { $0.id != "pet_egg" }.map(\.id)
        XCTAssertEqual(PetScreenCopy.collectionCount(allCompanions), Pets.pets.count)
    }
}
