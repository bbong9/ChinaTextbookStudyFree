# RD-06 测试夹具

- `legacy-progress-eaeff4f.json`：使用真实旧版本 `eaeff4f43353cfe7aad4ff1e28ef7aa3f6a1c93d` 的 `Models/CoreTypes.swift` 和旁边的 `legacy-progress-generator.swift.txt` 编译生成。内容为合成测试进度，无真实用户数据；由旧模型的 `JSONEncoder` 输出，没有通过删除新模型字段来伪造旧档。
- `pet-backup-ts.json`：由 `packages/core/src/__tests__/petBackup.test.ts` 调用生产代码 `buildBackup` 生成。复现：在仓库根执行 `RD06_GENERATE_FIXTURE=1 npm test --workspace=@cstf/core -- src/__tests__/petBackup.test.ts -t 'TS 生成'`。
- `pet-backup-ios.json`：由模拟器上的 `PetBackupTests.testIOSExportMatchesFixtureAndRoundTripsEveryPetField` 调用生产代码 `Backup.makeEnvelope` / `Backup.encode` 输出。测试同时在本地 `output/rd-06/ios-pet-backup.json` 留下实际输出；TS 测试对提交的夹具调用 `validateBackup`，逐项验证宠物扩展字段。

重建旧档：用 `git show eaeff4f43353cfe7aad4ff1e28ef7aa3f6a1c93d:apps/mobile/ChinaTextbookStudy/Models/CoreTypes.swift` 取出旧模型到临时目录，将生成器复制为该目录的 `main.swift`，用 `swiftc CoreTypes.swift main.swift -o generate` 编译，再执行 `./generate <夹具绝对路径>`。
