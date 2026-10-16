#!/usr/bin/env python3
"""Render static product posters from intact UI captures. No APIs or animation.

Requires Python 3 and Pillow; system fonts are used locally, not redistributed.
"""
from __future__ import annotations
import argparse
import functools
import hashlib
import json
import xml.etree.ElementTree as ET
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SHOTS = ROOT / "docs/screenshots/web"
POSTERS = ROOT / "docs/posters"
OUT = ROOT / "docs/showcase"
W, H = 2400, 1500
INK, MUTED = "#1d1d1f", "#6e6e73"


def find_font(candidates):
    for path in candidates:
        if Path(path).exists():
            return path
    raise SystemExit("Pass --cjk-font and --latin-font with installed font paths.")


@functools.lru_cache(maxsize=48)
def font(size, bold=False, latin=False):
    path = LATIN if latin else CJK
    index = 0 if latin or not bold or "Hiragino" not in path else 2
    return ImageFont.truetype(path, size=size, index=index)


def text(im, xy, value, size, bold=False, color=INK, anchor="lt", latin=False):
    draw = ImageDraw.Draw(im)
    face = font(size, bold, latin)
    bounds = draw.textbbox(xy, value, font=face, anchor=anchor)
    if not (0 <= bounds[0] < bounds[2] <= im.width and 0 <= bounds[1] < bounds[3] <= im.height):
        raise ValueError(f"Text leaves poster: {value!r} {bounds}")
    draw.text(xy, value, font=face, fill=color, anchor=anchor)


def centered(im, y, value, size, color=INK):
    text(im, (W // 2, y), value, size, color=color, anchor="mt")


def background():
    # The same quiet, warm-white surface as the README banner.
    im = Image.new("RGB", (W, H))
    draw = ImageDraw.Draw(im)
    a, b = (250, 251, 250), (242, 246, 243)
    for y in range(H):
        t = y / (H - 1)
        col = tuple(round(start + (end - start) * t) for start, end in zip(a, b))
        draw.line((0, y, W, y), fill=col)
    return im.convert("RGBA")


def display(im, name, x, y, width=None, height=None):
    # A fine white edge replaces the heavy simulated device bezel. The entire
    # source image is fitted proportionally; no UI is covered or reframed.
    with Image.open(SHOTS / name) as original:
        src = original.convert("RGB")
    if height is not None:
        width = round(src.width * height / src.height)
    elif width is not None:
        height = round(src.height * width / src.width)
    else:
        raise ValueError("A display width or height is required")
    inset, margin, radius = 6, 72, 24
    outer_w, outer_h = width + 2 * inset, height + 2 * inset
    if x < 48 or y < 48 or x + outer_w > W - 48 or y + outer_h > H - 48:
        raise ValueError(f"Image leaves poster safe area: {name}")
    layer = Image.new("RGBA", (outer_w + 2 * margin, outer_h + 2 * margin))
    mask = Image.new("L", layer.size)
    ImageDraw.Draw(mask).rounded_rectangle(
        (margin, margin + 18, margin + outer_w, margin + outer_h + 18),
        radius, fill=22,
    )
    shadow = Image.new("RGBA", layer.size, (33, 49, 38, 0))
    shadow.putalpha(mask.filter(ImageFilter.GaussianBlur(24)))
    layer.alpha_composite(shadow)
    ImageDraw.Draw(layer).rounded_rectangle(
        (margin, margin, margin + outer_w - 1, margin + outer_h - 1),
        radius, fill="#ffffff", outline="#e0e6e1", width=2,
    )
    screen = src.resize((width, height), Image.Resampling.LANCZOS).convert("RGBA")
    clip = Image.new("L", screen.size)
    ImageDraw.Draw(clip).rounded_rectangle(
        (0, 0, width - 1, height - 1), radius - inset, fill=255,
    )
    screen.putalpha(clip)
    layer.alpha_composite(screen, (margin + inset, margin + inset))
    im.alpha_composite(layer, (x - margin, y - margin))
    return outer_w, outer_h


def save(im, name):
    im.convert("RGB").save(POSTERS / name, optimize=True)


def heading(im, title, subtitle):
    centered(im, 160, title, 100)
    centered(im, 315, subtitle, 34, color=MUTED)


def hero():
    im = background()
    text(im, (180, 210), "聪聪学堂", 32, color=MUTED)
    text(im, (174, 445), "学习，", 124)
    text(im, (174, 615), "从好奇心开始。", 124)
    text(im, (180, 840), "互动练习 · 逐句听读 · 自主探索", 32, color=MUTED)
    text(im, (180, 1060), "小学全科 / 免费开源", 28, color=MUTED)
    display(im, "04-counting.jpg", 1240, 285, height=960)
    display(im, "05-feedback.jpg", 1780, 465, height=850)
    save(im, "hero.png")


def learning():
    im = background()
    heading(im, "每一步，都有小小的进步。", "选年级，动手数，再看懂为什么。")
    specs = [("01-onboarding.jpg", 540, "找到起点"),
             ("04-counting.jpg", 1200, "亲手探索"),
             ("05-feedback.jpg", 1860, "看懂为什么")]
    for name, center_x, caption in specs:
        height = 800
        with Image.open(SHOTS / name) as src:
            outer_w = round(src.width * height / src.height) + 12
        display(im, name, center_x - outer_w // 2, 470, height=height)
        text(im, (center_x, 1350), caption, 32, anchor="mt", color=MUTED)
    save(im, "learning.png")


def reading():
    im = background()
    heading(im, "让每一句，都读得懂。", "课本原页 · 逐句听读")
    display(im, "06-reading.jpg", 180, 490, width=1480)
    display(im, "06-reading-mobile.jpg", 1850, 440, height=860)
    save(im, "reading.png")


def explore():
    im = background()
    heading(im, "好奇心，不止于课堂。", "故事阅读 · 聪聪衣橱")
    display(im, "08-story-reader.jpg", 180, 510, width=960)
    display(im, "09-wardrobe.jpg", 1260, 510, width=960)
    text(im, (180, 1150), "读一个故事", 40)
    text(im, (1260, 1150), "换一种模样", 40)
    text(im, (180, 1235), "插画与逐句阅读", 28, color=MUTED)
    text(im, (1260, 1235), "用学习获得的宝石，给聪聪换装", 28, color=MUTED)
    save(im, "explore.png")


def write_manifest():
    files = sorted([ROOT / "docs/banner.svg", *POSTERS.glob("*.png"), *SHOTS.glob("*.jpg")])
    records = []
    for path in files:
        if path.suffix == ".svg":
            svg = ET.fromstring(path.read_text())
            pixels = [int(svg.attrib["width"]), int(svg.attrib["height"])]
        else:
            with Image.open(path) as image:
                pixels = [image.width, image.height]
        records.append({"path": str(path.relative_to(ROOT)), "bytes": path.stat().st_size,
                        "pixels": pixels, "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
    data = {"date": "2026-10-15", "artwork_updated": "2026-10-16", "format": "static product posters and intact browser screenshots",
            "branch": "codex/ux-quality-repairs", "screenshot_base_commit": "acde104e22321d4e0f84764fc62fd158a324a05f",
            "release_state": "unmerged; not deployed", "css_viewports": {"desktop": [1280,720], "mobile": [390,844]},
            "notes": ["Poster typography and framing are editorial; UI content is not altered.",
                      "Original capture pixels are listed individually; some exclude page edges.",
                      "Mobile images are browser simulations; iOS images remain separately labeled historical material."],
            "files": records}
    (OUT / "capture-manifest.json").write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def main():
    global CJK, LATIN
    parser = argparse.ArgumentParser()
    parser.add_argument("--cjk-font")
    parser.add_argument("--latin-font")
    args = parser.parse_args()
    CJK = args.cjk_font or find_font(["/System/Library/Fonts/Hiragino Sans GB.ttc", "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"])
    LATIN = args.latin_font or find_font(["/System/Library/Fonts/Avenir Next.ttc", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"])
    POSTERS.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)
    hero(); learning(); reading(); explore(); write_manifest()
    print("Created four static PNG posters and capture manifest.")


if __name__ == "__main__":
    main()
