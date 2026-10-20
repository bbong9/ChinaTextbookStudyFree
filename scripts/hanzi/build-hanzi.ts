import { createHash } from "node:crypto";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type { HanziAttribution, HanziCharacter, HanziIndex, HanziOrigin, HanziScene, HanziStrokeData, HanziUnit } from "../../packages/core/src/hanzi";
import { loadUnihan, MakeMeAHanziAdapter, pinyinKey, UNIHAN_VERSION, UPSTREAM, type StrokeSourceAdapter, type Unihan } from "./data-sources";

export interface SourceChar extends HanziAttribution {
  char: string;
  status: "draft";
  pinyin: string;
  pinyinAlternates: string[];
  strokeCount: number;
  strokeNames: string[];
  structure: string;
  words: { text: string; pinyin: string; status: "draft" }[];
  scene: HanziScene | null;
  sceneCaption: string | null;
  origin: (HanziOrigin & { status: "draft" }) | null;
  distractors: { shape: string[]; sound: string[] };
  reviewNotes: string[];
}

export interface HanziSource extends HanziAttribution {
  version: 1;
  bookId: string;
  status: "draft";
  editionNote: string;
  units: Omit<HanziUnit, "chars">[];
  chars: SourceChar[];
}

function requireThat(value: unknown, message: string): asserts value {
  if (!value) throw new Error(message);
}

export function requireAttribution(value: HanziAttribution, label: string): void {
  requireThat(typeof value?.source === "string" && value.source.trim(), `${label}：缺少 source`);
  requireThat(typeof value?.license === "string" && value.license.trim(), `${label}：缺少 license`);
}

export function codepoint(char: string): string {
  requireThat([...char].length === 1 && /^\p{Script=Han}$/u.test(char), `不是单个汉字：${char}`);
  return char.codePointAt(0)!.toString(16);
}

/** 和 scripts/tts/collect_texts.py 一样，先压缩空白再按原文 SHA-1 寻址。 */
export function audioPath(text: string): string {
  const normalized = text.trim().replace(/\s+/g, " ");
  const hash = createHash("sha1").update(normalized).digest("hex");
  return `/audio/${hash.slice(0, 2)}/${hash}.opus`;
}

export function validateCharacter(char: SourceChar, unihan: Unihan, strokes: HanziStrokeData): void {
  const label = char.char;
  codepoint(label);
  requireAttribution(char, label);
  requireAttribution(strokes, `${label} 笔顺`);
  requireThat(char.status === "draft", `${label}：本卡内容必须标 draft`);
  const entry = unihan.get(label);
  requireThat(entry?.readings.length && entry.radical, `${label}：Unihan 缺拼音或部首`);
  const readings = new Set(entry.readings.map(pinyinKey));
  requireThat(readings.has(pinyinKey(char.pinyin)), `${label}：拼音 ${char.pinyin} 不在 Unihan 读音集合内`);
  requireThat(Array.isArray(char.pinyinAlternates), `${label}：必须手工选择 pinyinAlternates（无其他读音时填空数组）`);
  const alternates = char.pinyinAlternates;
  requireThat(new Set(alternates.map(pinyinKey)).size === alternates.length, `${label}：备选读音重复`);
  for (const alternate of alternates) {
    requireThat(readings.has(pinyinKey(alternate)) && pinyinKey(alternate) !== pinyinKey(char.pinyin), `${label}：备选读音无效 ${alternate}`);
  }
  requireThat(strokes.char === label, `${label}：笔顺文件字不匹配`);
  requireThat(Number.isInteger(char.strokeCount) && char.strokeCount > 0
    && char.strokeCount === char.strokeNames.length && char.strokeCount === strokes.strokes.length,
  `${label}：strokeCount、strokeNames 与笔顺文件的笔画数不一致`);
  requireThat(char.strokeNames.every(name => typeof name === "string" && name.trim()), `${label}：笔画名称缺失`);
  requireThat(entry.strokeCounts.includes(char.strokeCount), `${label}：笔画数不在 Unihan kTotalStrokes 内`);
  for (const stroke of strokes.strokes) {
    requireThat(stroke.outline.trim() && stroke.median.length >= 2 && stroke.median.every(point =>
      point.length === 2 && point.every(n => Number.isFinite(n) && n >= 0 && n <= 1024)), `${label}：笔顺几何数据无效`);
  }
  requireThat(char.words.length >= 2 && char.words.length <= 4, `${label}：组词必须为 2–4 个`);
  for (const word of char.words) {
    requireThat(word.text.includes(label), `${label}：组词 ${word.text} 不包含目标字`);
    requireThat(word.pinyin.trim() && word.status === "draft", `${label}：组词读音缺失或未标 draft`);
  }
  requireThat(char.structure.trim(), `${label}：缺少结构`);
  requireThat(char.scene === null || ["sun", "moon", "water", "fire", "mountains", "rock", "field", "grain"].includes(char.scene), `${label}：未知场景 id`);
  requireThat(char.scene === null || (char.sceneCaption && char.origin?.kind === "象形"), `${label}：只有象形字可指定场景且必须有说明`);
  if (char.origin) {
    requireAttribution(char.origin, `${label} 字源`);
    requireThat(char.origin.forms.length === 0, `${label}：D6 不允许古文字字形`);
    requireThat(char.origin.status === "draft" && char.origin.explanation.trim() && char.origin.kind.trim(), `${label}：字源缺失或未标 draft`);
  }
  const { shape, sound } = char.distractors;
  const distractors = [...shape, ...sound];
  requireThat(distractors.length >= 2 && new Set(distractors).size === distractors.length, `${label}：至少需要两个不重复的干扰字`);
  for (const other of distractors) {
    codepoint(other);
    requireThat(other.normalize("NFKC") !== label.normalize("NFKC"), `${label}：干扰字与目标同形`);
    requireThat(unihan.get(other)?.readings.length, `${label}：干扰字 ${other} 无 Unihan 读音`);
  }
  for (const other of shape) {
    requireThat(!unihan.get(other)!.readings.map(pinyinKey).includes(pinyinKey(char.pinyin)), `${label}：shape 干扰字 ${other} 与目标同音`);
  }
  for (const other of sound) {
    requireThat(unihan.get(other)!.readings.map(pinyinKey).includes(pinyinKey(char.pinyin)), `${label}：sound 干扰字 ${other} 与目标不同音`);
  }
}

export async function compile(source: HanziSource, unihan: Unihan, adapter: StrokeSourceAdapter) {
  requireAttribution(source, "字表");
  requireThat(source.version === 1 && source.status === "draft", "字表 version/status 无效");
  requireThat(/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(source.bookId), "bookId 无效");
  const chars = new Map(source.chars.map(char => [char.char, char]));
  requireThat(chars.size === source.chars.length && chars.size > 0, "字表为空或有重复字");
  const units = source.units.map(unit => {
    requireThat(unit.status === "draft" && Number.isInteger(unit.unitNumber) && unit.unitNumber > 0 && unit.title.trim(), "单元信息无效或未标 draft");
    const members = [...new Set([...unit.recognitionChars, ...unit.writingChars])];
    requireThat(members.length > 0, "单元字表不能为空");
    members.forEach(char => requireThat(chars.has(char), `${unit.title}：缺少字文件 ${char}`));
    return { ...unit, chars: members };
  });
  requireThat(new Set(units.map(unit => unit.unitNumber)).size === units.length, "单元编号重复");
  const used = new Set(units.flatMap(unit => unit.chars));
  requireThat(used.size === chars.size && [...chars.keys()].every(char => used.has(char)), "字表包含未归属单元的字");
  const strokes = await adapter.load(used);
  const characters: HanziCharacter[] = source.chars.map(char => {
    const strokeData = strokes.get(char.char);
    requireThat(strokeData, `${char.char}：缺少笔顺数据`);
    validateCharacter(char, unihan, strokeData);
    const entry = unihan.get(char.char)!;
    return {
      ...char,
      radical: entry.radical,
      words: char.words.map(word => ({ ...word, audio: audioPath(word.text) })),
      // 两个按钮都朗读汉字，复用单字音频；避免把拼音 me 与英文 me 的全局文本哈希混用。
      audio: { char: audioPath(char.char), pinyin: audioPath(char.char), origin: char.origin ? audioPath(char.origin.explanation) : null },
      unihan: { source: UPSTREAM.unihan.url, license: "Unicode-3.0", version: UNIHAN_VERSION, readings: entry.readings, radical: entry.radical },
    };
  });
  const index: HanziIndex = { version: 1, bookId: source.bookId, status: source.status, source: source.source, license: source.license, units };
  return { index, characters, strokes };
}

export function report(source: HanziSource, result: Awaited<ReturnType<typeof compile>>): string {
  const lines = [
    `# ${source.bookId} 汉字内容初稿报告`, "",
    "- 全部字表、组词和字源讲解均为 `draft`，未经纸质课本和教参人工复核。",
    `- 教材版本说明：${source.editionNote}`,
    `- 两个识字单元共 ${result.characters.length} 个去重字；保留 recognitionChars / writingChars 归属，不将预计字数当成删字依据。`,
    `- 笔顺：${UPSTREAM.graphics.url}；SHA-256：\`${UPSTREAM.graphics.sha256}\`。`,
    `- Unihan：${UPSTREAM.unihan.url}；SHA-256：\`${UPSTREAM.unihan.sha256}\`。`,
    `- 部首映射：${UPSTREAM.radicals.url}；SHA-256：\`${UPSTREAM.radicals.sha256}\`。`,
    "- 手写初稿 MIT；Unihan 衍生字段 Unicode-3.0；笔顺图形单独按 Arphic Public License 分发。",
    "- 无音频文件：所有路径按文本 SHA-1 生成，由 SpeechTextIndex 注册原文；录音制作使用现有 scripts/tts 管线。",
    "- 提示读音由输入手工选择；Unihan 的全集可能含古音、异读，不直接全量展示给孩子。",
    "", "## 单元字表（全部 draft）", "",
  ];
  for (const unit of result.index.units) lines.push(`### ${unit.unitNumber} ${unit.title}`, "", `- 识字表：${unit.recognitionChars.join("、")}`, `- 写字表：${unit.writingChars.join("、")}`, "- [ ] 对照实际版次的纸质课本核对字表及单元编号。", "");
  lines.push("## 逐字来源、缺失项与复核清单", "", "每行均须人工复核：课本字表归属、本课读音、组词及拼音、部首与结构、干扰字适龄性、笔画名称与规范顺序、字源说法。", "", "| 字 | 状态 | 数据来源 | 缺失项 | 人工复核点 |", "| --- | --- | --- | --- | --- |");
  for (const char of result.characters) {
    const missing = ["录音", ...(char.origin ? [] : ["字源讲解（可空）"]), ...(char.scene ? [] : ["象形场景（用组词卡）"])];
    const review = [...char.reviewNotes];
    if (char.pinyinAlternates.length) review.push(`多音/异读：本课 ${char.pinyin}；备选 ${char.pinyinAlternates.join("、")}，核对现代常用读音`);
    const unselected = char.unihan.readings.filter(p => p !== char.pinyin && !char.pinyinAlternates.includes(p));
    if (unselected.length) review.push(`Unihan 另有 ${unselected.join("、")}（可能含古音、异读），核对是否需要提示`);
    review.push("课本与教参逐项待复核");
    lines.push(`| ${char.char} | ${char.status} | 手写初稿 MIT；Unihan ${UNIHAN_VERSION}（拼音、部首）；MMH ${char.strokeCount} 画（APL） | ${missing.join("；")} | [ ] ${review.join("；")} |`);
  }
  lines.push("", "## 笔顺规范复核", "", "- 对照依据：《通用规范汉字笔顺规范》（GF 0023—2020）。", "- 机器检查只证明笔画数、标注数量与源数据一致，不能代替规范逐字审阅。", "- 当前未完成纸质规范逐字人工核验；已确认不一致的字：尚无已确认条目，不代表不存在差异。", "- [ ] 所有试点字逐字对照规范；重点核对折笔名称、转折是否连笔、点/撇先后和包围结构封口顺序。", "", "## 发布前人工复核", "", "- [ ] 确认教材版次，并逐单元核对识字表、写字表和漏字/多字。", "- [ ] 逐词核对组词、词义、轻声和变调，尤其“一、不”和多音字。", "- [ ] 核对八个象形场景及字源讲解，避免把记忆口诀当作确证的字源。", "- [ ] 对照规范记录笔顺差异；有差异时修订适配或标注后再放行。", "- [ ] 完成人工复核后才能按审阅记录升级为 verified（本卡构建器只接受 draft）。", "");
  return lines.join("\n");
}

async function main(): Promise<void> {
  const [bookId, ...flags] = process.argv.slice(2);
  requireThat(bookId && /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(bookId), "用法：npx tsx scripts/hanzi/build-hanzi.ts chinese-g1up [--source <file>]");
  requireThat(flags.length === 0 || (flags.length === 2 && flags[0] === "--source"), "未知参数");
  const here = dirname(fileURLToPath(import.meta.url));
  const root = resolve(here, "../..");
  const source = JSON.parse(await readFile(flags[1] ? resolve(flags[1]) : join(here, "sources", `${bookId}.json`), "utf8")) as HanziSource;
  requireThat(source.bookId === bookId, "输入 bookId 不匹配");
  // 在联网及写文件之前拒绝缺失授权；包括每字和字源的授权。
  requireAttribution(source, "字表");
  for (const char of source.chars) { requireAttribution(char, char.char); if (char.origin) requireAttribution(char.origin, `${char.char} 字源`); }
  const cache = join(here, ".cache");
  const result = await compile(source, await loadUnihan(cache), new MakeMeAHanziAdapter(cache));
  const content = join(root, "content", "hanzi");
  for (const license of ["UNICODE-LICENSE", "strokes/LICENSE", "strokes/README.md"]) requireThat((await readFile(join(content, license), "utf8")).trim(), `缺少许可说明 ${license}`);
  const output = join(content, bookId);
  await mkdir(join(output, "chars"), { recursive: true });
  const json = (value: unknown) => `${JSON.stringify(value, null, 2)}\n`;
  await writeFile(join(output, "index.json"), json(result.index));
  for (const char of result.characters) {
    await writeFile(join(output, "chars", `${codepoint(char.char)}.json`), json(char));
    await writeFile(join(content, "strokes", `${codepoint(char.char)}.json`), json(result.strokes.get(char.char)));
  }
  await writeFile(join(here, `report-${bookId}.md`), report(source, result));
  console.log(`${bookId}：生成 ${result.characters.length} 个 draft 字文件及共享笔顺；全部校验通过。`);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch(error => { console.error(`汉字构建失败：${(error as Error).message}`); process.exitCode = 1; });
}
