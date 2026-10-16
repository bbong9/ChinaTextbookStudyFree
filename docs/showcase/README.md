# 聪聪学堂 · 品牌视觉

以项目熊猫图标与学习截图为参考，用内置 imagegen 生成统一的立体品牌视觉：浅色背景、柔和光线、中文排版和充足留白。横幅保留可编辑 SVG；四张海报均为生成器的原生 PNG 输出，没有放大或裁切。

| 素材 | 尺寸 | 内容 |
| --- | --- | --- |
| [品牌横幅](../banner.svg) | 1600×500 · SVG | 聪聪学堂与熊猫聪聪 |
| [品牌主视觉](../visuals/hero.png) | 1586×992 · PNG | 学习，从好奇心开始 |
| [学习](../visuals/learning.png) | 1586×992 · PNG | 每一步，都有小小的进步 |
| [听读](../visuals/reading.png) | 1586×992 · PNG | 让每一句，都读得懂 |
| [探索](../visuals/explore.png) | 1586×992 · PNG | 好奇心，不止于课堂 |

## 查看

[静态画廊](../web-showcase.html) 可在本地打开并放大图片；也可在仓库根目录运行：

```sh
python3 scripts/media/preview_showcase.py
```

访问 `http://127.0.0.1:3037/web-showcase.html`。支持键盘打开图片、Esc关闭并返回原焦点。

## 生成与来源

2026-10-16 使用 Codex 内置 imagegen 生成。完整提示词、精修步骤及各图的参考来源见 [生成记录](imagegen-prompts.md)。新的变体应以 `hero.png` 作为风格与熊猫形象参考，并保留最终输出文件；旧的截图拼贴生成脚本已移除，不会覆盖这些图片。

这些是品牌概念图，不是产品界面截图。原始 Web 截图保留在 [screenshots/web](../screenshots/web/)，采集于2026-10-15的 `codex/ux-quality-repairs` 本地生产构建。手机截图为浏览器视口模拟；iOS历史截图单独标记。相关UX修复状态见 [PR #13](https://github.com/wuwangzhang1216/ChinaTextbookStudyFree/pull/13)。

横幅直接编辑 `docs/banner.svg`，复用项目现有熊猫图标。全部素材的像素尺寸、长度与SHA256见 [素材清单](capture-manifest.json)。
