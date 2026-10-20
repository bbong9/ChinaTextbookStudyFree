# 共享汉字笔顺数据

**本目录数据按 Arphic Public License（APL）分发**，完整英文许可见 [LICENSE](LICENSE)。仓库的 App 与生成脚本代码仍按仓库根目录的 MIT 许可分发。

- 来源：[Make Me a Hanzi](https://github.com/skishore/makemeahanzi)，只使用 `graphics.txt`，不使用其字典、字源和古文字数据。
- 固定 commit：`bddc96d41bef78427ed0e034e9f7e31d71fd1b92`。
- 固定下载地址：`https://raw.githubusercontent.com/skishore/makemeahanzi/bddc96d41bef78427ed0e034e9f7e31d71fd1b92/graphics.txt`。
- 原文件 SHA-256：`a28c478b5178e98f67f510b2d52fde08a69dc664654ef43498253b9b764d46ee`。
- 上游图形源于 Arphic PL KaitiM GB 和 Arphic PL UKai；许可全文原样复制自同一 commit 的 `APL/english/ARPHICPL.TXT`。

## 转换说明

2026-10-20，RD-12 构建器从上游原始文件选择试点字，将 `character` 改为 `char`，将 `strokes` 与 `medians` 按索引合并为 `outline` 与 `median`。上游左上角为 `(0, 900)`、左下角为 `(0, -124)`；轮廓的所有端点、控制点及中线坐标统一转换为 `(x, 900-y)`。输出坐标为 1024×1024、原点左上、Y 轴向下；保留上游笔画顺序。

转换结果按汉字 Unicode 码位的小写十六进制命名，可跨书共享。每份 JSON 都保留来源及许可。这里的图形是楷书笔顺，不含甲骨文、金文或小篆。

生成入口为 `npx tsx scripts/hanzi/build-hanzi.ts chinese-g1up`；原始文件只缓存在被 Git 忽略的 `scripts/hanzi/.cache/`，不提交。不要把轮廓复制到字卡、Swift/TypeScript 源码或测试夹具；运行时从本目录加载，seed 中按相同层级打包到 `data/hanzi/strokes/`。

机器检查不等于人工规范核验。初稿的逐字笔画名称、折笔命名及与《通用规范汉字笔顺规范》的符合性仍需按生成报告复核，不宣称已经逐字对照纸质规范或课本。

「关于」页的来源展示由 RD-21 接入，本卡保留数据级归属信息。
