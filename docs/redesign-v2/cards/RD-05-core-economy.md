# RD-05 core 经济扩展

> 先读 [README](../README.md) 第 1 节全局规则,尤其是 1.1。

**依赖**:无 · **可并行**:RD-01、RD-02、RD-12
**已拍板**:README 第 5 节 D1、D3、D4 均按表中数值执行。数值仍集中放在一个常量表里,方便以后调。

## 目标
新版本里所有「发多少、花多少」的规则,一次性在 `packages/core` 定义好,Swift 端做镜像,并补黄金向量。后面的卡只调用这些函数,不自己定数值。

## 范围
### 1. 等级 `packages/core/src/level.ts` ↔ `Domain/Level.swift`
- 等级由累计 XP(`progress.xp`)决定,纯函数,不存档。
- 到达第 n 级所需累计 XP:`50 × n × (n − 1)`。即 Lv1 = 0、Lv2 = 100、Lv3 = 300、Lv5 = 1000、Lv10 = 4500。
- `levelInfo(totalXp) → { level, xpIntoLevel, xpForNextLevel }`。
- 显示上限 Lv99;超过仍算,但显示 99。

### 2. 宠物目录 `packages/core/src/pets.ts` ↔ `Domain/Pets.swift`
| id | 名字 | 获得方式 | 价格(金币) | 技能(只给不影响经济的效果) |
| --- | --- | --- | --- | --- |
| `pet_mituan` | 米团 | 开局赠送 | 0 | 学习陪伴;Lv5 起开花形态 |
| `pet_fox` | 阿橘 | 购买 | 450 | 数学小火车每局多 1 次提示 |
| `pet_cat` | 奶糖 | 购买 | 600 | 识字闯关「练」每关多 1 次提示 |
| `pet_penguin` | 冰冰 | 购买 | 800 | 英语气球里用英语鼓励你 |
| `pet_owl` | 博博 | 曾经连续学习满 7 天 | 0 | 课外书屋每日导读由博博朗读 |
| `pet_dragon` | 云宝 | 达到 Lv10 | 0 | 成语动画专属解说开场 |
| `pet_egg` | 神秘蛋 | 购买 | 300 | 按固定顺序孵出:小黄鸭 → 噜噜 → 咩咩;三只都有了以后下架 |
| `pet_duck` / `pet_pig` / `pet_sheep` | 小黄鸭 / 噜噜 / 咩咩 | 只能从神秘蛋孵出 | — | 无 |

- 「曾经连续学习满 7 天」直接用现有账本 `claimedStreakRewards` 是否包含 7 来判断,不新增字段。
- 价格按 D1 定稿。设计稿原值是 1200 / 1500 / 2000 / 800,写在注释里备查。
- 导出:`PETS`、`petById`、`canUnlock(pet, ctx)`(ctx 包含金币、等级、连胜账本、已拥有列表)、`nextEggHatch(owned)`。

### 3. 宠物饼干(新道具,整数计数)
- 课程结算:星级 ≥ 2 发 1 块;每天从课程拿到的饼干最多 5 块。`lessonTreatReward(stars, treatsFromLessonsToday)`。
- 签到:签到周期第 3 天和第 6 天各 +1,第 7 天 +3。`checkInTreats(cycleDay)`。
- 周期日:`checkInCycleDay(effectiveStreak) = ((max(1, streak) − 1) mod 7) + 1`。

### 4. 每日学习时长宝箱
- 三档:10 分钟、20 分钟、30 分钟。
- 奖励:10 金币;15 金币;20 金币 + 2 块饼干。
- 每档每天只能领一次。导出 `STUDY_CHESTS`、`claimableStudyChests(minutesToday, claimedToday)`。
- 「学习分钟」怎么计时在 RD-08 定义,这里只管奖励。

### 5. 小游戏奖励(数学小火车、英语气球)
- 一局结束后:正确率 ≥ 0.8 → 8 金币 + 10 XP;否则 3 金币 + 5 XP。
- 每个游戏每天最多 3 局有奖励,之后可以继续玩,但不发奖励,界面要说明。
- 导出 `miniGameReward(accuracy, rewardedRoundsToday)`。
- XP 计入今日 XP(影响每日目标和本地联赛)。宝石周末不翻倍,XP 是否吃周末双倍跟课程一致:**吃**。

### 6. 成语动画
- 每个成语第一次完整看完:10 金币 + 10 XP。重复观看不发。`idiomFirstWatchReward`。

### 7. 识字五步关卡(RD-13 用)
- 「玩」和「练」共 6 道选择题。首次答对数 `c`(0–6)。
- XP:`10 × c`,完成「写」再 +10,完成「说」再 +10。
- 星级:`starsFromAccuracy(c / 6)`,沿用现有阈值。
- 金币:`lessonGemDrip(stars, isFirstPerfect, crossedDailyGoal)`,沿用现有规则。
- 导出 `hanziLessonXp(firstTryCorrect, wrote, spoke)`。

### 8. 课外书屋(RD-20 用)
- 每天第一次记录「读了 15 分钟」:5 金币 + 10 XP。
- 一周内记录满 5 天(按 `week.ts` 的周键):额外 30 金币,每周一次。
- 导出 `readingLogReward`、`weeklyReadingChallengeReward`。

### 9. Swift 镜像与黄金向量
- `Domain/Economy.swift` 或新文件 `Domain/EconomyV2.swift`:同名常量用 camelCase,数值完全一致。
- `golden-vectors.json` 新增分组:`level`、`pets`、`lessonTreats`、`checkInCycle`、`studyChests`、`miniGame`、`idiomWatch`、`hanziXp`、`readingLog`。
- 每组至少覆盖:边界值(如 99 XP / 100 XP)、上限(第 6 块饼干、第 4 局)、空输入。
- TS 端在 `__tests__/goldenVectors.test.ts` 消费;Swift 端在 `GoldenVectorTests.swift` 消费。

## 不做
- 存档字段和 UI(RD-06 起)。
- 宠物照顾数值(开心 / 饱饱 / 干净)不属于经济,放 RD-06 的 Swift 侧。

## 验收标准
- AC1 `npm test` 通过,新增黄金向量全部被 TS 消费。
- AC2 `GoldenVectorTests` 通过,新增分组全部被 Swift 消费,没有跳过的分组。
- AC3 core 的 `index.ts` 导出了新模块,`npm run type-check` 通过。
- AC4 所有数值只在一处定义,Swift 里不出现与 core 不一致的魔法数字。审阅时抽查。
- AC5 PR 描述里有一张「收入速度」估算表:按每天 5 节课、平均 2 星、签到、学满 20 分钟、玩 2 局小游戏算,每天和每周能拿多少金币,以及第一只付费宠物需要几天。用来复核 D1 的价格是否合适。

## 审阅重点
- 黄金向量是否真的两端都读了同一个文件(不是各写一份)。
- 「每日上限」类规则的「今天」用本地日期,和现有 `SRS.todayString` 一致。
