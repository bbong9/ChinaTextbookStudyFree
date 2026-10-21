# RD-19 睡前绘本验收

基线：`origin/redesign/v2` 的 `9fee6e1c275d4baae497981045924fb8fa5ef6cc`。独立分支 `codex/rd-19-bedtime-story`。全部为本地 iOS 18.6 模拟器与 seed 内容验证，不代表真机验收。

## 验收对应

| 标准 | 实现与证据 |
| --- | --- |
| AC1 | 首篇是现有数据的《门口的小伞》（`chinese-g1up-s1-v2`）。沿用 `18-story.png` 的全屏画面、顶部缎带、底部 ruby 文字卡与朗读按钮；插图来自既有资源，缺图改用 RD-03 夜景与 RD-04 狐狸。见三机型 `*-reader-first.jpg`、`*-reader-long.jpg`。 |
| AC2 | `scripts/build-story-pinyin.mjs` 生成 12 册、188 篇、4110 句、104578 个字符，逐句验证拼音与原文字数一致、标点为空串。`StoryReadingTests.testEveryGeneratedSeedPinyinRowMatchesOriginalStory` 从最终 seed 解码核验。缺失、损坏、路径不安全、句子错位均降级；UI 用例验证隐藏拼音开关并可朗读。 |
| AC3 | `narration-highlight-with-audio.mp4` 展示真实录音播放、高亮和翻页。录音以实际 `duration/currentTime` 按可朗读字符均分，标点、空格不占时间。缺录音由系统 TTS 的实际范围回调高亮，见 `iphone16-system-tts.jpg`。 |
| AC4 | `Reading.id(.story, storyId)`、`Economy.storyQuizXp` 与 `ProgressStore.completeReading` 保持原逻辑。单测覆盖 0、0.799999、0.8、1；UI 实际答题验证 5 XP、15 XP、再次完成显示“已领过奖励”。见 `*-quiz-result-five-xp.jpg`、`iphone16-quiz-result-fifteen-xp.jpg`、`iphone16-quiz-repeat-no-xp.jpg`。 |
| AC5 | `bedtime-complete-with-audio.mp4` 从第 1 页连续播完全部 8 页，最后停止于晚安。用例确认跳过测验、返回书架后仍未读。睡前模式不发 XP、不写阅读完成、不调系统亮度。 |

## 视觉与交互

- 三机型均检查首篇男孩、女孩面部与主要动作完整；使用现有图片中心裁切，无需新增 focus 字段。最终 SE、iPad 长句两行完整显示，无需滚动；文字卡保留超长句的滚动能力。
- 阅读字号使用 `ClayFont.story(scale:english:)`，物理字号至少 28pt；字与自己的拼音作为整体换行，过长句允许在文字卡内滚动。
- 书架按单元分组，默认当前语文书，可切其他语文书；保留原英语故事入口，`en` / `English` 均隐藏拼音。
- 左右按钮、滑动翻页；自动朗读结束后等待 1.5 秒再翻页。离开、静音、进入后台均停止播放并取消待翻页任务。
- 使用既有 `Stage`、Clay 令牌与 RD-10 `LessonShell` / `QuestionRendererView`。点击区在 SE 用例中实测至少 44pt；减少动态效果时禁用过渡，夜景及狐狸没有循环动画。
- 新书架内容字体支持动态字体至 xxLarge。系统 TTS 兜底、英语字体与拼音隐藏均有 UI 证据。

## 录屏音轨说明

模拟器 `simctl recordVideo` 不采集声音。本目录视频的画面是实际运行录屏，音轨使用此次应用真正播放的同源原录音，按 DEBUG 证据开关记录的播放时间、时长与速率对齐合成，再以实际翻页帧校准视频起点；不是设备采音。`capture-timeline.json` 留存相对时间、原录音路径、SHA-256 和校准方法。

最终完整视频为 50.247 秒，逐页核对 1–8 页及晚安页；7 个翻页点最大校准残差 0.163 秒。合成音轨整体平均音量 -16.9 dB，8 段朗读逐段均通过非静音校验。

应用只在 DEBUG 且同时含 `-uitest -uitest-story-evidence` 时写这份临时记录，正常运行与 Release 不记录。录屏缩小为半分辨率并压缩，未提交原始录屏、音频副本或完整测试附件。

## 内容与依赖

- `pinyin-pro`（MIT，lock 固定 3.29.5）仅新增为根目录 devDependency，仅构建脚本引用；App 不在运行时生成拼音，也未加 SPM/UI 依赖。
- `content/story-pinyin/REVIEW.md` 是完整的多音字、轻声及一/不变调复核表；自动标注仍待人工逐句复核，未声称已经按课本全部校验。
- 可重复的人工校正规则放在 `scripts/story-pinyin-overrides.json`：首篇“背着书包”的背负读音、早上/地上/乐乐/谢谢的轻声，以及“月亮”的轻声。连续三声仍标本调。
- `seed-audit.json` 逐项比较基础包：原 2828 项字节不变、无删除，仅加入 14 项旁挂与许可/报告文件。没有改下载目录的 `stories.json`。

## 验证结果

| 设备 / 验证 | 通过 / 总数 | 失败 | 跳过 | 运行时警告 |
| --- | --- | --- | --- | --- |
| iPhone 16 | 346 / 346 | 0 | 0 | 0 |
| iPhone SE (3rd gen) | 1 / 1 | 0 | 0 | 0 |
| iPad (A16) | 1 / 1 | 0 | 0 | 0 |
| core 单测 | 370 / 370（15 个文件） | 0 | 0 | — |

core 类型检查、拼音生成及 `--check`、seed 打包、`git diff --check` 均通过。原始模拟器结果汇总见 `test-results.json`。

```sh
node scripts/build-story-pinyin.mjs
node scripts/build-story-pinyin.mjs --check
bash scripts/build-seed-zip.sh --content-only
npm test
npm run type-check --workspace=@cstf/core
LC_ALL=C scripts/redesign/sim-test.sh iphone16 -collect-test-diagnostics never
LC_ALL=C scripts/redesign/sim-test.sh se -only-testing:ChinaTextbookStudyUITests/StoryBookUITests/testReaderLayoutPinyinPagingAndExistingQuiz -collect-test-diagnostics never
LC_ALL=C scripts/redesign/sim-test.sh ipad -only-testing:ChinaTextbookStudyUITests/StoryBookUITests/testReaderLayoutPinyinPagingAndExistingQuiz -collect-test-diagnostics never
```

全部模拟器测试通过队列串行执行，使用默认 DerivedData 与 `CODE_SIGNING_ALLOWED=NO`。未配置签名、Team 或 Bundle ID。

## 范围与后续

- Dock 的 `.bedtimeStories` 已由 RD-01 预留，只做该分支接线及隐藏绘本自带页头之外的旧壳页头；未改首页、经济规则或存档字段。
- 提交前再次 fetch 确认当前集成基线没有 `StudyTimer`，按 COMMON 不自行实现；计时接入待 RD-08 合并后补。普通模式应计时、睡前模式排除。
- 主目录原有 `SeedInstaller.swift` 与 output 未跟踪文件均保留；本卡只在独立 worktree 修改。
