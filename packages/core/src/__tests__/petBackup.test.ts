import { readFileSync, writeFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { buildBackup, validateBackup } from "../backup";

const fixtureURL = new URL("../../../../apps/mobile/ChinaTextbookStudyTests/Fixtures/", import.meta.url);
const readFixture = (name: string) => JSON.parse(readFileSync(new URL(name, fixtureURL), "utf8"));

// 此样本由真实 buildBackup 生成；不手工拼备份信封。
const tsBackup = buildBackup({
  platform: "web",
  exportedAt: "2026-10-20T08:00:00.000Z",
  data: {
    xp: 560, gems: 1234, lifetimeGems: 1500,
    ownedPets: ["pet_mituan", "pet_fox", "pet_duck"],
    activePet: "pet_fox", petTreats: 4,
    treatsFromLessonsDate: "2026-10-20", treatsFromLessonsCount: 5,
    petCare: {
      pet_mituan: { fullness: 72.5, clean: 80, happy: 35, updatedAt: 1792483200000 },
      pet_duck: { fullness: 100, clean: 100, happy: 100, updatedAt: 1792483200000 },
      pet_fox: {
        fullness: 40, clean: 100, happy: 75.25, updatedAt: 1792483200000,
        lastBathAt: 1792479600000, lastPlayAt: 1792481400000,
      },
    },
    petAccessory: { pet_mituan: "skin_graduate", pet_fox: "skin_glasses" },
    ownedCosmetics: { skin_graduate: true, skin_glasses: true },
    petsMigrated: true,
  },
});

describe("RD-06 宠物备份互通", () => {
  it("TS 生成的夹具与 buildBackup 一致，校验不丢新字段", () => {
    if (process.env.RD06_GENERATE_FIXTURE === "1") {
      writeFileSync(new URL("pet-backup-ts.json", fixtureURL), JSON.stringify(tsBackup, null, 2) + "\n");
    }
    const fixture = readFixture("pet-backup-ts.json");
    expect(fixture).toEqual(tsBackup);
    const result = validateBackup(fixture);
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
    expect(result.data).toEqual(tsBackup);
  });

  it("iOS 实际导出的夹具经 validateBackup 保留全部宠物字段", () => {
    const fixture = readFixture("pet-backup-ios.json");
    const result = validateBackup(fixture);
    expect(fixture.platform).toBe("ios");
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
    expect(result.data).toEqual(fixture);
    for (const key of ["ownedPets", "activePet", "petTreats", "treatsFromLessonsDate",
      "treatsFromLessonsCount", "petCare", "petAccessory", "petsMigrated"] as const) {
      expect(result.data?.data[key]).toEqual(tsBackup.data[key]);
    }
  });

  it("旧信封不凭空补迁移标记；未知字段不报错", () => {
    const old = buildBackup({ platform: "web", data: { gems: 123 } });
    const result = validateBackup({ ...old, data: { ...old.data, futureField: { a: 1 } } });
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
    expect(result.data?.data.petsMigrated).toBeUndefined();
    expect(result.data?.data.ownedPets).toBeUndefined();
  });

  it("损坏的单项不会丢掉整个备份或同伴状态", () => {
    const result = validateBackup({
      ...tsBackup,
      data: {
        ...tsBackup.data, petTreats: -1, treatsFromLessonsCount: 2.5,
        ownedPets: ["pet_mituan", 42], petsMigrated: "true",
        petAccessory: { pet_mituan: "skin_graduate", pet_fox: false },
        petCare: {
          pet_mituan: { fullness: 120, clean: -10, happy: 50, updatedAt: 123 },
          pet_fox: { fullness: "bad", clean: 90, happy: 90, updatedAt: 123 },
          pet_cat: { fullness: 90, clean: 90, happy: 90, updatedAt: -1 },
        },
      },
    });
    expect(result.ok).toBe(true);
    expect(result.errors.length).toBeGreaterThan(0);
    expect(result.data?.data.petTreats).toBeUndefined();
    expect(result.data?.data.treatsFromLessonsCount).toBeUndefined();
    expect(result.data?.data.petsMigrated).toBeUndefined();
    expect(result.data?.data.ownedPets).toEqual(["pet_mituan"]);
    expect(result.data?.data.petAccessory).toEqual({ pet_mituan: "skin_graduate" });
    expect(result.data?.data.petCare).toEqual({ pet_mituan: { fullness: 100, clean: 0, happy: 50, updatedAt: 123 } });
  });
});
