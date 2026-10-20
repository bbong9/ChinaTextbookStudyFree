import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { audioPath, compile, validateCharacter, type HanziSource, type SourceChar } from "./build-hanzi";
import { convertGraphic, flipOutline, parseUnihan, verifyChecksum, type Unihan } from "./data-sources";
import type { HanziStrokeData } from "../../packages/core/src/hanzi";

// 夹具的几何数据是自写测试折线，不复制任何上游轮廓。
const fixture: SourceChar = {
  char: "山", status: "draft", pinyin: "shān", pinyinAlternates: [], strokeCount: 3,
  strokeNames: ["竖", "竖折", "竖"], structure: "独体字", source: "自写测试", license: "MIT",
  words: [{ text: "高山", pinyin: "gāo shān", status: "draft" }, { text: "山羊", pinyin: "shān yáng", status: "draft" }],
  scene: "mountains", sceneCaption: "测试场景", origin: { kind: "象形", explanation: "测试讲解", forms: [], source: "自写测试", license: "MIT", status: "draft" },
  distractors: { shape: ["出", "田"], sound: ["衫"] }, reviewNotes: [],
};
const strokes: HanziStrokeData = { char: "山", source: "自写测试", license: "MIT", strokes: Array.from({ length: 3 }, () => ({ outline: "M 10 10 L 10 40", median: [[10, 10], [10, 40]] })) };
const unihan: Unihan = new Map([
  ["山", { readings: ["shān"], radical: "山", strokeCounts: [3] }],
  ["出", { readings: ["chū"], radical: "凵", strokeCounts: [5] }],
  ["田", { readings: ["tián"], radical: "田", strokeCounts: [5] }],
  ["衫", { readings: ["shān"], radical: "衣", strokeCounts: [8] }],
]);

test("合法初稿合并单元归属，输出内容不嵌笔顺", async () => {
  const source: HanziSource = { version: 1, bookId: "chinese-g1up", status: "draft", source: "自写", license: "MIT", editionNote: "测试", units: [{ unitNumber: 2, title: "测试", status: "draft", recognitionChars: ["山"], writingChars: ["山"] }], chars: [fixture] };
  const result = await compile(source, unihan, { async load() { return new Map([["山", strokes]]); } });
  assert.deepEqual(result.index.units[0].chars, ["山"]);
  assert.equal(result.characters[0].radical, "山");
  assert.equal("strokes" in result.characters[0], false);
  assert.equal(result.characters[0].audio.char, audioPath("山"));
  assert.equal(result.characters[0].audio.pinyin, result.characters[0].audio.char);
});

const badCases: [string, (c: SourceChar, s: HanziStrokeData) => void, RegExp][] = [
  ["拼音拼错", c => { c.pinyin = "shǎān"; }, /不在 Unihan/],
  ["未手工选择提示读音", c => { delete (c as Partial<SourceChar>).pinyinAlternates; }, /必须手工选择/],
  ["主笔画数不一致", c => { c.strokeCount = 2; }, /笔画数不一致/],
  ["笔画名称数量不一致", c => { c.strokeNames.pop(); }, /笔画数不一致/],
  ["笔顺文件数量不一致", (_c, s) => { s.strokes.pop(); }, /笔画数不一致/],
  ["shape 组混入同音字", c => { c.distractors.shape = ["衫", "田"]; c.distractors.sound = []; }, /与目标同音/],
  ["sound 组混入同形字", c => { c.distractors.sound = ["山"]; }, /与目标同形/],
  ["sound 组并非同音", c => { c.distractors.sound = ["田"]; c.distractors.shape = ["出"]; }, /不同音/],
  ["组词漏目标字", c => { c.words[0].text = "河流"; }, /不包含目标字/],
  ["字卡来源缺失", c => { c.source = ""; }, /缺少 source/],
  ["字卡许可缺失", c => { c.license = " "; }, /缺少 license/],
  ["笔顺来源缺失", (_c, s) => { s.source = ""; }, /缺少 source/],
  ["笔顺许可缺失", (_c, s) => { s.license = ""; }, /缺少 license/],
  ["字源许可缺失", c => { c.origin!.license = ""; }, /缺少 license/],
  ["古文字图形", c => { (c.origin!.forms as unknown[]) = [{ script: "jiaguwen" }]; }, /D6/],
];
for (const [name, mutate, expected] of badCases) test(`故意错误：${name}`, () => {
  const c = structuredClone(fixture), s = structuredClone(strokes);
  mutate(c, s);
  assert.throws(() => validateCharacter(c, unihan, s), expected);
});

for (const field of ["source", "license"]) test(`CLI 缺 ${field} 非零退出且不写产物`, () => {
  const dir = mkdtempSync(join(tmpdir(), "rd12-invalid-"));
  try {
    const input = JSON.parse(readFileSync(new URL("./sources/chinese-g1up.json", import.meta.url), "utf8"));
    delete input.chars[0][field];
    const file = join(dir, "bad.json");
    writeFileSync(file, JSON.stringify(input));
    const output = new URL("../../content/hanzi/chinese-g1up/index.json", import.meta.url);
    const before = readFileSync(output);
    const run = spawnSync(process.execPath, ["--import", "tsx", "scripts/hanzi/build-hanzi.ts", "chinese-g1up", "--source", file], { cwd: new URL("../..", import.meta.url), encoding: "utf8" });
    assert.equal(run.status, 1, run.stderr);
    assert.match(run.stderr, new RegExp(`缺少 ${field}`));
    assert.deepEqual(readFileSync(output), before);
  } finally { rmSync(dir, { recursive: true, force: true }); }
});

test("上游坐标的端点、控制点和中线同时转换，未知命令不吞掉", () => {
  assert.equal(flipOutline("M 10 900 L 20 -124 Q 30 800 40 700 C 50 600 60 500 70 400 Z"), "M 10 0 L 20 1024 Q 30 100 40 200 C 50 300 60 400 70 500 Z");
  const converted = convertGraphic({ character: "山", strokes: ["M 0 900 L 20 800"], medians: [[[0, 900], [20, 800]]] });
  assert.deepEqual(converted.strokes[0].median, [[0, 0], [20, 100]]);
  assert.throws(() => flipOutline("M 0 0 A 2 3 0 0 0 4 5"), /不支持/);
});

test("解析 kMandarin 多音值及多组 kHanyuPinyin，不丢读音或部首", () => {
  const result = parseUnihan("U+5730\tkMandarin\tde dì\nU+5730\tkHanyuPinyin\t10420.120:dì,de 12345.010:di", "U+5730\tkRSUnicode\t32.3\nU+5730\tkTotalStrokes\t6", "32; 2F1F; 571F");
  assert.deepEqual(result.get("地"), { readings: ["de", "di", "dì"].sort(), radical: "土", strokeCounts: [6] });
});

test("缓存 SHA-256 不匹配必须拒绝", () => {
  const data = Buffer.from("test fixture");
  verifyChecksum(data, createHash("sha256").update(data).digest("hex"));
  assert.throws(() => verifyChecksum(data, "0".repeat(64)), /sha256 不一致/);
});

test("音频文本空白规范化后寻址，与现有 Python TTS 收集器一致", () => {
  assert.equal(audioPath(" 高山 \n"), audioPath("高山"));
  const run = spawnSync("python3", ["-c", "from scripts.tts.collect_texts import collect_hanzi; items=list(collect_hanzi()); assert len({i['char'] for i in items})==100; assert all(i['status']=='draft' and i['language']=='Chinese' for i in items); print(len(items))"], { cwd: new URL("../..", import.meta.url), encoding: "utf8" });
  assert.equal(run.status, 0, run.stderr);
  assert.ok(Number(run.stdout.trim()) >= 400);
});
