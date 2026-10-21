import XCTest
import ZIPFoundation
@testable import ChinaTextbookStudy

final class StoryReadingTests: XCTestCase {
    private var directory: URL!
    private var loader: DataLoader!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("rd19-\(UUID().uuidString)")
        let seed = try XCTUnwrap(Bundle.main.url(forResource: "seed-data", withExtension: "zip"))
        try FileManager.default.unzipItem(at: seed, to: directory)
        loader = DataLoader(dataRoot: directory.appendingPathComponent("data"))
    }

    override func tearDownWithError() throws { try FileManager.default.removeItem(at: directory) }

    func testEveryGeneratedSeedPinyinRowMatchesOriginalStory() throws {
        let index = try loader.loadSiteIndex()
        var books = 0, stories = 0, sentences = 0
        for book in index.books {
            guard let document = try loader.loadStories(bookId: book.id) else { continue }
            let sidecar = loader.loadStoryPinyin(bookId: book.id)
            for story in document.stories where !StoryReading.isEnglish(story.language) {
                let rows = try XCTUnwrap(StoryReading.pinyin(sidecar?[story.id], for: story), story.id)
                for (row, sentence) in zip(rows, story.sentences) {
                    XCTAssertEqual(row.count, sentence.text.count)
                    for (character, reading) in zip(sentence.text, row) where character.unicodeScalars.allSatisfy({ CharacterSet.punctuationCharacters.contains($0) }) {
                        XCTAssertEqual(reading, "")
                    }
                }
                stories += 1; sentences += rows.count
            }
            if sidecar != nil { books += 1 }
        }
        XCTAssertEqual(books, 12); XCTAssertEqual(stories, 188); XCTAssertEqual(sentences, 4110)
    }

    func testMissingMalformedUnsafeAndMisalignedPinyinDegradeToNil() throws {
        XCTAssertNil(loader.loadStoryPinyin(bookId: "missing"))
        XCTAssertNil(loader.loadStoryPinyin(bookId: "../chinese-g1up"))
        let story = try XCTUnwrap(loader.loadStories(bookId: "chinese-g1up")?.stories.first)
        XCTAssertNil(StoryReading.pinyin(nil, for: story))
        XCTAssertNil(StoryReading.pinyin([["wrong"]], for: story))
        try Data("invalid".utf8).write(to: loader.sandboxDataRoot.appendingPathComponent("story-pinyin/chinese-g1up.json"))
        XCTAssertNil(loader.loadStoryPinyin(bookId: "chinese-g1up"))
    }

    func testEnglishLanguageAliasesNeverShowRuby() throws {
        var story = try XCTUnwrap(loader.loadStories(bookId: "english-g3up")?.stories.first)
        let rows = story.sentences.map { Array(repeating: "", count: $0.text.count) }
        for language in ["en", "English", "EN"] {
            story.language = language
            XCTAssertTrue(StoryReading.isEnglish(language))
            XCTAssertNil(StoryReading.pinyin(rows, for: story))
        }
    }

    func testRecordingTimelineSkipsPunctuationAndUsesEqualCharacterSlots() {
        let text = "“一，二！三。”"
        XCTAssertEqual(StoryReading.highlight(text: text, elapsed: 0, duration: 6), 1)
        XCTAssertEqual(StoryReading.highlight(text: text, elapsed: 1.99, duration: 6), 1)
        XCTAssertEqual(StoryReading.highlight(text: text, elapsed: 2, duration: 6), 3)
        XCTAssertEqual(StoryReading.highlight(text: text, elapsed: 4, duration: 6), 5)
        XCTAssertEqual(StoryReading.highlight(text: text, elapsed: 99, duration: 6), 5)
        XCTAssertNil(StoryReading.highlight(text: "？！", elapsed: 1, duration: 2))
        XCTAssertNil(StoryReading.highlight(text: text, elapsed: .nan, duration: 2))
        XCTAssertNil(StoryReading.highlight(text: text, elapsed: 1, duration: 0))
    }

    func testSpeechRangeConvertsUTF16WithoutSplittingCharacters() {
        XCTAssertEqual(StoryReading.characterIndex(text: "🌙晚安", speechRange: NSRange(location: 2, length: 1)), 1)
        XCTAssertNil(StoryReading.characterIndex(text: "晚安", speechRange: NSRange(location: 10, length: 1)))
    }

    func testNormalFinalPageEntersExistingQuizAndBackStaysInBounds() {
        var flow = StoryPageFlow(count: 2, bedtime: false, hasQuestions: true)
        flow.previous(); XCTAssertEqual(flow.page, 0)
        XCTAssertNil(flow.next()); XCTAssertEqual(flow.page, 1)
        XCTAssertEqual(flow.next(), .quiz)
        flow.previous(); XCTAssertEqual(flow.page, 0)
    }

    func testBedtimeFinalPageAlwaysEndsWithoutQuizOrReward() {
        for hasQuestions in [true, false] {
            var flow = StoryPageFlow(count: 8, bedtime: true, hasQuestions: hasQuestions)
            for _ in 0..<7 { XCTAssertNil(flow.next()) }
            XCTAssertEqual(flow.next(), .goodnight)
            XCTAssertEqual(flow.page, 7)
        }
        var noQuestions = StoryPageFlow(count: 1, bedtime: false, hasQuestions: false)
        XCTAssertEqual(noQuestions.next(), .completion)
    }

    func testQuizRewardBoundaryAndCanonicalReadingKeyAreUnchanged() throws {
        XCTAssertEqual(Economy.storyQuizXp(accuracy: 0), 5)
        XCTAssertEqual(Economy.storyQuizXp(accuracy: 0.799999), 5)
        XCTAssertEqual(Economy.storyQuizXp(accuracy: 0.8), 15)
        XCTAssertEqual(Economy.storyQuizXp(accuracy: 1), 15)
        let story = try XCTUnwrap(loader.loadStories(bookId: "chinese-g1up")?.stories.first)
        XCTAssertEqual(Reading.id(.story, story.id), "reading:story:chinese-g1up-s1-v2")
        for source in story.questions {
            let adapted = StoryReaderView.question(from: source)
            let answer = source.type == "choice" ? source.options.firstIndex(of: source.answer)
                .flatMap { Unicode.Scalar(65 + $0) }.map(String.init) ?? source.answer : source.answer
            XCTAssertTrue(Grade.gradeAnswer(question: adapted, userAnswer: answer))
        }
    }

    @MainActor func testNilRecordingPathStillStartsSystemSpeech() {
        let settings = SettingsStore.shared
        let muted = settings.isMuted
        settings.isMuted = false
        defer { AudioPlayer.shared.stop(); settings.isMuted = muted }
        AudioPlayer.shared.play(text: "晚安，小朋友。", audioPath: nil)
        XCTAssertTrue(AudioPlayer.shared.isPlaying)
        XCTAssertEqual(AudioPlayer.shared.nowPlayingPath, "tts-0")
        XCTAssertNil(AudioPlayer.shared.recordingDuration)
    }
}
