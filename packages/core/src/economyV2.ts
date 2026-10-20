/** RD-05 经济数值表；Swift 镜像见 Domain/EconomyV2.swift。货币字段仍用 gems。 */
import { WEEKEND_XP_MULTIPLIER, XP_PER_CORRECT } from "./economy";
import { dateKey, weekDateKeys, weekStartKey } from "./week";

export interface EconomyReward {
  gems: number;
  xp: number;
}

export interface StudyChest {
  /** 同时作为每日领取账本中的档位标识。 */
  readonly minutes: number;
  readonly gems: number;
  readonly treats: number;
}

/** 所有新增可调数值集中于此；已有的首答 XP、周末倍率继续复用 economy.ts。 */
export const ECONOMY_V2 = {
  level: { xpFactor: 50, displayCap: 99 },
  // D1：设计稿旧价分别为 1200 / 1500 / 2000 / 800，以下为定稿价格。
  pets: [
    { id: "pet_mituan", name: "米团", acquisition: "starter", price: 0,
      skill: "学习陪伴；Lv5 起开花形态", floweringLevel: 5 },
    { id: "pet_fox", name: "阿橘", acquisition: "purchase", price: 450,
      skill: "数学小火车每局多 1 次提示" },
    { id: "pet_cat", name: "奶糖", acquisition: "purchase", price: 600,
      skill: "识字闯关「练」每关多 1 次提示" },
    { id: "pet_penguin", name: "冰冰", acquisition: "purchase", price: 800,
      skill: "英语气球里用英语鼓励你" },
    { id: "pet_owl", name: "博博", acquisition: "streak", price: 0,
      skill: "课外书屋每日导读由博博朗读", requiredStreak: 7 },
    { id: "pet_dragon", name: "云宝", acquisition: "level", price: 0,
      skill: "成语动画专属解说开场", requiredLevel: 10 },
    { id: "pet_egg", name: "神秘蛋", acquisition: "purchase", price: 300,
      skill: "按固定顺序孵出小黄鸭 → 噜噜 → 咩咩" },
    { id: "pet_duck", name: "小黄鸭", acquisition: "egg", price: null, skill: "无" },
    { id: "pet_pig", name: "噜噜", acquisition: "egg", price: null, skill: "无" },
    { id: "pet_sheep", name: "咩咩", acquisition: "egg", price: null, skill: "无" },
  ],
  eggHatchOrder: ["pet_duck", "pet_pig", "pet_sheep"],
  lessonTreats: { minStars: 2, reward: 1, dailyCap: 5 },
  // 下标为周期日；0 留空。金币签到仍沿用 dailyRewardForStreak，不覆盖旧表。
  checkInTreats: [0, 0, 0, 1, 0, 0, 1, 3],
  studyChests: [
    { minutes: 10, gems: 10, treats: 0 },
    { minutes: 20, gems: 15, treats: 0 },
    { minutes: 30, gems: 20, treats: 2 },
  ],
  miniGame: {
    goodAccuracy: 0.8, dailyRounds: 3,
    good: { gems: 8, xp: 10 }, base: { gems: 3, xp: 5 },
  },
  idiomWatch: { gems: 10, xp: 10 },
  hanzi: { choiceQuestions: 6, writeXp: 10, speakXp: 10 },
  reading: { minutes: 15, daily: { gems: 5, xp: 10 }, weeklyDays: 5, weeklyGems: 30 },
} as const;

export const STUDY_CHESTS: readonly StudyChest[] = ECONOMY_V2.studyChests;

/** 课程饼干账本由调用方按本地日期取出，本函数不读时钟、不修改账本。 */
export function lessonTreatReward(stars: number, treatsFromLessonsToday: number): number {
  const rule = ECONOMY_V2.lessonTreats;
  if (!Number.isFinite(stars) || !Number.isFinite(treatsFromLessonsToday) || stars < rule.minStars) return 0;
  const received = Math.max(0, Math.floor(treatsFromLessonsToday));
  return Math.min(rule.reward, Math.max(0, rule.dailyCap - received));
}

export function checkInCycleDay(effectiveStreak: number): number {
  const streak = Number.isFinite(effectiveStreak) ? Math.max(1, Math.floor(effectiveStreak)) : 1;
  return ((streak - 1) % (ECONOMY_V2.checkInTreats.length - 1)) + 1;
}

/** 入参是周期日（1–7）；有效连胜应先经 checkInCycleDay 转换。 */
export function checkInTreats(cycleDay: number): number {
  return ECONOMY_V2.checkInTreats[cycleDay] ?? 0;
}

/** claimedToday 保存本地当天已领取的分钟档位，例如 [10, 20]。 */
export function claimableStudyChests(minutesToday: number, claimedToday: readonly number[]): StudyChest[] {
  return STUDY_CHESTS
    .filter(chest => minutesToday >= chest.minutes && !claimedToday.includes(chest.minutes))
    .map(chest => ({ ...chest }));
}

/**
 * rewardedRoundsToday 是「该游戏、本地当天」已奖励局数，两个游戏分别计数。
 * isWeekend 由调用方按本地日期计算；返回的 XP 应同时计入总 XP、今日 XP 和联赛。
 * 金币不受周末倍率影响；达到每日上限后继续游戏，返回零奖励。
 */
export function miniGameReward(accuracy: number, rewardedRoundsToday: number, isWeekend = false): EconomyReward {
  const rule = ECONOMY_V2.miniGame;
  if (!Number.isFinite(accuracy) || !Number.isFinite(rewardedRoundsToday)
    || Math.max(0, Math.floor(rewardedRoundsToday)) >= rule.dailyRounds) return { gems: 0, xp: 0 };
  const reward = accuracy >= rule.goodAccuracy ? rule.good : rule.base;
  return { gems: reward.gems, xp: reward.xp * (isWeekend ? WEEKEND_XP_MULTIPLIER : 1) };
}

/** 只在完整播放结束时调用，alreadyWatched 指该成语是否已领过首次观看奖励。 */
export function idiomFirstWatchReward(alreadyWatched: boolean): EconomyReward {
  return alreadyWatched ? { gems: 0, xp: 0 } : { ...ECONOMY_V2.idiomWatch };
}

/** 识字关卡基础 XP；星级和金币继续调用 starsFromAccuracy、lessonGemDrip。 */
export function hanziLessonXp(firstTryCorrect: number, wrote: boolean, spoke: boolean): number {
  const rule = ECONOMY_V2.hanzi;
  const correct = Number.isFinite(firstTryCorrect)
    ? Math.min(rule.choiceQuestions, Math.max(0, Math.floor(firstTryCorrect))) : 0;
  return correct * XP_PER_CORRECT + (wrote ? rule.writeXp : 0) + (spoke ? rule.speakXp : 0);
}

/** 阅读记录使用 week.ts 本地日期键，与 iOS SRS.todayString 一致；now 显式传入。 */
export function readingLogReward(minutesRead: number, loggedDateKeys: readonly string[], now: Date): EconomyReward {
  if (minutesRead < ECONOMY_V2.reading.minutes || !Number.isFinite(minutesRead)
    || loggedDateKeys.includes(dateKey(now))) return { gems: 0, xp: 0 };
  return { ...ECONOMY_V2.reading.daily };
}

/** 按本地周一至周日计数，去重、忽略周外及未来记录；claimedWeekKeys 保存已领取周键。 */
export function weeklyReadingChallengeReward(
  loggedDateKeys: readonly string[], claimedWeekKeys: readonly string[], now: Date,
): number {
  const week = weekStartKey(now);
  if (claimedWeekKeys.includes(week)) return 0;
  const today = dateKey(now);
  const weekDays = new Set(weekDateKeys(week));
  const recorded = new Set(loggedDateKeys.filter(key => weekDays.has(key) && key <= today));
  return recorded.size >= ECONOMY_V2.reading.weeklyDays ? ECONOMY_V2.reading.weeklyGems : 0;
}
