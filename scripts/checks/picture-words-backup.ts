import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { buildBackup, validateBackup } from "@cstf/core/backup";

async function main() {
  const storage = new Map<string, string>();
  Object.defineProperty(globalThis, "localStorage", { configurable: true, value: {
    getItem: (key: string) => storage.get(key) ?? null,
    setItem: (key: string, value: string) => storage.set(key, value),
    removeItem: (key: string) => storage.delete(key),
  } });
  const { useProgressStore } = await import("../../apps/web/src/store/progress");
  const fixture = JSON.parse(readFileSync(new URL(
    "../../apps/mobile/ChinaTextbookStudyTests/Fixtures/picture-words-ios.json", import.meta.url,
  ), "utf8"));
  const validated = validateBackup(fixture);
  assert.equal(validated.ok, true);
  assert.deepEqual(validated.errors, []);
  assert.ok(validated.data);
  useProgressStore.getState().importBackup(validated.data);
  const seen = fixture.data.pictureWordsSeen;
  assert.deepEqual(useProgressStore.getState().exportBackup().data.pictureWordsSeen, seen);
  const persisted = storage.get("csf-progress-v1");
  assert.ok(persisted);
  useProgressStore.setState({ pictureWordsSeen: undefined });
  storage.set("csf-progress-v1", persisted);
  await useProgressStore.persist.rehydrate();
  assert.deepEqual(useProgressStore.getState().exportBackup().data.pictureWordsSeen, seen);
  for (const pictureWordsSeen of [[], ["future-word", "sheep", "sheep"], undefined]) {
    useProgressStore.getState().importBackup(buildBackup({ platform: "ios", data: { pictureWordsSeen } }));
    useProgressStore.getState().toggleMute();
    assert.deepEqual(useProgressStore.getState().exportBackup().data.pictureWordsSeen, pictureWordsSeen);
  }
  console.log("RD-16 网页图鉴备份：iOS 回环、持久化恢复、空图鉴、未来 id、旧档覆盖 5 项通过。");
}
main().catch(error => { console.error(error); process.exitCode = 1; });
