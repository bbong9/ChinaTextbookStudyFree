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

完整日志与 xcresult 仅保留在本卡临时目录，提交证据只包含摘要与半分辨率截图。
