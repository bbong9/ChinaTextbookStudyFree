import Foundation

/// 与 packages/core/src/hanzi.ts 镜像；不改变 UserProgress 或备份格式。
enum HanziReviewStatus: String, Codable {
    case draft, verified
}

struct HanziAttribution: Codable {
    let source: String
    let license: String
}

struct HanziIndex: Codable {
    let version: Int
    let bookId: String
    let status: HanziReviewStatus
    let source: String
    let license: String
    let units: [HanziUnit]
}

struct HanziUnit: Codable {
    let unitNumber: Int
    let title: String
    let status: HanziReviewStatus
    let chars: [String]
    let recognitionChars: [String]
    let writingChars: [String]
}

enum HanziScene: String, Codable {
    case sun, moon, water, fire, mountains, rock, field, grain
}

struct HanziWord: Codable {
    let text: String
    let pinyin: String
    let audio: String
    let status: HanziReviewStatus
}

struct HanziOrigin: Codable {
    let kind: String
    let explanation: String
    /// D6：v1 仅接受空数组，不引入古文字图形。
    let forms: [String]
    let source: String
    let license: String
    let status: HanziReviewStatus
}

struct HanziDistractors: Codable {
    let shape: [String]
    let sound: [String]
}

struct HanziAudio: Codable {
    let char: String
    let pinyin: String
    let origin: String?
}

struct HanziUnihan: Codable {
    let source: String
    let license: String
    let version: String
    let readings: [String]
    let radical: String
}

struct HanziStroke: Codable {
    let outline: String
    /// 每个点是 [x, y]，1024×1024，Y 向下。
    let median: [[Double]]
}

struct HanziStrokeData: Codable {
    let char: String
    let strokes: [HanziStroke]
    let source: String
    let license: String
}

struct HanziCharacter: Codable {
    let char: String
    let status: HanziReviewStatus
    let pinyin: String
    let pinyinAlternates: [String]
    let strokeCount: Int
    let strokeNames: [String]
    let radical: String
    let structure: String
    let words: [HanziWord]
    let scene: HanziScene?
    let sceneCaption: String?
    let origin: HanziOrigin?
    let distractors: HanziDistractors
    let audio: HanziAudio
    let source: String
    let license: String
    let unihan: HanziUnihan
    let reviewNotes: [String]

    /// 只在加载时合并；不写回字卡 JSON，APL 图形保持独立。
    var strokes: [HanziStroke] = []
    var strokeAttribution: HanziAttribution? = nil

    enum CodingKeys: String, CodingKey {
        case char, status, pinyin, pinyinAlternates, strokeCount, strokeNames
        case radical, structure, words, scene, sceneCaption, origin, distractors
        case audio, source, license, unihan, reviewNotes
    }
}
