import XCTest
@testable import ChinaTextbookStudy

final class PetBackupTests: XCTestCase {
    private var fixtures: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures")
    }
    private let now = Date(timeIntervalSince1970: 1_792_483_200)

    private func tsEnvelope() throws -> Backup.Envelope {
        let data = try Data(contentsOf: fixtures.appendingPathComponent("pet-backup-ts.json"))
        return try Backup.validate(data).get()
    }

    func testTSGeneratedBackupImportsEveryPetFieldUnchanged() throws {
        let envelope = try tsEnvelope()
        let p = Backup.userProgress(from: envelope, now: now, today: "2026-10-20")
        XCTAssertEqual(p.ownedPets, ["pet_mituan", "pet_fox", "pet_duck"])
        XCTAssertEqual(p.activePet, "pet_fox")
        XCTAssertEqual(p.petTreats, 4)
        XCTAssertEqual(p.treatsFromLessonsDate, "2026-10-20")
        XCTAssertEqual(p.treatsFromLessonsCount, 5)
        XCTAssertEqual(p.petCare, envelope.data.petCare)
        XCTAssertEqual(p.petAccessory, envelope.data.petAccessory)
        XCTAssertEqual(p.petsMigrated, true)
        XCTAssertNil(p.petCare?["pet_mituan"]?.lastBathAt)
        XCTAssertEqual(p.petCare?["pet_fox"]?.lastBathAt, 1_792_479_600_000)
    }

    func testIOSExportMatchesFixtureAndRoundTripsEveryPetField() throws {
        let source = try tsEnvelope()
        let p = Backup.userProgress(from: source, now: now, today: "2026-10-20")
        let exported = Backup.makeEnvelope(from: p, exportedAt: now)
        let raw = try Backup.encode(exported)
        // 留下真正由 iOS 生产代码生成的输出，供 TS validateBackup 验收。
        let root = fixtures.deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let output = root.appendingPathComponent("output/rd-06/ios-pet-backup.json")
        try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
        try raw.write(to: output, options: .atomic)
        let fixture = try Backup.validate(Data(contentsOf: fixtures.appendingPathComponent("pet-backup-ios.json"))).get()
        XCTAssertEqual(exported, fixture)
        let roundTrip = Backup.userProgress(from: try Backup.validate(raw).get(), now: now, today: "2026-10-20")
        XCTAssertEqual(roundTrip.ownedPets, p.ownedPets)
        XCTAssertEqual(roundTrip.activePet, p.activePet)
        XCTAssertEqual(roundTrip.petTreats, p.petTreats)
        XCTAssertEqual(roundTrip.treatsFromLessonsDate, p.treatsFromLessonsDate)
        XCTAssertEqual(roundTrip.treatsFromLessonsCount, p.treatsFromLessonsCount)
        XCTAssertEqual(roundTrip.petCare, p.petCare)
        XCTAssertEqual(roundTrip.petAccessory, p.petAccessory)
        XCTAssertEqual(roundTrip.petsMigrated, p.petsMigrated)
    }

    func testOldBackupMigratesLegacySkinAndPreservesCurrencyAndOwnership() throws {
        let legacyData = try Data(contentsOf: fixtures.appendingPathComponent("legacy-progress-eaeff4f.json"))
        let legacy = try JSONDecoder().decode(UserProgress.self, from: legacyData)
        let envelope = Backup.makeEnvelope(from: legacy, exportedAt: now)
        XCTAssertNil(envelope.data.petsMigrated)
        let p = Backup.userProgress(from: try Backup.validate(Backup.encode(envelope)).get(), now: now)
        XCTAssertEqual(p.ownedPets, ["pet_mituan"])
        XCTAssertEqual(p.activePet, "pet_mituan")
        XCTAssertEqual(p.petTreats, 0)
        XCTAssertEqual(p.petAccessory, ["pet_mituan": "skin_graduate"])
        XCTAssertEqual(Set(p.ownedCosmetics ?? []), Set(legacy.ownedCosmetics ?? []))
        XCTAssertEqual(p.gems, legacy.gems)
    }

    func testBadPetFieldsDoNotRejectBackupOrValidCareEntries() throws {
        let raw = Data("""
        {"schema":"cstf-backup","version":1,"data":{
          "petTreats":-1,"treatsFromLessonsCount":2.5,"petsMigrated":"true",
          "ownedPets":["pet_mituan",42],
          "petAccessory":{"pet_mituan":"skin_graduate","pet_fox":false},
          "petCare":{
            "pet_mituan":{"fullness":120,"clean":-10,"happy":50,"updatedAt":123},
            "pet_fox":{"fullness":"bad","clean":90,"happy":90,"updatedAt":123},
            "pet_cat":{"fullness":90,"clean":90,"happy":90,"updatedAt":-1}
          },"unknownFutureField":true
        }}
        """.utf8)
        let envelope = try Backup.validate(raw).get()
        XCTAssertNil(envelope.data.petTreats)
        XCTAssertNil(envelope.data.treatsFromLessonsCount)
        XCTAssertNil(envelope.data.petsMigrated)
        XCTAssertEqual(envelope.data.ownedPets, ["pet_mituan"])
        XCTAssertEqual(envelope.data.petAccessory, ["pet_mituan": "skin_graduate"])
        XCTAssertEqual(envelope.data.petCare, ["pet_mituan": PetCareState(fullness: 100, clean: 0, happy: 50, updatedAt: 123)])
    }
}
