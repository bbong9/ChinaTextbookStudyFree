import { readFileSync, writeFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { buildBackup, validateBackup } from "../backup";

const fixtures = new URL("../../../../apps/mobile/ChinaTextbookStudyTests/Fixtures/", import.meta.url);
const tsBackup = buildBackup({ platform: "web", exportedAt: "2026-10-21T08:00:00.000Z", data: {
  xp: 123, gems: 456, pictureWordsSeen: ["duck", "sheep", "apple", "future-word"],
} });

describe("RD-16 图鉴备份", () => {
  it("从生产 buildBackup 生成 TS 夹具，校验往返保留词条", () => {
    if (process.env.RD16_GENERATE_FIXTURE === "1") {
      writeFileSync(new URL("picture-words-ts.json", fixtures), JSON.stringify(tsBackup, null, 2) + "\n");
    }
    const fixture = JSON.parse(readFileSync(new URL("picture-words-ts.json", fixtures), "utf8"));
    expect(fixture).toEqual(tsBackup);
    expect(validateBackup(fixture).data).toEqual(tsBackup);
  });

  it("iOS 生产编码夹具在 core 中保留全部图鉴字段", () => {
    // 首次生成前可用 TS->iOS 的测试单独跑生成用例。
    const fixture = JSON.parse(readFileSync(new URL("picture-words-ios.json", fixtures), "utf8"));
    const result = validateBackup(fixture);
    expect(fixture.platform).toBe("ios");
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
    expect(result.data?.data.pictureWordsSeen).toEqual(tsBackup.data.pictureWordsSeen);
  });

  it("旧档缺失、空数组和未来 id 均保持原样", () => {
    for (const pictureWordsSeen of [undefined, [], ["future-word", "sheep", "sheep"]]) {
      const envelope = buildBackup({ platform: "web", data: { pictureWordsSeen } });
      const result = validateBackup(JSON.parse(JSON.stringify(envelope)));
      expect(result.ok).toBe(true);
      expect(result.errors).toEqual([]);
      expect(result.data?.data.pictureWordsSeen).toEqual(pictureWordsSeen);
    }
  });

  it("单项坏类型只丢坏项；字段坏类型不拒收其他进度", () => {
    for (const field of [null, false, 42, {}]) {
      const result = validateBackup({ ...tsBackup, data: { ...tsBackup.data, pictureWordsSeen: field } });
      expect(result.ok).toBe(true);
      expect(result.data?.data.pictureWordsSeen).toBeUndefined();
      expect(result.data?.data.gems).toBe(456);
    }
    const result = validateBackup({ ...tsBackup, data: { pictureWordsSeen: ["sheep", 42, null, "future-word"] } });
    expect(result.data?.data.pictureWordsSeen).toEqual(["sheep", "future-word"]);
  });
});
