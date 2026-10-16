# 聪聪学堂 · 静态产品展示

采用简洁字重、黑白灰、大留白和轻阴影，只制作静态海报与真实截图。横幅采用可缩放SVG，海报为高分辨率、无损PNG，可直接用于README、介绍页或演示文档。无视频、动图、配乐或播放组件。

| 海报 | 尺寸 | 内容 |
| --- | --- | --- |
| [README 品牌横幅](../banner.svg) | 1600×500 · SVG | 聪聪学堂与熊猫聪聪 |
| [品牌主视觉](../posters/hero.png) | 2400×1500 | 学习，从好奇心开始 |
| [学习流程](../posters/learning.png) | 2400×1600 | 选择年级、互动点数与答题反馈 |
| [课文听读](../posters/reading.png) | 2400×1500 | 课本原页与手机逐句听读 |
| [故事与衣橱](../posters/explore.png) | 2400×1500 | 课外阅读与聪聪装扮 |

横幅复用项目 App 图标中的熊猫几何图形，文字与布局直接编辑 `docs/banner.svg`，不依赖外部图片或生成API。

## 浏览与重制

直接打开 [静态画廊](../web-showcase.html) 可查看和放大图片；或在仓库根目录运行：

```sh
python3 scripts/media/preview_showcase.py
```

访问 `http://127.0.0.1:3037/web-showcase.html`。画廊没有自动播放或背景动效，支持键盘打开图片、Esc关闭并返回原焦点。

海报通过代码排版，不调用生成API；原始界面截图位于 `../screenshots/web/`。重新生成只需要Python 3与Pillow：

```sh
python3 scripts/media/build_showcase.py
```

macOS默认使用本机Hiragino Sans GB与Avenir Next；Linux可安装Noto Sans CJK与DejaVu Sans，或用`--cjk-font`和`--latin-font`指定字体路径。系统字体不随仓库分发。海报和原始截图的像素尺寸及SHA256见 [素材清单](capture-manifest.json)。

## 画面边界

2026-10-15采集，来自`codex/ux-quality-repairs`本地生产构建。截图保留实际文字、布局、分数和学习状态，不虚构成绩。海报中的通用显示边框、标题和背景属于展示排版，未使用Apple商标或设备外形。

手机画面为浏览器CSS视口模拟，不是真机拍摄；截图服务可能裁去页面边缘，精确像素以素材清单为准。iOS图片仍单独标记为历史素材。画面中的UX修复来自 [PR #13](https://github.com/wuwangzhang1216/ChinaTextbookStudyFree/pull/13)，尚未合并或上线，不能将海报视为线上、教师、儿童或真机验收证据。
