# RD-23 发版验收:截图测试、性能、无签名 ipa

> 先读 [README](../README.md) 第 1 节全局规则。

**依赖**:全部卡片合并到 `redesign/v2` 之后

## 目标
在把 `redesign/v2` 合并回 `main` 之前做一次完整的验收,并产出可以直接自签安装的**无签名 ipa**。

## 范围
### 1. 截图测试
- 更新 `ChinaTextbookStudyUITests/ScreenshotTests.swift`:按设计稿顺序截 20 张(宠物家族、首页地图、识字五步、字源卡、结算、签到、宠物小屋、商店、数学、英语、看图识物、成语选择、成语播放、绘本、书屋、家长中心),命名和 `design/png/` 一致。
- 设备:iPhone SE (3rd gen)、iPhone 16、iPad (A16)。
- 新增脚本 `scripts/redesign/compare-shots.sh`:把截图和 `design/png/` 拼成左右对比图,输出到 `docs/redesign-v2/evidence/rd-23/`。
- 审阅者逐张看,和设计稿差别较大的地方开新卡修,不在本卡改界面。

### 2. 全流程 UI 测试 `RedesignFlowUITests`
新用户从零开始,依次完成:
1. 首次引导;
2. 首页;
3. 第一节课闯关;
4. 结算;
5. 喂宠物;
6. 签到;
7. 数学小火车一局;
8. 家长门。

测试中途不能卡死,也不能出现找不到的元素。

### 3. 存档兼容
- 用 `main` 分支的 App 造一个「老用户」存档:有连签、宝石、皮肤、错题、阅读记录。导出备份 JSON,放进 `ChinaTextbookStudyTests/Fixtures/legacy-progress.json`。
- 测试用新版本导入这份存档:字段都在,皮肤已迁移成宠物配饰(RD-06),金币数不变。
- Web 端导入新版本导出的备份,能读(`packages/core` 测试)。

### 4. 性能
- 用 Instruments 录 iPhone SE 真机或模拟器的数据,PR 里附结论:
  - 首页地图滚动 ≥ 55fps;
  - 识字「写」这一步描红 ≥ 55fps;
  - 冷启动到首页 < 2.5 秒(SE);
  - 首页常驻内存 < 250MB。
- 不达标的项目列出原因和改进建议,由审阅者决定是否阻塞发版。

### 5. 包体与 ipa
- 记录 .app 体积:改版前后各多少,字体和新内容各占多少。
- **无签名 ipa**(用户自签安装,**不要配置签名、Team ID 或 Bundle ID**):
```
xcodebuild -project apps/mobile/ChinaTextbookStudy.xcodeproj -scheme ChinaTextbookStudy \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath build/dd CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" build
mkdir -p build/ipa/Payload && cp -R build/dd/Build/Products/Release-iphoneos/ChinaTextbookStudy.app build/ipa/Payload/
(cd build/ipa && zip -qry ChinaTextbookStudy-redesign-unsigned.ipa Payload)
```
- 把上面的命令写成 `scripts/redesign/build-unsigned-ipa.sh`。先跑 `xcodegen generate`,产物输出到 `output/ios-build/`。
- 如果 widget 扩展在无签名构建下报错,在脚本里说明处理方式,不要关掉 widget 功能。

### 6. 收尾
- README 第 4 节所有卡片状态改为「已合并」。
- 写 `docs/redesign-v2/CHANGELOG.md`:面向用户的改版说明,10 条以内。

## 验收标准
- AC1 3 台设备 × 20 张对比图齐全。
- AC2 `RedesignFlowUITests` 和全部旧测试通过,`npm test` 通过。
- AC3 老存档兼容测试通过。
- AC4 性能数据和包体数据写在 PR 里。
- AC5 `output/ios-build/ChinaTextbookStudy-redesign-unsigned.ipa` 能生成。用 `unzip -l` 确认里面有 `Payload/ChinaTextbookStudy.app`,并附上 `codesign -dv` 的输出,证明未签名。

## 审阅重点
- 本卡只做验收和打包,发现的界面问题开新卡修,不在本卡顺手改。
