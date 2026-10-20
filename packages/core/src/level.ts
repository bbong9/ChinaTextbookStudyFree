import { ECONOMY_V2 } from "./economyV2";

export interface LevelInfo {
  level: number;
  xpIntoLevel: number;
  /** 从当前实际等级升到下一级所需 XP（不是累计 XP）。 */
  xpForNextLevel: number;
}

/** 50 × n × (n − 1)；只把显示等级封顶 99，XP 及升级进度继续计算。 */
export function levelInfo(totalXp: number): LevelInfo {
  const xp = Number.isFinite(totalXp) ? Math.max(0, Math.floor(totalXp)) : 0;
  const { xpFactor, displayCap } = ECONOMY_V2.level;
  const actualLevel = Math.floor((1 + Math.sqrt(1 + 4 * xp / xpFactor)) / 2);
  return {
    level: Math.min(displayCap, actualLevel),
    xpIntoLevel: xp - xpFactor * actualLevel * (actualLevel - 1),
    xpForNextLevel: 2 * xpFactor * actualLevel,
  };
}
