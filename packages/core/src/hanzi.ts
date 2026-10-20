/** RD-12：手写教材初稿与 APL 笔顺分别分发，加载时才合并。 */
export type HanziReviewStatus = "draft" | "verified";

export interface HanziAttribution {
  source: string;
  license: string;
}

export interface HanziUnit {
  unitNumber: number;
  title: string;
  status: HanziReviewStatus;
  chars: string[];
  /** 保留识字表、写字表归属，chars 是两者按出现顺序去重后的并集。 */
  recognitionChars: string[];
  writingChars: string[];
}

export interface HanziIndex extends HanziAttribution {
  version: 1;
  bookId: string;
  status: HanziReviewStatus;
  units: HanziUnit[];
}

export type HanziScene = "sun" | "moon" | "water" | "fire" | "mountains" | "rock" | "field" | "grain";

export interface HanziWord {
  text: string;
  pinyin: string;
  audio: string;
  status: HanziReviewStatus;
}

export interface HanziOriginForm extends HanziAttribution {
  script: "jiaguwen" | "jinwen" | "xiaozhuan";
  svgPath: string;
}

export interface HanziOrigin extends HanziAttribution {
  kind: string;
  explanation: string;
  /** 预留字形格式；D6：v1 不分发古文字字形，数据保持空数组。 */
  forms: HanziOriginForm[];
  status: HanziReviewStatus;
}

export interface HanziCharacter extends HanziAttribution {
  char: string;
  status: HanziReviewStatus;
  pinyin: string;
  pinyinAlternates: string[];
  strokeCount: number;
  strokeNames: string[];
  radical: string;
  structure: string;
  words: HanziWord[];
  scene: HanziScene | null;
  sceneCaption: string | null;
  origin: HanziOrigin | null;
  distractors: { shape: string[]; sound: string[] };
  audio: { char: string; pinyin: string; origin: string | null };
  unihan: HanziAttribution & { version: string; readings: string[]; radical: string };
  reviewNotes: string[];
}

export interface HanziStroke {
  outline: string;
  /** 1024 × 1024，原点在左上角，Y 轴向下。 */
  median: [number, number][];
}

export interface HanziStrokeData extends HanziAttribution {
  char: string;
  strokes: HanziStroke[];
}

export interface HanziLoadedCharacter extends HanziCharacter {
  strokes: HanziStroke[];
  strokeAttribution: HanziAttribution | null;
}
