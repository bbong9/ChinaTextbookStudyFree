# RD-06 宠物存档与状态

> 先读 [README](../README.md) 第 1 节全局规则。

**依赖**:RD-05 · RD-04 合并后再接 `PetEnvironment`

## 目标
宠物的拥有、出战、饼干、照顾状态进存档,`ProgressStore` 提供操作接口,并接上 RD-04 的 `PetView`。

## 范围
### 1. 存档字段(`UserProgress`,全部 Optional)
| 字段 | 类型 | 含义 |
| --- | --- | --- |
| `ownedPets` | `[String]` | 已拥有宠物 id;读取时缺省 = `["pet_mituan"]` |
| `activePet` | `String` | 出战宠物;缺省 `pet_mituan` |
| `petTreats` | `Int` | 饼干库存 |
| `treatsFromLessonsDate` / `treatsFromLessonsCount` | `String` / `Int` | 当日从课程拿到的饼干数(上限账本) |
| `petCare` | `[String: PetCareState]` | 每只宠物的照顾状态 |
| `petAccessory` | `[String: String]` | 每只宠物戴的配饰 id(配饰就是旧皮肤 id) |

`PetCareState`:`fullness`、`clean`、`happy`(0–100)、`updatedAt`(Unix 毫秒)、`lastBathAt`、`lastPlayAt`。

同步改 `packages/core/src/backup.ts` 和 `Domain/Backup.swift`,保证新字段两端都能导出、导入;旧客户端不认识的字段不报错。

### 2. 旧档迁移(一次性,幂等)
- `equippedMascotSkin` 如果不是 `skin_default`,就变成米团的配饰:`petAccessory["pet_mituan"]`。
- `ownedCosmetics` 里的皮肤保持拥有,在 UI 上改叫「配饰」,id 不变。
- 不退款,不没收。
- 用一个迁移标记字段 `petsMigrated: Bool?` 保证只执行一次。

### 3. 照顾状态(纯函数 `Domain/PetCare.swift`,只在 Swift 侧)
- **衰减**(按经过的真实时间计算,打开 App 时结算):饱饱每 8 小时 −10,干净每 12 小时 −10,开心每 12 小时 −10。**下限 20**,永远不会到 0,也没有生病、离家、死亡。
- **喂食**:消耗 1 块饼干,饱饱 +25(上限 100),开心 +5。没饼干时按钮置灰,提示「去闯关赚饼干」。
- **洗澡**:免费,冷却 4 小时,干净设为 100。
- **玩耍**:免费,冷却 1 小时,开心 +30。
- **学习加成**:每完成一节课(任意类型),出战宠物开心 +10。
- 照顾状态只影响宠物表情和台词,**不影响任何经济数值**:
  - 开心 < 40 → `sad`;
  - 饱饱 < 40 → 提示「肚子饿啦」;
  - 其他情况 → `happy`。
- 不发任何催促通知。现有的学习提醒通知不受影响。

### 4. `ProgressStore` 接口
- `ownedPets`、`activePet`、`setActivePet(_:)`
- `canAdopt(_:)`:返回可领养,或不可领养的原因(金币不足 / 未达等级 / 未满 7 天 / 已拥有 / 已售完)
- `adopt(_:)`:扣金币,写拥有。神秘蛋走 `hatchEgg()`,返回孵出的宠物 id;蛋本身不进 `ownedPets`
- `petTreats`、`feed()`、`bathe(now:)`、`play(now:)`、`careState(for:now:)`
- `setAccessory(_:for:)`
- 课程结算 `completeLesson` 里调用 core 的 `lessonTreatReward` 发饼干,并把结果写进 `LessonOutcome.treatsGained`
- `canUnlock` 依赖的等级用 RD-05 的 `levelInfo(progress.xp)`

### 5. 接线
- RD-04 的 `PetEnvironment` 改为从 `ProgressStore.activePet`、配饰、照顾状态派生。

## 验收标准
- AC1 单元测试 `PetStateTests` 覆盖:
  - 领养成功、金币不足、等级不足、连签不足;
  - 神秘蛋按顺序孵出 3 次,之后下架;
  - 喂食没饼干;洗澡和玩耍的冷却;
  - 衰减跨 3 天后停在 20;
  - 迁移幂等(连续执行两次结果相同);
  - 每日饼干上限第 6 块不发。
- AC2 备份往返测试:iOS 导出 → `validateBackup`(TS)能读出新字段;TS 生成的含新字段的备份 → iOS 导入一致。把 TS 生成的样本存为测试夹具。
- AC3 老存档(没有任何新字段的真实样本,放进测试夹具)启动后:拥有米团、出战米团、饼干 0、原皮肤变成米团配饰。
- AC4 原有测试和黄金向量测试通过。

## 审阅重点
- 衰减按时间差计算,和打开 App 的频率无关;时钟回拨(时间差 < 0)时不变化。
- 领养的扣钱和写拥有在同一次 `save()` 里完成,不会出现扣了钱没拿到宠物。
