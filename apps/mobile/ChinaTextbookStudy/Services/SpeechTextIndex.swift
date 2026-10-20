import Foundation

/// 音频路径 → 原文 的索引，给 `AudioPlayer` 的系统 TTS 兜底用。
///
/// 题库里每条音频引用（`/audio/xx/<sha>.opus|mp3`）都对应一段原文：题干、选项、
/// 解析、知识卡、课文/故事句子。iOS 端的录音包不一定在本地（GitHub Release
/// 上没有 iOS 分包、国内网络也常拉不下来），而 v1.4.0 起大量新题本来就没有录音。
/// `DataLoader` 每解码一份课程/课文/故事就把这些对应关系登记进来，播放时找不到
/// 录音文件就用原文走 `AVSpeechSynthesizer`。
///
/// `DataLoader` 不在主线程隔离里，所以这里自己加锁，而不是挂到 `@MainActor`。
final class SpeechTextIndex: @unchecked Sendable {
    static let shared = SpeechTextIndex()

    private var map: [String: String] = [:]
    private let lock = NSLock()

    private init() {}

    func text(for path: String) -> String? {
        lock.lock(); defer { lock.unlock() }
        return map[Self.key(path)]
    }

    // MARK: - Registration

    func register(_ lesson: Lesson) {
        var pairs: [(String?, String)] = []
        for q in lesson.questions { collect(q.audio, question: q.question, options: q.options, explanation: q.explanation, into: &pairs) }
        if let k = lesson.knowledge, let a = k.audio {
            pairs.append((a.point, k.point))
            pairs.append((a.coreConcept, k.coreConcept))
            pairs.append((a.keyFormula, k.keyFormula))
            pairs.append((a.tips, k.tips))
            for (i, path) in (a.commonMistakes ?? []).enumerated() where i < k.commonMistakes.count {
                pairs.append((path, k.commonMistakes[i]))
            }
        }
        store(pairs)
    }

    func register(_ book: BookPassages) {
        store(book.passages.flatMap { $0.sentences.map { ($0.audio, $0.text) } })
    }

    func register(_ book: BookStories) {
        var pairs: [(String?, String)] = []
        for s in book.stories {
            pairs += s.sentences.map { ($0.audio, $0.text) }
            for q in s.questions { collect(q.audio, question: q.question, options: q.options, explanation: q.explanation, into: &pairs) }
        }
        store(pairs)
    }

    private func collect(_ audio: QuestionAudio?, question: String, options: [String], explanation: String,
                         into pairs: inout [(String?, String)]) {
        guard let audio else { return }
        pairs.append((audio.question, question))
        pairs.append((audio.explanation, explanation))
        for (i, path) in (audio.options ?? []).enumerated() where i < options.count {
            pairs.append((path, options[i]))
        }
    }

    private func store(_ pairs: [(String?, String)]) {
        lock.lock(); defer { lock.unlock() }
        for (path, text) in pairs {
            guard let path, !path.isEmpty, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            map[Self.key(path)] = text
        }
    }

    /// "/audio/8e/8ec5….opus" 与 "audio/8e/8ec5….m4a" 视为同一条。
    private static func key(_ path: String) -> String {
        var rel = path
        if rel.hasPrefix("/") { rel.removeFirst() }
        if let dot = rel.lastIndex(of: "."), !rel[dot...].contains("/") { rel = String(rel[..<dot]) }
        return rel
    }

    // MARK: - Spoken form

    /// 默认中文语音（中文语音念夹杂的英文单词也还行，反过来不行）；只有不含汉字
    /// 且确实有英文单词时才用英文语音 —— 纯算式 "$\frac{1}{5}$ + 3" 要按中文读。
    static func isChinese(_ text: String) -> Bool {
        if text.unicodeScalars.contains(where: { (0x4E00...0x9FFF).contains($0.value) }) { return true }
        let stripped = text.replacingOccurrences(of: #"\\[a-zA-Z]+"#, with: "", options: .regularExpression)
        return stripped.range(of: #"[A-Za-z]{2,}"#, options: .regularExpression) == nil
    }

    /// 把显示用文本整理成适合朗读的形式：去掉 LaTeX 定界、把运算符/分数/填空横线
    /// 读成中文。英文句子只处理填空横线。
    static func spokenForm(_ text: String) -> String {
        var s = text
        s = s.replacingOccurrences(of: #"_{2,}"#, with: isChinese(text) ? "（横线）" : " blank ", options: .regularExpression)
        guard isChinese(text) else { return s }

        s = s.replacingOccurrences(of: #"\\frac\{([^{}]*)\}\{([^{}]*)\}"#, with: "$2分之$1", options: .regularExpression)
        let commands: [(String, String)] = [
            (#"\times"#, "乘"), (#"\div"#, "除以"), (#"\cdot"#, "乘"),
            (#"\leq"#, "小于等于"), (#"\geq"#, "大于等于"), (#"\le"#, "小于等于"), (#"\ge"#, "大于等于"),
            (#"\neq"#, "不等于"), (#"\ne"#, "不等于"), (#"\approx"#, "约等于"), (#"\pi"#, "派"),
            (#"\bigcirc"#, "圆圈"), (#"\square"#, "方框"), (#"\triangle"#, "三角形"), (#"\angle"#, "角"),
        ]
        for (cmd, word) in commands { s = s.replacingOccurrences(of: cmd, with: word) }
        s = s.replacingOccurrences(of: #"\\[a-zA-Z]+"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: #"[${}]"#, with: "", options: .regularExpression)
        // 纯数字分数 3/10 → 十分之三（读数字即可，TTS 会念「10分之3」）。
        s = s.replacingOccurrences(of: #"(\d+)\s*/\s*(\d+)"#, with: "$2分之$1", options: .regularExpression)
        let symbols: [(String, String)] = [
            ("×", "乘"), ("÷", "除以"), ("＋", "加"), ("+", "加"), ("＝", "等于"), ("=", "等于"),
            ("≤", "小于等于"), ("≥", "大于等于"), ("≠", "不等于"), ("≈", "约等于"),
            ("<", "小于"), (">", "大于"), ("□", "方框"), ("○", "圆圈"), ("◯", "圆圈"),
        ]
        for (sym, word) in symbols { s = s.replacingOccurrences(of: sym, with: word) }
        // 数字之间的减号读「减」，其余横杠（破折号等）不动。
        s = s.replacingOccurrences(of: #"(\d)\s*[-−－]\s*(\d)"#, with: "$1减$2", options: .regularExpression)
        // （ ）/ ( ) 空括号是填空位。
        s = s.replacingOccurrences(of: #"[（(][\s　]*[)）]"#, with: "（括号）", options: .regularExpression)
        return s
    }
}
