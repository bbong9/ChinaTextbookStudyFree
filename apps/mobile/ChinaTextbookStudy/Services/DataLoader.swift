import Foundation

enum DataLoaderError: Error, LocalizedError {
    case seedIndexMissing
    case bookNotDownloaded(String)
    case lessonNotFound(String)

    var errorDescription: String? {
        switch self {
        case .seedIndexMissing:
            return "Bundle 内未找到 seed-index.json"
        case .bookNotDownloaded(let id):
            return "教材 \(id) 尚未下载"
        case .lessonNotFound(let id):
            return "课程 \(id) 不存在"
        }
    }
}

/// Reads the user-facing data layout that mirrors apps/web/public/data/.
///
/// Layout under sandbox `Application Support/cstf/data/`:
///
///     index.json
///     books/<bookId>/outline.json
///     books/<bookId>/passages.json   (optional)
///     books/<bookId>/stories.json    (optional)
///     books/<bookId>/lessons/<lessonId>.json
///
/// The same shape is used for the bundled seed (read-only) so that the
/// first launch can still display a bookshelf without network access.
final class DataLoader {
    static let shared = DataLoader()

    private let dataRootOverride: URL?

    /// 测试可用独立的 seed 解压目录，不读写真实沙盒数据。
    init(dataRoot: URL? = nil) {
        dataRootOverride = dataRoot
    }

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    // MARK: - Sandbox roots

    /// `Application Support/cstf/data/`
    var sandboxDataRoot: URL {
        if let dataRootOverride { return dataRootOverride }
        let fm = FileManager.default
        let base = (try? fm.url(for: .applicationSupportDirectory,
                                in: .userDomainMask,
                                appropriateFor: nil,
                                create: true)) ?? fm.temporaryDirectory
        return base.appendingPathComponent("cstf/data", isDirectory: true)
    }

    /// `Application Support/cstf/audio/`
    var sandboxAudioRoot: URL {
        sandboxDataRoot.deletingLastPathComponent().appendingPathComponent("audio", isDirectory: true)
    }

    // MARK: - Index

    /// Load the canonical SiteIndex, falling back to the bundled seed on first launch.
    func loadSiteIndex() throws -> SiteIndex {
        let sandboxIndex = sandboxDataRoot.appendingPathComponent("index.json")
        if FileManager.default.fileExists(atPath: sandboxIndex.path) {
            return try decode(SiteIndex.self, from: sandboxIndex)
        }
        return try loadSeedIndex()
    }

    /// Read the bundled seed index (offline bookshelf placeholder).
    func loadSeedIndex() throws -> SiteIndex {
        guard let url = Bundle.main.url(forResource: "seed-index", withExtension: "json") else {
            throw DataLoaderError.seedIndexMissing
        }
        return try decode(SiteIndex.self, from: url)
    }

    // MARK: - Book-scoped loads

    func loadOutline(bookId: String) throws -> Outline {
        let url = bookDir(bookId).appendingPathComponent("outline.json")
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw DataLoaderError.bookNotDownloaded(bookId)
        }
        return try decode(Outline.self, from: url)
    }

    func loadLesson(bookId: String, lessonId: String) throws -> Lesson {
        let url = bookDir(bookId)
            .appendingPathComponent("lessons", isDirectory: true)
            .appendingPathComponent("\(lessonId).json")
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw DataLoaderError.lessonNotFound(lessonId)
        }
        let lesson = try decode(Lesson.self, from: url)
        SpeechTextIndex.shared.register(lesson)
        return lesson
    }

    /// 某节课的文件是否存在于本地（Wave E1：outline 声明了 examLessonId
    /// 但旧资产包没有对应文件时，路径上的挑战节点隐藏）。
    func lessonExists(bookId: String, lessonId: String) -> Bool {
        let url = bookDir(bookId)
            .appendingPathComponent("lessons", isDirectory: true)
            .appendingPathComponent("\(lessonId).json")
        return FileManager.default.fileExists(atPath: url.path)
    }

    func loadPassages(bookId: String) throws -> BookPassages? {
        let url = bookDir(bookId).appendingPathComponent("passages.json")
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let passages = try decode(BookPassages.self, from: url)
        SpeechTextIndex.shared.register(passages)
        return passages
    }

    func loadStories(bookId: String) throws -> BookStories? {
        let url = bookDir(bookId).appendingPathComponent("stories.json")
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let stories = try decode(BookStories.self, from: url)
        SpeechTextIndex.shared.register(stories)
        return stories
    }

    // MARK: - Hanzi（缺失或损坏均返回 nil；缺笔顺仍可读字卡）

    func loadHanziIndex(bookId: String) -> HanziIndex? {
        guard let directory = hanziBookDir(bookId),
              let index = try? decode(HanziIndex.self, from: directory.appendingPathComponent("index.json")),
              index.bookId == bookId, index.version == 1 else { return nil }
        return index
    }

    func loadHanziChar(bookId: String, char: String) -> HanziCharacter? {
        guard let directory = hanziBookDir(bookId), char.unicodeScalars.count == 1,
              let scalar = char.unicodeScalars.first else { return nil }
        let filename = String(scalar.value, radix: 16) + ".json"
        let charURL = directory.appendingPathComponent("chars", isDirectory: true).appendingPathComponent(filename)
        guard var character = try? decode(HanziCharacter.self, from: charURL),
              character.char == char, character.origin?.forms.isEmpty != false else { return nil }
        let strokeURL = sandboxDataRoot.appendingPathComponent("hanzi/strokes", isDirectory: true)
            .appendingPathComponent(filename)
        if let data = try? decode(HanziStrokeData.self, from: strokeURL),
           data.char == char, data.strokes.count == character.strokeCount,
           data.strokes.allSatisfy({ stroke in
               !stroke.outline.isEmpty && stroke.median.count >= 2 && stroke.median.allSatisfy { point in
                   point.count == 2 && point.allSatisfy { $0.isFinite && (0...1024).contains($0) }
               }
           }),
           !data.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !data.license.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            character.strokes = data.strokes
            character.strokeAttribution = HanziAttribution(source: data.source, license: data.license)
        }
        SpeechTextIndex.shared.register(character)
        return character
    }

    private func hanziBookDir(_ bookId: String) -> URL? {
        guard bookId.range(of: #"^[a-z0-9]+(?:-[a-z0-9]+)*$"#, options: .regularExpression) != nil else { return nil }
        return sandboxDataRoot.appendingPathComponent("hanzi", isDirectory: true)
            .appendingPathComponent(bookId, isDirectory: true)
    }

    // MARK: - Helpers

    private func bookDir(_ bookId: String) -> URL {
        sandboxDataRoot
            .appendingPathComponent("books", isDirectory: true)
            .appendingPathComponent(bookId, isDirectory: true)
    }

    private func decode<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        let data = try Data(contentsOf: url)
        return try decoder.decode(T.self, from: data)
    }
}
