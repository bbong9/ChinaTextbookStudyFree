import { readFileSync, readdirSync } from "node:fs";
import { describe, expect, it } from "vitest";
import type { HanziCharacter, HanziIndex, HanziStrokeData } from "../hanzi";

const root = new URL("../../../../content/hanzi/", import.meta.url);
const read = <T>(path: string): T => JSON.parse(readFileSync(new URL(path, root), "utf8"));

describe("RD-12 提交的完整汉字初稿", () => {
  it("两个单元的识字/写字并集恰好覆盖全部 100 个字文件", () => {
    const index = read<HanziIndex>("chinese-g1up/index.json");
    expect(index.status).toBe("draft");
    expect(index.units.map(unit => unit.unitNumber)).toEqual([2, 6]);
    for (const unit of index.units) expect(unit.chars).toEqual([...new Set([...unit.recognitionChars, ...unit.writingChars])]);
    const chars = [...new Set(index.units.flatMap(unit => unit.chars))];
    expect(chars).toHaveLength(100);
    const names = readdirSync(new URL("chinese-g1up/chars/", root)).sort();
    expect(names).toEqual(chars.map(char => `${char.codePointAt(0)!.toString(16)}.json`).sort());
  });

  it("每字有五步所需数据、明确初稿状态和独立授权的共享笔顺", () => {
    const index = read<HanziIndex>("chinese-g1up/index.json");
    let scenes = 0;
    for (const char of new Set(index.units.flatMap(unit => unit.chars))) {
      const hex = char.codePointAt(0)!.toString(16);
      const data = read<HanziCharacter>(`chinese-g1up/chars/${hex}.json`);
      const stroke = read<HanziStrokeData>(`strokes/${hex}.json`);
      expect(data.char).toBe(char);
      expect(data.status).toBe("draft");
      expect(data.license).toBe("MIT");
      expect(data.unihan.readings).toContain(data.pinyin);
      expect(data.pinyinAlternates).not.toContain(data.pinyin);
      expect(data.strokeNames).toHaveLength(data.strokeCount);
      expect(stroke.strokes).toHaveLength(data.strokeCount);
      expect(stroke.license).toBe("Arphic Public License");
      expect(stroke.source).toContain("bddc96d41bef78427ed0e034e9f7e31d71fd1b92");
      expect(data).not.toHaveProperty("strokes");
      for (const word of data.words) { expect(word.status).toBe("draft"); expect(word.text).toContain(char); }
      if (data.origin) { expect(data.origin.status).toBe("draft"); expect(data.origin.forms).toEqual([]); }
      if (data.scene) { scenes += 1; expect(data.sceneCaption).toBeTruthy(); }
      for (const path of [data.audio.char, data.audio.pinyin, ...data.words.map(word => word.audio)]) expect(path).toMatch(/^\/audio\/([a-f0-9]{2})\/\1[a-f0-9]{38}\.opus$/);
    }
    expect(scenes).toBe(8);
  });
});
