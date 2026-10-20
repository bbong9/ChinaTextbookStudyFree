# RD-12 汉字内容包与数据管线

> 先读 [README](../README.md) 第 1 节全局规则,尤其是 1.3 内容与版权。

**依赖**:无 · **可并行**:RD-01、RD-02、RD-05
**已拍板**:D5 接受 APL,笔顺数据单独存放;D6 第一版不放古文字字形。

## 背景
现有语文课程是「知识点 + 题目」,没有逐字的数据(拼音、笔顺、组词、图片、读音)。识字五步关卡(RD-13)需要一个新的汉字内容包。本卡只做**数据格式、生成脚本和试点数据**,不做界面。

## 范围
### 1. 数据格式(`packages/core/src/hanzi.ts` 定义类型,Swift 侧 `Models/Hanzi.swift` 做 `Codable` 镜像)
```
content/hanzi/<bookId>/index.json
{
  "version": 1,
  "bookId": "chinese-g1up",
  "units": [ { "unitNumber": 2, "title": "识字(一)", "chars": ["日","月","水","火","山","石","田","禾"] } ]
}

content/hanzi/<bookId>/chars/<码位十六进制>.json      例如 5c71.json = 山
{
  "char": "山",
  "pinyin": "shān",
  "pinyinAlternates": [],                 // 多音字的其他读音,本课不用的读音放这里
  "strokeCount": 3,
  "strokeNames": ["竖", "横折", "竖"],    // 笔画名称是我们自己标注的,和下面的 strokes 文件一一对应
  "radical": "山",
  "structure": "独体字",
  "words": [ { "text": "高山", "pinyin": "gāo shān", "audio": "/audio/…" } ],   // 2–4 个
  "scene": "mountains" | null,             // 「认」这一步的看图场景 id,只有象形字才有
  "sceneCaption": "看图:三座山峰",
  "origin": {                              // 可以为 null
    "kind": "象形",
    "explanation": "像三座连在一起的山峰,中间那座最高。",
    "forms": [ { "script": "jiaguwen" | "jinwen" | "xiaozhuan", "svgPath": "…", "source": "…", "license": "…" } ]
  },
  "distractors": { "shape": ["出","田"], "sound": ["衫"] },
  "audio": { "char": "/audio/…", "pinyin": "/audio/…", "origin": "/audio/…" }
}
```
```
content/hanzi/strokes/<码位十六进制>.json          按 APL 分发,和上面的 chars 文件分开存放
{
  "char": "山",
  "strokes": [ { "outline": "<SVG path>", "median": [[x,y], …] } ],   // 坐标系 1024×1024,y 轴向下
  "source": "Make Me a Hanzi (graphics.txt)", "license": "Arphic Public License"
}
```
- 笔顺文件按字共享,不分书。`DataLoader` 读字时把两份文件合并成一个模型;笔顺文件缺失时 `strokes` 为空。
- `source` 和 `license` 是**必填**项。生成脚本遇到缺失直接报错退出。
- 音频路径沿用现有内容寻址规则(`/audio/<前两位>/<sha1>.<ext>`),由现有 `scripts/tts/` 管线生成。

### 2. 生成脚本 `scripts/hanzi/`
- `sources/<bookId>.json`:手工整理的输入,包括每单元的字表、本课读音、组词、场景 id、形近字和同音干扰字、字源讲解。
- `build-hanzi.ts`:读取输入 + 笔顺数据源 + Unihan(拼音、部首;Unicode 许可证),输出第 1 节格式。
- 校验项:
  - 拼音必须在 Unihan `kMandarin` 或 `kHanyuPinyin` 读音集合内(防止手误);
  - 笔画数、`strokeNames` 数量和笔顺文件的笔画数三者一致;
  - 干扰字不能和目标字同音(shape 组)或同形(sound 组);
  - 组词必须包含目标字。
- 输出一份报告 `scripts/hanzi/report-<bookId>.md`,列出每个字的数据来源、缺失项、需要人工复核的点(多音字、笔顺有争议的字)。

### 3. 笔顺数据
- **D5 已定:接受 APL。** 脚本做成「数据源适配器」接口,实现 Make Me a Hanzi 适配器。上游数据文件下载到 gitignore 的缓存目录,不提交原始 `graphics.txt`;只提交转换后、试点用到的字。
- 下载地址和固定的 commit hash 写在脚本里,校验 sha256。
- APL 全文放到 `content/hanzi/strokes/LICENSE`,同目录放 `README.md`,写明来源、转换方式和「本目录数据按 APL 分发」。
- App 的「关于」页列出这条来源(RD-21)。
- 笔顺必须符合《通用规范汉字笔顺规范》。报告里列出与该规范不一致的字。

### 4. 古文字字形
- **D6**:第一版不提交任何古文字字形,`origin.forms` 为空数组,只保留 `kind` 和 `explanation`。
- RD-13 根据 `forms` 是否为空决定字源卡显示时间轴还是只显示文字。

### 5. 试点范围
- 书:`chinese-g1up`(统编版一年级上册)。
- 单元:「识字(一)」和「识字(二)」两个单元的识字表和写字表,预计 30–40 个字。
- 字表、组词、字源讲解都由 Codex 整理成初稿,**最终要对照纸质课本和教参人工复核**:报告里列出复核清单,复核前状态标 `draft`。

### 6. 打包
- 试点数据放进 seed 包:改 `scripts/build-seed-zip.sh`,把 `content/hanzi/chinese-g1up/` 打进 `seed-data.zip`,和课程数据一样首启安装。
- `DataLoader` 新增 `loadHanziIndex(bookId:)` 和 `loadHanziChar(bookId:char:)`;找不到文件时返回 `nil`,不抛错。
- 新音频登记进 `SpeechTextIndex`,没有录音文件时可以用系统 TTS 兜底。

## 不做
- 识字界面(RD-13)。
- 试点以外的书。

## 验收标准
- AC1 `npx tsx scripts/hanzi/build-hanzi.ts chinese-g1up` 能运行;缺 `source` / `license` 时报错退出。
- AC2 校验项各有一个故意出错的样例,能被拦下。用脚本自带的测试或 `npm test` 证明。
- AC3 Swift 能解码全部试点字文件(单元测试 `HanziDecodingTests` 遍历 seed 包)。
- AC4 报告文件列出每个字的状态(`draft` / `verified`)和复核清单。
- AC5 seed 包体积增量写在 PR 里,不含音频时应 < 2MB。
- AC6 第三方笔顺数据只出现在 `content/hanzi/strokes/`,而且目录里有 LICENSE 和 README(审阅时检查 diff)。

## 审阅重点
- 数据格式是否足够 RD-13 用,不要等到做界面时再改格式:玩、认、练、写、说、字源卡每一步需要的字段都要有。
- 多音字处理:关卡里只用 `pinyin` 一个读音,`pinyinAlternates` 只用于提示。
