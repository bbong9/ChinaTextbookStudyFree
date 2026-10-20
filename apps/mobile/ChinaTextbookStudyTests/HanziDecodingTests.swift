import XCTest
import ZIPFoundation
@testable import ChinaTextbookStudy

/// 从实际随 App 打包的 seed 解压，验证字卡、共享笔顺与首启后的目录契约。
final class HanziDecodingTests: XCTestCase {
    private var directory: URL!
    private var loader: DataLoader!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("rd12-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let seed = try XCTUnwrap(Bundle.main.url(forResource: "seed-data", withExtension: "zip"))
        try FileManager.default.unzipItem(at: seed, to: directory)
        loader = DataLoader(dataRoot: directory.appendingPathComponent("data"))
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
    }

    func testAllSeedCharactersDecodeAndMergeSharedStrokes() throws {
        let index = try XCTUnwrap(loader.loadHanziIndex(bookId: "chinese-g1up"))
        XCTAssertEqual(index.status, .draft)
        XCTAssertEqual(index.units.map(\.unitNumber), [2, 6])
        let chars = Set(index.units.flatMap(\.chars))
        XCTAssertEqual(chars.count, 100)
        let charDirectory = loader.sandboxDataRoot.appendingPathComponent("hanzi/chinese-g1up/chars")
        let files = try FileManager.default.contentsOfDirectory(atPath: charDirectory.path).filter { $0.hasSuffix(".json") }
        XCTAssertEqual(files.count, chars.count)
        for char in chars.sorted() {
            let loaded = try XCTUnwrap(loader.loadHanziChar(bookId: index.bookId, char: char), char)
            XCTAssertEqual(loaded.char, char)
            XCTAssertEqual(loaded.status, .draft)
            XCTAssertTrue(loaded.words.allSatisfy { $0.status == .draft && $0.text.contains(char) })
            XCTAssertEqual(loaded.strokeNames.count, loaded.strokeCount)
            XCTAssertEqual(loaded.strokes.count, loaded.strokeCount, char)
            XCTAssertEqual(loaded.strokeAttribution?.license, "Arphic Public License")
            XCTAssertTrue(loaded.origin?.forms.isEmpty ?? true)
            XCTAssertTrue(loaded.unihan.readings.contains(loaded.pinyin))
            XCTAssertFalse(loaded.pinyinAlternates.contains(loaded.pinyin))
            // 合并后的 APL 数据不能经字卡 Codable 写回到内容文件。
            let encoded = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(loaded)) as? [String: Any])
            XCTAssertNil(encoded["strokes"])
            XCTAssertNil(encoded["strokeAttribution"])
        }
        for file in ["LICENSE", "README.md"] {
            XCTAssertTrue(FileManager.default.fileExists(atPath: loader.sandboxDataRoot.appendingPathComponent("hanzi/strokes/\(file)").path))
        }
        print("RD-12：实际 seed 中 100 个字卡全部解码并合并共享笔顺。")
    }

    func testMissingStrokeFileKeepsCharacterWithEmptyStrokes() throws {
        try FileManager.default.removeItem(at: loader.sandboxDataRoot.appendingPathComponent("hanzi/strokes/5c71.json"))
        let character = try XCTUnwrap(loader.loadHanziChar(bookId: "chinese-g1up", char: "山"))
        XCTAssertEqual(character.strokeCount, 3)
        XCTAssertTrue(character.strokes.isEmpty)
        XCTAssertNil(character.strokeAttribution)
    }

    func testMissingMalformedOrUnsafeRequestsReturnNil() throws {
        XCTAssertNil(loader.loadHanziIndex(bookId: "missing"))
        XCTAssertNil(loader.loadHanziIndex(bookId: "../chinese-g1up"))
        XCTAssertNil(loader.loadHanziChar(bookId: "missing", char: "山"))
        XCTAssertNil(loader.loadHanziChar(bookId: "chinese-g1up", char: "山山"))
        XCTAssertNil(loader.loadHanziChar(bookId: "chinese-g1up", char: ""))
        try Data("broken json".utf8).write(to: loader.sandboxDataRoot.appendingPathComponent("hanzi/chinese-g1up/index.json"))
        try Data("broken json".utf8).write(to: loader.sandboxDataRoot.appendingPathComponent("hanzi/chinese-g1up/chars/5c71.json"))
        XCTAssertNil(loader.loadHanziIndex(bookId: "chinese-g1up"))
        XCTAssertNil(loader.loadHanziChar(bookId: "chinese-g1up", char: "山"))
    }

    func testCorruptStrokeFileAndMissingLicenseDegradeToEmpty() throws {
        let file = loader.sandboxDataRoot.appendingPathComponent("hanzi/strokes/5c71.json")
        let original = try Data(contentsOf: file)
        try Data("broken json".utf8).write(to: file)
        XCTAssertTrue(try XCTUnwrap(loader.loadHanziChar(bookId: "chinese-g1up", char: "山")).strokes.isEmpty)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: original) as? [String: Any])
        object["license"] = ""
        try JSONSerialization.data(withJSONObject: object).write(to: file)
        XCTAssertTrue(try XCTUnwrap(loader.loadHanziChar(bookId: "chinese-g1up", char: "山")).strokes.isEmpty)
    }

    @MainActor
    func testWithoutRecordingsRegistersTextAndStartsSystemTTS() async throws {
        let character = try XCTUnwrap(loader.loadHanziChar(bookId: "chinese-g1up", char: "山"))
        let paths = [character.audio.char, character.audio.pinyin] + character.words.map(\.audio) + [try XCTUnwrap(character.audio.origin)]
        for path in paths {
            XCTAssertNil(AudioPlayer.shared.resolve(path), "试点未内置录音")
            XCTAssertNotNil(SpeechTextIndex.shared.text(for: path))
            XCTAssertTrue(AudioPlayer.shared.canPlay(path))
        }
        XCTAssertEqual(SpeechTextIndex.shared.text(for: character.audio.char), "山")
        XCTAssertEqual(SpeechTextIndex.shared.text(for: character.audio.pinyin), "山")
        XCTAssertEqual(SpeechTextIndex.shared.text(for: character.words[0].audio), character.words[0].text)
        XCTAssertEqual(SpeechTextIndex.shared.text(for: try XCTUnwrap(character.audio.origin)), character.origin?.explanation)
        let settings = SettingsStore.shared
        let muted = settings.isMuted
        settings.isMuted = false
        defer { AudioPlayer.shared.stop(); settings.isMuted = muted }
        AudioPlayer.shared.play(path: character.audio.char, settings: settings)
        XCTAssertTrue(AudioPlayer.shared.isPlaying)
        XCTAssertEqual(AudioPlayer.shared.nowPlayingPath, "tts-0")
        print("RD-12：无任何试点录音，山/拼音/组词/字源均可回退，已启动系统 TTS 队列。")
    }
}
