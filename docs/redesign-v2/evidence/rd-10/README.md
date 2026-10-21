# RD-10 验证记录

## 改版前基线

- 基线：`origin/redesign/v2`，`ac64013`，2026-10-21。
- `scripts/redesign/sim-test.sh iphone16 -only-testing:ChinaTextbookStudyUITests/LessonFlowUITests`：5/5 通过，0 失败。
- `scripts/redesign/sim-test.sh iphone16 -only-testing:ChinaTextbookStudyTests/LessonReplayTests`：1/1 通过，0 失败。
- 固定回放：实际 seed 的 `g1up / g1up-u1-kp1`，题号 `[1,3,6,8,9,11,14,15,19,20,22,23,1,8]`。
- 答案序列：`[对,对,C,A,D,C,C,C,3,6,7,8,错,B]`。第 1、4 次故意答错，末尾重练这两题。
- 注入日期：`2026-10-21T04:00:00Z`（周三）；生产 `Grade` 判分、生产 `ProgressStore.completeLesson` 结算。

| 阶段 | 首答答对 | XP | 星级 | 红心 | 回放次数 |
| --- | --- | --- | --- | --- | --- |
| 改版前 | 10/12 | 100 | 2 | 5 → 3 | 14 |

原始关键输出：

```text
RD-10 LessonOutcome: lesson=g1up-u1-kp1 answers=14 correct=10/12 XP=100 stars=2 hearts=5->3
Executed 1 test, with 0 failures
```

## 截图样本与证据边界

八种题型通过 `LessonPresentationTests.testEightSeedQuestionPresentations` 在模拟器窗口中承载生产 `LessonShell` 和 `QuestionRendererView`，每台设备一次拍完。局部暂停宠物和场景装饰动画，答案初始为空。该夹具不修改课程数据、生产路由或存档。

| 展示类型 | 教材 / 课程 | 题号 |
| --- | --- | --- |
| choice | g1up / g1up-u1-kp1 | 6 |
| trueFalse | g1up / g1up-u1-kp1 | 1 |
| fillBlank | g1up / g1up-u1-kp1 | 19 |
| calculation | g1up / g1up-u2-kp3 | 22 |
| wordProblem | g1up / g1up-u1-kp1 | 19，测试投影 |
| fillBlankText | english-g3up / english-g3up-u1-kp1 | 77 |
| wordOrder | chinese-g1down / chinese-g1down-u1-kp1 | 22 |
| matching | chinese-g1down / chinese-g1down-u1-kp1 | 19 |

当前打包 seed 只有七种题型，没有 `word_problem`。应用题截图仅在测试中将现有数字题的类型设为 `.wordProblem`，用于验证独立分发分支；它不代表 seed 原生提供了第八类型。

`LessonShellFlowUITests` 另从真实首页进入关卡，执行固定答案、断心后复习回心并续学、英语文字键盘输入、15 题跳级测试。组件展示与完整导航流程分别记录，不作为真机或 VoiceOver 人工验收。

## 逻辑边界核对

与改版前 `ac64013` 对比，以下生产函数原文相同：

- `LessonRunnerView`：`check`、`finish`、`persistSession`、`applyResume`、`proceed`、`advance`、`load`、`submitReport`、`autoNarrate`、`pickTitle`；`OutOfHeartsGate.countdown` 也相同。
- `JumpTestView`：`advance`、`finish`、`retry`、`prepare`、`sampleQuestions`。
- `MistakeReviewRunnerView`：`check`、`advance`。
- `QuestionViews`：`cardState`、`tfCardState`、`letterFor`、`pick`、`unpick`、`tapLeft`、`tapRight`、`commitAllMatched`、`WordOrderFormat.readableAnswer`、流式排列计算。
- `XPFloaterView.start` 以及连击的声音与时序沿用原实现。

完整日志与 xcresult 仅在本卡临时目录用于验证，PR 创建后清理；提交证据只包含摘要与半分辨率截图。
