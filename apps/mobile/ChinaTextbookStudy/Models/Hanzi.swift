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

struct HanziOriginForm: Codable {
    enum Script: String, Codable {
        case jiaguwen, jinwen, xiaozhuan
    }

    let script: Script
    let svgPath: String
    let source: String
    let license: String
}

struct HanziOrigin: Codable {
    let kind: String
    let explanation: String
    /// 预留字形格式；D6：v1 不分发古文字字形，数据保持空数组。
    let forms: [HanziOriginForm]
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        char = try container.decode(String.self, forKey: .char)
        status = try container.decode(HanziReviewStatus.self, forKey: .status)
        pinyin = try container.decode(String.self, forKey: .pinyin)
        pinyinAlternates = try container.decode([String].self, forKey: .pinyinAlternates)
        strokeCount = try container.decode(Int.self, forKey: .strokeCount)
        strokeNames = try container.decode([String].self, forKey: .strokeNames)
        radical = try container.decode(String.self, forKey: .radical)
        structure = try container.decode(String.self, forKey: .structure)
        words = try container.decode([HanziWord].self, forKey: .words)
        // 新场景只降级为无场景，仍保留字卡及后续合并的笔顺。
        let sceneID = try container.decodeIfPresent(String.self, forKey: .scene)
        scene = sceneID.flatMap(HanziScene.init(rawValue:))
        sceneCaption = try container.decodeIfPresent(String.self, forKey: .sceneCaption)
        origin = try container.decodeIfPresent(HanziOrigin.self, forKey: .origin)
        distractors = try container.decode(HanziDistractors.self, forKey: .distractors)
        audio = try container.decode(HanziAudio.self, forKey: .audio)
        source = try container.decode(String.self, forKey: .source)
        license = try container.decode(String.self, forKey: .license)
        unihan = try container.decode(HanziUnihan.self, forKey: .unihan)
        reviewNotes = try container.decode([String].self, forKey: .reviewNotes)
    }
}
