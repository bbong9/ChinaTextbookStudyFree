import XCTest
@testable import ChinaTextbookStudy

final class PictureWordsTests: XCTestCase {
    func testCatalogHasFiftyUniqueWordsAndRequiredCategoryCounts() {
        XCTAssertEqual(PictureWords.all.count, 50)
        XCTAssertEqual(PictureWords.ids.count, 50)
        for (category, count) in [(PictureCategory.animals, 20), (.fruit, 10), (.transport, 10), (.body, 10)] {
            XCTAssertEqual(PictureWords.all.filter { $0.category == category }.count, count)
        }
        XCTAssertEqual(PictureCategory.animals.scenes, [.farm, .forest, .water])
        for scene in PictureScene.allCases { XCTAssertFalse(PictureWords.words(in: scene).isEmpty) }
        for word in PictureWords.all {
            XCTAssertFalse(word.char.isEmpty)
            XCTAssertFalse(word.pinyin.isEmpty)
            XCTAssertFalse(word.english.isEmpty)
            XCTAssertFalse(word.sound.isEmpty)
            XCTAssertLessThanOrEqual(word.char.count, word.id == "owl" ? 3 : 2)
        }
    }

    func testSevenClayAnimalsUseExistingKinds() {
        let clay = PictureWords.all.compactMap { word -> String? in
            if case .clay = word.art { return word.id }; return nil
        }
        XCTAssertEqual(Set(clay), ["duck", "pig", "sheep", "fox", "cat", "penguin", "owl"])
    }

    func testSeenCountIgnoresDuplicatesAndFutureIds() {
        XCTAssertEqual(PictureWords.seen(nil), [])
        XCTAssertEqual(PictureWords.seen(["sheep", "duck", "sheep", "future-word"]), ["sheep", "duck"])
    }

    func testEveryWordHasChineseAndSeparateEnglishSpeechFallback() {
        for word in PictureWords.all {
            SpeechTextIndex.shared.register(word)
            XCTAssertEqual(SpeechTextIndex.shared.text(for: word.nameAudio), word.char)
            XCTAssertEqual(SpeechTextIndex.shared.text(for: word.pinyinAudio), word.char)
            XCTAssertEqual(SpeechTextIndex.shared.text(for: word.soundAudio), word.sound)
            XCTAssertEqual(SpeechTextIndex.shared.text(for: word.englishAudio), word.english)
            XCTAssertTrue(SpeechTextIndex.isChinese(word.char))
            XCTAssertFalse(SpeechTextIndex.isChinese(word.english))
        }
    }

    @MainActor func testTextTokensMeetToddlerMinimums() {
        XCTAssertGreaterThanOrEqual(ClayFont.pictureCharacterSize, 72)
        XCTAssertGreaterThanOrEqual(ClayFont.picturePinyinSize, 24)
    }

    @MainActor func testAudioPlayerCanReadEveryEntryWithoutAnyNewRecording() {
        for word in PictureWords.all {
            SpeechTextIndex.shared.register(word)
            for path in word.chineseAudio + [word.englishAudio] {
                XCTAssertNil(AudioPlayer.shared.resolve(path))
                XCTAssertTrue(AudioPlayer.shared.canPlay(path))
            }
        }
    }
}

@MainActor
final class PictureWordsPersistenceTests: XCTestCase {
    private var savedProgress: Data?
    private var savedPrefs: Data?
    private let now = Date(timeIntervalSince1970: 1_792_569_600)

    override func setUp() async throws {
        savedProgress = try? Data(contentsOf: PersistenceService.url(for: "progress.json"))
        savedPrefs = try? Data(contentsOf: PersistenceService.url(for: "prefs.json"))
        let fresh = UserProgress(xp: 123, streak: 2, lastActiveDate: "2026-10-21", completedLessons: [:], mistakesBank: [])
        try PersistenceService.write(fresh, to: "progress.json")
    }

    override func tearDown() async throws {
        for (name, data) in [("progress.json", savedProgress), ("prefs.json", savedPrefs)] {
            let url = PersistenceService.url(for: name)
            if let data { try data.write(to: url) }
            else if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
        }
    }

    func testDiscoveryPersistsAcrossNewStoreWithoutAnyRewardOrOtherMutation() throws {
        let store = ProgressStore(now: now)
        let before = store.progress
        store.discoverPictureWord("sheep")
        store.discoverPictureWord("sheep")
        store.discoverPictureWord("apple")
        store.discoverPictureWord("unknown-word")
        var expected = before
        expected.pictureWordsSeen = ["sheep", "apple"]
        XCTAssertEqual(store.progress, expected)
        XCTAssertEqual(PersistenceService.read(UserProgress.self, from: "progress.json"), expected)
        let restarted = ProgressStore(now: now)
        XCTAssertEqual(restarted.pictureWordsSeen, ["sheep", "apple"])
        XCTAssertEqual(restarted.progress.xp, before.xp)
        XCTAssertEqual(restarted.progress.gems, before.gems)
    }

    func testAllFiftyDiscoveriesAreIdempotentAndKeepFutureIds() throws {
        var p = try XCTUnwrap(PersistenceService.read(UserProgress.self, from: "progress.json"))
        p.pictureWordsSeen = ["future-word"]
        try PersistenceService.write(p, to: "progress.json")
        let store = ProgressStore(now: now)
        for _ in 0..<2 { for word in PictureWords.all { store.discoverPictureWord(word.id) } }
        XCTAssertEqual(store.pictureWordsSeen.count, 50)
        XCTAssertEqual(store.progress.pictureWordsSeen?.count, 51)
        XCTAssertEqual(store.progress.pictureWordsSeen?.first, "future-word")
    }

    func testOldSaveDecodesWithEmptyAlbum() throws {
        let legacy = try JSONDecoder().decode(UserProgress.self, from: Data("""
        {"xp":0,"streak":0,"lastActiveDate":"","completedLessons":{},"mistakesBank":[]}
        """.utf8))
        XCTAssertNil(legacy.pictureWordsSeen)
        XCTAssertEqual(PictureWords.seen(legacy.pictureWordsSeen), [])
    }
}

final class PictureWordsBackupTests: XCTestCase {
    private var fixtures: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures")
    }

    func testTSBackupImportsAndIOSExportRoundTripsWithoutLosingUnknownIds() throws {
        let fixture = fixtures.appendingPathComponent("picture-words-ts.json")
        let source = try Backup.validate(Data(contentsOf: fixture)).get()
        let now = Date(timeIntervalSince1970: 1_792_569_600)
        let p = Backup.userProgress(from: source, now: now, today: "2026-10-21")
        XCTAssertEqual(p.pictureWordsSeen, ["duck", "sheep", "apple", "future-word"])
        let exported = Backup.makeEnvelope(from: p, exportedAt: now)
        let raw = try Backup.encode(exported)
        XCTAssertEqual(try Backup.validate(raw).get().data.pictureWordsSeen, p.pictureWordsSeen)
        XCTAssertEqual(Backup.userProgress(from: exported, now: now).pictureWordsSeen, p.pictureWordsSeen)
        // 生产编码器输出，供 core / 网页真实 store 回环验证。
        let root = fixtures.deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let output = root.appendingPathComponent("output/rd-16/picture-words-ios.json")
        try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
        try raw.write(to: output, options: .atomic)
    }

    func testMalformedFieldIsIgnoredAndPartiallyBadArrayKeepsStrings() throws {
        for field in ["42", "null", "{}", "true"] {
            let raw = Data("{\"schema\":\"cstf-backup\",\"version\":1,\"data\":{\"gems\":12,\"pictureWordsSeen\":\(field)}}".utf8)
            let envelope = try Backup.validate(raw).get()
            XCTAssertNil(envelope.data.pictureWordsSeen)
            XCTAssertEqual(envelope.data.gems, 12)
        }
        let raw = Data("""
        {"schema":"cstf-backup","version":1,"data":{"pictureWordsSeen":["sheep",42,"future-word",null]}}
        """.utf8)
        XCTAssertEqual(try Backup.validate(raw).get().data.pictureWordsSeen, ["sheep", "future-word"])
    }

    func testMissingFieldStaysMissingAndEmptyAlbumStaysEmpty() throws {
        for field in ["", "\"pictureWordsSeen\":[]"] {
            let raw = Data("{\"schema\":\"cstf-backup\",\"version\":1,\"data\":{\(field)}}".utf8)
            let envelope = try Backup.validate(raw).get()
            XCTAssertEqual(envelope.data.pictureWordsSeen, field.isEmpty ? nil : [])
        }
    }
}
