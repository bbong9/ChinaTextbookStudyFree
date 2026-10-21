#!/usr/bin/env node
// 离线构建：只读已下载数据或现有 seed，不改 stories.json。
import { pinyin } from 'pinyin-pro';
import { readFileSync, writeFileSync, mkdirSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve, join } from 'node:path';
import { execFileSync } from 'node:child_process';
import { createRequire } from 'node:module';
import assert from 'node:assert/strict';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const args = process.argv.slice(2);
const check = args.includes('--check');
const dataIndex = args.indexOf('--data-dir');
const documents = dataIndex >= 0
  ? readdirSync(resolve(args[dataIndex + 1], 'books')).sort().flatMap(book => {
    try { return [JSON.parse(readFileSync(resolve(args[dataIndex + 1], 'books', book, 'stories.json'), 'utf8'))]; }
    catch (error) { if (error.code === 'ENOENT') return []; throw error; }
  })
  : JSON.parse(execFileSync('python3', ['-c', `import json,zipfile,sys
with zipfile.ZipFile(sys.argv[1]) as z:
 print(json.dumps([json.loads(z.read(n)) for n in sorted(z.namelist()) if n.endswith('/stories.json')]))`,
    join(root, 'apps/mobile/ChinaTextbookStudy/Resources/seed-data.zip')], { maxBuffer: 32 * 1024 * 1024 }));
const out = join(root, 'content/story-pinyin');
const overrides = JSON.parse(readFileSync(join(root, 'scripts/story-pinyin-overrides.json'), 'utf8'));
mkdirSync(out, { recursive: true });
const require = createRequire(import.meta.url);
const packageRoot = dirname(require.resolve('pinyin-pro/package.json'));
const license = readFileSync(join(packageRoot, 'LICENSE'), 'utf8');
if (check) assert.equal(readFileSync(join(out, 'LICENSE.pinyin-pro'), 'utf8'), license);
else writeFileSync(join(out, 'LICENSE.pinyin-pro'), license);
const report = ['# 故事拼音复核清单', '',
  '由 `node scripts/build-story-pinyin.mjs` 从现有 seed 原文生成。pinyin-pro（MIT）仅作开发依赖。',
  '保留句子语境判读；一、不标语流变调，连续三声仍标本调；标点留空。以下自动标注待人工复核，未声称已逐句核对课本。', '',
  '人工校正规则见 `scripts/story-pinyin-overrides.json`，按语境处理首篇的背负、轻声和月亮，规则先于报告输出。', '',
  '| 书 / 故事 / 句 | 原文 | 多音字（位置从 1 起） | 轻声 | 一、不 |',
  '| --- | --- | --- | --- | --- |'];
let books = 0, stories = 0, sentences = 0, characters = 0;
for (const document of documents) {
  const output = {};
  for (const story of document.stories) {
    if (/^(en|english)$/i.test(story.language)) continue;
    output[story.id] = story.sentences.map((sentence, sentenceIndex) => {
      const chars = Array.from(sentence.text);
      const result = pinyin(sentence.text, { type: 'all', toneSandhi: true, nonZh: 'spaced' });
      assert.equal(result.length, chars.length, `${story.id} 句 ${sentenceIndex + 1} 字数不匹配`);
      const row = result.map((item, index) => {
        assert.equal(item.origin, chars[index], `${story.id} 原文位置不匹配`);
        return item.isZh ? item.pinyin : '';
      });
      for (const override of overrides) {
        if (override.storyId && override.storyId !== story.id) continue;
        assert.equal(Array.from(override.text).length, override.pinyin.length);
        let from = 0, offset;
        while ((offset = sentence.text.indexOf(override.text, from)) >= 0) {
          const charOffset = Array.from(sentence.text.slice(0, offset)).length;
          row.splice(charOffset, override.pinyin.length, ...override.pinyin);
          from = offset + override.text.length;
        }
      }
      assert.equal(row.length, chars.length);
      const poly = [], neutral = [], sandhi = [];
      result.forEach((item, i) => {
        if (!item.isZh) return;
        if (item.polyphonic.length > 1) poly.push(`${i + 1}:${item.origin}=${row[i]}（${item.polyphonic.join('/')}）`);
        if (!/[āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ]/.test(row[i])) neutral.push(`${item.origin}=${row[i]}`);
        if (/[一不]/.test(item.origin)) sandhi.push(`${item.origin}=${row[i]}`);
      });
      if (poly.length || neutral.length || sandhi.length) report.push(`| ${document.bookId} / ${story.id} / ${sentenceIndex + 1} | ${sentence.text.replaceAll('|', '／')} | ${poly.join('；') || '—'} | ${neutral.join('；') || '—'} | ${sandhi.join('；') || '—'} |`);
      sentences++; characters += row.length;
      return row;
    });
    stories++;
  }
  if (!Object.keys(output).length) continue;
  const file = join(out, `${document.bookId}.json`);
  // 一句占一行，便于把原句与 ruby 对照审阅，避免逐字数组撑出十万行 diff。
  const text = '{\n' + Object.entries(output).map(([id, rows]) =>
    `  ${JSON.stringify(id)}: [\n${rows.map(row => '    ' + JSON.stringify(row)).join(',\n')}\n  ]`
  ).join(',\n') + '\n}\n';
  if (check) assert.equal(readFileSync(file, 'utf8'), text, `${file} 需要重新生成`);
  else writeFileSync(file, text);
  books++;
}
report.splice(5, 0, `共 ${books} 册 / ${stories} 篇 / ${sentences} 句 / ${characters} 个字符，全部逐句校验长度。`, '');
const reportText = report.join('\n') + '\n';
if (check) assert.equal(readFileSync(join(out, 'REVIEW.md'), 'utf8'), reportText);
else writeFileSync(join(out, 'REVIEW.md'), reportText);
console.log(`故事拼音${check ? '校验' : '生成'}通过：${books} 册、${stories} 篇、${sentences} 句、${characters} 个字符。`);
