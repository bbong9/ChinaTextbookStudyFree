# RD-12 汉字数据管线

在仓库根目录运行（Node.js、Python 3、已有 npm 依赖）：

```sh
npx tsx scripts/hanzi/build-hanzi.ts chinese-g1up
npx tsx --test scripts/hanzi/build-hanzi.test.ts
bash scripts/build-seed-zip.sh --content-only
npm test
```

第一次运行会从 `data-sources.ts` 中的固定 URL 下载源文件，校验 SHA-256 后存入 `.cache/`。重复运行也会校验缓存；损坏时报错，需人工删除该缓存文件后重试。不提交原始笔顺/Unihan 文件、不写 `apps/web/public/data/`，不调用收费 TTS 服务。

- `sources/chinese-g1up.json` 是人工可编辑输入。字表、字卡、组词、字源均是 `draft`；不能用自动构建把它们升级为 `verified`。
- 输入显式区分识字表和写字表；输出 `units[].chars` 是它们有序去重的并集。卡片的 30–40 为预估，完整两单元初稿为 100 个去重字，版次与园地归属待人工核对，详见报告。
- `data-sources.ts` 定义笔顺适配器接口和 Make Me a Hanzi 实现；只输出本次字表所需的笔顺。
- Unihan 17.0.0 用 `kMandarin`/`kHanyuPinyin` 验证读音，以 `kRSUnicode` 和同版 `CJKRadicals.txt` 填充部首，并用 `kTotalStrokes` 作额外笔画数检查。Unicode 许可见 `content/hanzi/UNICODE-LICENSE`。这些部首未必与教材偏旁命名相同，仍需复核。
- 所有内容验证通过之后才写 `content/hanzi/<bookId>/`、共享笔顺和 `report-<bookId>.md`；字卡里不嵌入笔顺图形。
- 测试使用自写几何夹具；覆盖每种校验的故意错误样例、授权缺失 CLI 非零退出、坐标转换、缓存哈希和源读音解析。
- `--source <file>` 可选择待校验输入，输出仍由 `bookId` 决定；错误输入不会写文件。

## 无录音与后续录音

`audioPath()` 与 `scripts/tts/collect_texts.py` 共用“压缩空白、文本 UTF-8 SHA-1”的约定。`collect_texts.py` 会收集已生成的汉字、拼音、组词及字源讲解，登记到原有 manifest，供原有 `batch_tts.py` 消费。语音落地及发布仍由既有音频 Release 流程完成，本卡不生成录音。

Swift `DataLoader.loadHanziChar` 解码后把每个路径及原文登记进 `SpeechTextIndex`，缺录音时复用 `AudioPlayer` 的系统 TTS。汉字按钮和拼音按钮都朗读汉字，复用单字音频地址，避免拉丁拼音被当成英文，也避免 `me` 等文本与已有英语录音的全局哈希碰撞。多音字主读音只取 `pinyin`，其他读音仅作提示；系统 TTS 对孤立多音字的选音仍需人工试听。

## 打包

普通 `build-seed-zip.sh` 在原有打包完成后加入根目录 `content/`。本机没有 Release 课程目录时，可用 `--content-only` 从已有 seed 更新汉字内容；原有课程与录音的逐项内容保持一致，新的汉字内容不含音频。seed 的路径是 `data/hanzi/...`，沿用 `SeedInstaller` 的首启安装机制。许可与说明同样进入 seed。
