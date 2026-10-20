import { ECONOMY_V2 } from "./economyV2";

export type PetId = typeof ECONOMY_V2.pets[number]["id"];

export interface Pet {
  readonly id: PetId;
  readonly name: string;
  readonly acquisition: "starter" | "purchase" | "streak" | "level" | "egg";
  /** 只能孵出的宠物没有售价，不能把 null 当成免费购买。 */
  readonly price: number | null;
  readonly skill: string;
  readonly floweringLevel?: number;
  readonly requiredStreak?: number;
  readonly requiredLevel?: number;
}

export interface PetUnlockContext {
  gems: number;
  level: number;
  claimedStreakRewards: readonly number[];
  owned: readonly string[];
}

export const PETS: readonly Pet[] = ECONOMY_V2.pets;

export function petById(id: string): Pet | undefined {
  return PETS.find(pet => pet.id === id);
}

/** D4：返回第一个尚未拥有的孵化伙伴，集齐后三只不再售蛋；不使用随机数。 */
export function nextEggHatch(owned: readonly string[]): PetId | undefined {
  return ECONOMY_V2.eggHatchOrder.find(id => !owned.includes(id));
}

/** 只判断领取/购买资格，不扣金币或写存档。神秘蛋可重复购买，直到集齐孵化伙伴。 */
export function canUnlock(pet: Pet | undefined, ctx: PetUnlockContext): boolean {
  if (!pet) return false;
  if (pet.id === "pet_egg") {
    return pet.price !== null && ctx.gems >= pet.price && nextEggHatch(ctx.owned) !== undefined;
  }
  if (ctx.owned.includes(pet.id)) return false;
  switch (pet.acquisition) {
    case "starter": return true;
    case "purchase": return pet.price !== null && ctx.gems >= pet.price;
    case "streak": return pet.requiredStreak !== undefined && ctx.claimedStreakRewards.includes(pet.requiredStreak);
    case "level": return pet.requiredLevel !== undefined && ctx.level >= pet.requiredLevel;
    case "egg": return false;
  }
}
