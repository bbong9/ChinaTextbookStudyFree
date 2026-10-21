# 项目约定

- 一律用中文回答;提交信息、PR 标题和描述也用中文。
- iOS 改版开发卡在 `docs/redesign-v2/`,开工前先读 `docs/redesign-v2/README.md`。
- **模拟器测试一律用 `scripts/redesign/sim-test.sh iphone16|se|ipad [额外参数]` 跑**,不要直接 `xcodebuild test`、不要新建或手动启动模拟器。这台 Mac 同一时间只允许一个模拟器测试,脚本会自动排队。卡片提示词里写的 xcodebuild 测试命令,一律换成这个脚本。
