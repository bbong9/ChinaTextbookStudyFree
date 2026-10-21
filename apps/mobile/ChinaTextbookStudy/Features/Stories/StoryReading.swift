import Foundation

/// 拼音是旁挂内容，不进入用户存档；缺句、错位时整句隐藏 ruby。
typealias StoryPinyin = [String: [[String]]]

enum StoryReading {
    static func isEnglish(_ language: String) -> Bool {
        ["en", "english"].contains(language.lowercased())
    }

    static func pinyin(_ rows: [[String]]?, for story: Story) -> [[String]]? {
        guard !isEnglish(story.language), let rows, rows.count == story.sentences.count,
              zip(rows, story.sentences).allSatisfy({ $0.count == $1.text.count }) else { return nil }
        return rows
    }

    /// 录音时长均分给可朗读字符；标点和空格不占时间。
    static func highlight(text: String, elapsed: Double, duration: Double) -> Int? {
        let characters = Array(text)
        let indices = characters.indices.filter { index in
            characters[index].unicodeScalars.contains { CharacterSet.alphanumerics.contains($0) }
        }
        guard !indices.isEmpty, duration.isFinite, duration > 0, elapsed.isFinite, elapsed >= 0 else { return nil }
        let slot = min(indices.count - 1, Int(min(1, elapsed / duration) * Double(indices.count)))
        return indices[slot]
    }

    /// AVSpeech 的范围以 UTF-16 计；转换到 Swift 字符索引，兼容英文和 emoji。
    static func characterIndex(text: String, speechRange: NSRange?) -> Int? {
        guard let speechRange, let range = Range(speechRange, in: text) else { return nil }
        return text.distance(from: text.startIndex, to: range.lowerBound)
    }
}

struct StoryPageFlow: Equatable {
    enum Ending { case quiz, completion, goodnight }
    let count: Int
    let bedtime: Bool
    let hasQuestions: Bool
    private(set) var page = 0

    mutating func next() -> Ending? {
        if page + 1 < count { page += 1; return nil }
        return bedtime ? .goodnight : hasQuestions ? .quiz : .completion
    }

    mutating func previous() { page = max(0, page - 1) }
}

#if DEBUG
/// 仅由证据用 UI 测试启用；模拟器无采音能力，记录时间以便把相同原录音对齐到录屏。
@MainActor
enum StoryNarrationTrace {
    private static var enabled: Bool {
        let args = ProcessInfo.processInfo.arguments
        return args.contains("-uitest") && args.contains("-uitest-story-evidence")
    }
    private static var file: URL { FileManager.default.temporaryDirectory.appendingPathComponent("rd19-narration.jsonl") }
    static func reset() { if enabled { try? Data().write(to: file) } }
    static func record(story: Story, page: Int, audio: AudioPlayer) {
        guard enabled, let path = story.sentences[page].audio, let duration = audio.recordingDuration else { return }
        let rate = Double(audio.recordingRate)
        let row: [String: Any] = ["time": Date().timeIntervalSince1970 - audio.recordingElapsed / rate,
            "story": story.id, "page": page, "audio": path, "duration": duration, "rate": rate]
        guard let data = try? JSONSerialization.data(withJSONObject: row, options: [.sortedKeys]),
              let handle = try? FileHandle(forWritingTo: file) else { return }
        defer { try? handle.close() }
        try? handle.seekToEnd(); try? handle.write(contentsOf: data + Data([10]))
    }
}
#endif
