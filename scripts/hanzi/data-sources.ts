import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { createReadStream } from "node:fs";
import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { createInterface } from "node:readline";
import type { HanziStrokeData } from "../../packages/core/src/hanzi";

export const MMH_COMMIT = "bddc96d41bef78427ed0e034e9f7e31d71fd1b92";
export const UNIHAN_VERSION = "17.0.0";
export const UPSTREAM = {
  graphics: {
    url: `https://raw.githubusercontent.com/skishore/makemeahanzi/${MMH_COMMIT}/graphics.txt`,
    sha256: "a28c478b5178e98f67f510b2d52fde08a69dc664654ef43498253b9b764d46ee",
    file: "graphics.txt",
  },
  unihan: {
    url: `https://www.unicode.org/Public/${UNIHAN_VERSION}/ucd/Unihan.zip`,
    sha256: "f7a48b2b545acfaa77b2d607ae28747404ce02baefee16396c5d2d7a8ef34b5e",
    file: `Unihan-${UNIHAN_VERSION}.zip`,
  },
  radicals: {
    url: `https://www.unicode.org/Public/${UNIHAN_VERSION}/ucd/CJKRadicals.txt`,
    sha256: "826f83be25cd18fb8a5015a514704504e1982e840ea14d058bf583e1cc620c83",
    file: `CJKRadicals-${UNIHAN_VERSION}.txt`,
  },
} as const;

export function verifyChecksum(data: Uint8Array, expected: string): void {
  const actual = createHash("sha256").update(data).digest("hex");
  if (actual !== expected) throw new Error(`sha256 不一致：预期 ${expected}，实际 ${actual}`);
}

/** 已有缓存也必校验；失败时不使用缓存、不静默下载新版本。 */
async function cached(cache: string, spec: { url: string; sha256: string; file: string }): Promise<string> {
  await mkdir(cache, { recursive: true });
  const path = join(cache, spec.file);
  let data: Buffer;
  try { data = await readFile(path); }
  catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
    console.log(`下载固定版本：${spec.url}`);
    const response = await fetch(spec.url, { signal: AbortSignal.timeout(60_000) });
    if (!response.ok) throw new Error(`下载失败 ${response.status}：${spec.url}`);
    data = Buffer.from(await response.arrayBuffer());
    verifyChecksum(data, spec.sha256);
    await writeFile(`${path}.tmp`, data);
    await rename(`${path}.tmp`, path);
  }
  verifyChecksum(data, spec.sha256);
  return path;
}

export interface UnihanEntry { readings: string[]; radical: string; strokeCounts: number[] }
export type Unihan = Map<string, UnihanEntry>;
export const pinyinKey = (pinyin: string): string => pinyin.normalize("NFC").toLowerCase();

export function parseUnihan(readings: string, irg: string, radicals: string): Unihan {
  const radicalMap = new Map<string, string>();
  for (const line of radicals.split(/\r?\n/)) {
    const match = line.match(/^([\d']+);\s*[\dA-F]+;\s*([\dA-F]+)/);
    if (match) radicalMap.set(match[1], String.fromCodePoint(parseInt(match[2], 16)));
  }
  const entries: Unihan = new Map();
  for (const line of `${readings}\n${irg}`.split(/\r?\n/)) {
    const match = line.match(/^U\+([\dA-F]+)\t(kMandarin|kHanyuPinyin|kRSUnicode|kTotalStrokes)\t(.+)$/);
    if (!match) continue;
    const char = String.fromCodePoint(parseInt(match[1], 16));
    const entry = entries.get(char) ?? { readings: [], radical: "", strokeCounts: [] };
    const [, , field, value] = match;
    if (field === "kMandarin" || field === "kHanyuPinyin") {
      const values = field === "kMandarin" ? value.split(/\s+/)
        : value.split(/\s+/).flatMap(group => group.slice(group.indexOf(":") + 1).split(","));
      entry.readings = [...new Set([...entry.readings, ...values.map(pinyinKey)])].sort();
    } else if (field === "kRSUnicode") {
      const radicalNumber = value.split(/\s+/)[0].split(".")[0];
      entry.radical = radicalMap.get(radicalNumber) ?? "";
    } else entry.strokeCounts = value.split(/\s+/).map(Number);
    entries.set(char, entry);
  }
  return entries;
}

export async function loadUnihan(cache: string): Promise<Unihan> {
  const zip = await cached(cache, UPSTREAM.unihan);
  const radicals = await cached(cache, UPSTREAM.radicals);
  // 不引入 ZIP 依赖，不把解压后的上游文件写入内容目录。
  const text = execFileSync("python3", ["-c", [
    "import sys,zipfile,json",
    "with zipfile.ZipFile(sys.argv[1]) as z:",
    " print(json.dumps([z.read(n).decode('utf-8') for n in ['Unihan_Readings.txt','Unihan_IRGSources.txt']]))",
  ].join("\n"), zip], { encoding: "utf8", maxBuffer: 64 * 1024 * 1024 });
  const [readings, irg] = JSON.parse(text) as [string, string];
  return parseUnihan(readings, irg, await readFile(radicals, "utf8"));
}

/** 适配器只向构建器交付统一格式，可替换其他有明确授权的数据源。 */
export interface StrokeSourceAdapter {
  load(chars: ReadonlySet<string>): Promise<Map<string, HanziStrokeData>>;
}

interface MakeMeAHanziGraphic { character: string; strokes: string[]; medians: [number, number][][] }

/** 上游只用绝对 M/L/Q/C/Z。转换所有控制点，禁止丢失未知命令。 */
export function flipOutline(path: string): string {
  if (/[A-Za-z]/g.test(path.replace(/[MLQCZ]/g, ""))) throw new Error("不支持的 SVG 路径命令");
  const tokens = path.match(/[MLQCZ]|-?\d+(?:\.\d+)?/g) ?? [];
  let coordinate = 0;
  return tokens.map(token => {
    if (/^[MLQCZ]$/.test(token)) { coordinate = 0; return token; }
    return String(coordinate++ % 2 === 0 ? Number(token) : 900 - Number(token));
  }).join(" ");
}

export function convertGraphic(graphic: MakeMeAHanziGraphic): HanziStrokeData {
  if (!graphic.strokes.length || graphic.strokes.length !== graphic.medians.length) {
    throw new Error(`${graphic.character}：上游轮廓与中线数量不一致`);
  }
  return {
    char: graphic.character,
    strokes: graphic.strokes.map((outline, i) => ({
      outline: flipOutline(outline),
      median: graphic.medians[i].map(([x, y]) => [x, 900 - y]),
    })),
    source: `Make Me a Hanzi (graphics.txt) @ ${MMH_COMMIT}; ${UPSTREAM.graphics.url}`,
    license: "Arphic Public License",
  };
}

export class MakeMeAHanziAdapter implements StrokeSourceAdapter {
  constructor(private readonly cache: string) {}
  async load(chars: ReadonlySet<string>): Promise<Map<string, HanziStrokeData>> {
    const path = await cached(this.cache, UPSTREAM.graphics);
    const lines = createInterface({ input: createReadStream(path), crlfDelay: Infinity });
    const result = new Map<string, HanziStrokeData>();
    for await (const line of lines) {
      if (!line.trim()) continue;
      const graphic = JSON.parse(line) as MakeMeAHanziGraphic;
      if (chars.has(graphic.character)) result.set(graphic.character, convertGraphic(graphic));
    }
    return result;
  }
}
