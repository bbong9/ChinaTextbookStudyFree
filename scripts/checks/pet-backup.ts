import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { buildBackup, validateBackup, type BackupData, type BackupEnvelope } from "@cstf/core/backup";

const petKeys = [
  "ownedPets", "activePet", "petTreats", "treatsFromLessonsDate",
  "treatsFromLessonsCount", "petCare", "petAccessory", "petsMigrated",
] as const;
const petFields = (data: Partial<BackupData>) =>
  Object.fromEntries(petKeys.filter(key => data[key] !== undefined).map(key => [key, data[key]]));
const json = <T>(value: T): T => JSON.parse(JSON.stringify(value));

async function main() {
  const storage = new Map<string, string>();
  Object.defineProperty(globalThis, "localStorage", { configurable: true, value: {
    getItem: (key: string) => storage.get(key) ?? null,
    setItem: (key: string, value: string) => storage.set(key, value),
    removeItem: (key: string) => storage.delete(key),
  } });
  const { useProgressStore } = await import("../../apps/web/src/store/progress");
  const fixture = JSON.parse(readFileSync(new URL(
    "../../apps/mobile/ChinaTextbookStudyTests/Fixtures/pet-backup-ios.json", import.meta.url,
  ), "utf8")) as BackupEnvelope;
  const validated = validateBackup(fixture);
  assert.equal(validated.ok, true);
  assert.deepEqual(validated.errors, []);
  assert.ok(validated.data);
  useProgressStore.getState().importBackup(validated.data);
  assert.deepEqual(petFields(json(useProgressStore.getState().exportBackup()).data), petFields(fixture.data),
    "iOS 备份经实际网页 store 导入再导出，八个字段必须完全一致");

  // 清掉内存后从 persist 的 localStorage 快照恢复，验证刷新页面也不会丢失。
  const persisted = storage.get("csf-progress-v1");
  assert.ok(persisted);
  assert.deepEqual(petFields(JSON.parse(persisted).state), petFields(fixture.data));
  useProgressStore.setState(Object.fromEntries(petKeys.map(key => [key, undefined])));
  storage.set("csf-progress-v1", persisted);
  await useProgressStore.persist.rehydrate();
  assert.deepEqual(petFields(json(useProgressStore.getState().exportBackup()).data), petFields(fixture.data));

  // 未迁移标记、零值、空集合和网页不认识的 id 都必须保留，不能套用 iOS 迁移。
  const opaque = buildBackup({ platform: "ios", data: {
    ownedPets: ["pet_future", "pet_fox", "pet_future"], activePet: "pet_future",
    petTreats: 0, treatsFromLessonsDate: "", treatsFromLessonsCount: 0,
    petCare: {}, petAccessory: { pet_future: "skin_future" }, petsMigrated: false,
  } });
  const expectedOpaque = petFields(json(opaque.data));
  useProgressStore.getState().importBackup(opaque);
  useProgressStore.getState().toggleMute(); // 普通网页操作不能改宠物数据。
  assert.deepEqual(petFields(json(useProgressStore.getState().exportBackup()).data), expectedOpaque);

  useProgressStore.getState().importBackup(buildBackup({ platform: "web" }));
  assert.deepEqual(petFields(json(useProgressStore.getState().exportBackup()).data), {},
    "导入无宠物字段的旧备份必须覆盖上一份备份，不能残留宠物数据");
  assert.deepEqual(petFields(JSON.parse(storage.get("csf-progress-v1")!).state), {});
  console.log("网页宠物备份：iOS 回环、持久化恢复、不透明字段、旧档覆盖 4 项通过。");
}

main().catch(error => { console.error(error); process.exitCode = 1; });
