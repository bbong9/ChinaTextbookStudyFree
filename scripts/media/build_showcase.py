#!/usr/bin/env python3
"""Compose a product film from unaltered browser captures; no generation APIs.

Requires Python 3, Pillow, NumPy and FFmpeg. Run from any directory.
System fonts are used locally, never redistributed. See docs/demo/README.md.
"""
from __future__ import annotations

import argparse
import functools
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parents[2]
SHOTS = ROOT / "docs/screenshots/web"
SOURCE = ROOT / "docs/demo/source"
OUT = ROOT / "docs/demo"
WORK = ROOT / "deploy-output/readme-media"
W, H, FPS, DURATION = 1920, 1080, 30, 38
INK = "#162b24"
GREEN = "#72b92e"
PAPER = "#f5f6f2"


def font_path(candidates: list[str]) -> str:
    for item in candidates:
        if Path(item).exists():
            return item
    raise SystemExit("Install a CJK font or pass --cjk-font / --latin-font.")


@functools.lru_cache(maxsize=64)
def font(size: int, latin: bool = False):
    return ImageFont.truetype(LATIN if latin else CJK, size=size)


def text(im, xy, words, size=30, fill=INK, latin=False, anchor=None, spacing=20):
    ImageDraw.Draw(im).multiline_text(xy, words, font=font(size, latin), fill=fill,
                                       spacing=spacing, anchor=anchor)


def label(im, xy, words, light=False):
    text(im, xy, words, 22, "#b1c9bb" if light else "#62766a", True)


def ease(t):
    t = max(0, min(1, t))
    return 1 - (1 - t) ** 3


@functools.lru_cache(maxsize=30)
def shot(name):
    p = SOURCE / name if (SOURCE / name).exists() else SHOTS / name
    return Image.open(p).convert("RGB")


@functools.lru_cache(maxsize=2)
def background(dark=False):
    # Original, deliberately quiet gradient. The application captures stay intact.
    y, x = np.mgrid[0:H, 0:W]
    glow = np.exp(-(((x - 1450) / 1050) ** 2 + ((y - 520) / 1000) ** 2))
    base = np.array([14, 23, 20] if dark else [248, 248, 244], dtype=float)
    delta = np.array([15, 25, 14] if dark else [-12, -5, -13], dtype=float)
    return Image.fromarray(np.uint8(np.clip(base + glow[:, :, None] * delta, 0, 255))).convert("RGBA")


@functools.lru_cache(maxsize=128)
def phone(name, height):
    src = shot(name)
    sh = height - 24
    sw = round(src.width * sh / src.height)
    layer = Image.new("RGBA", (sw + 72, height + 76))
    mask = Image.new("L", layer.size)
    ImageDraw.Draw(mask).rounded_rectangle((29, 20, sw + 53, height + 20), radius=42, fill=75)
    shadow = Image.new("RGBA", layer.size, (9, 30, 17, 0))
    shadow.putalpha(mask.filter(ImageFilter.GaussianBlur(18)))
    layer.alpha_composite(shadow)
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle((24, 6, sw + 48, height + 6), radius=39, fill="#18231e", outline="#4f5a53", width=2)
    screen = src.resize((sw, sh), Image.Resampling.LANCZOS).convert("RGBA")
    clip = Image.new("L", screen.size)
    ImageDraw.Draw(clip).rounded_rectangle((0, 0, sw - 1, sh - 1), radius=29, fill=255)
    screen.putalpha(clip)
    layer.alpha_composite(screen, (36, 18))
    # Generic display frame; no Apple hardware, camera cutout or false status bar.
    return layer


@functools.lru_cache(maxsize=128)
def window(name, width):
    src = shot(name)
    ih = round(src.height * width / src.width)
    layer = Image.new("RGBA", (width + 100, ih + 120))
    mask = Image.new("L", layer.size)
    ImageDraw.Draw(mask).rounded_rectangle((36, 22, width + 64, ih + 79), radius=24, fill=55)
    shade = Image.new("RGBA", layer.size, (8, 31, 15, 0))
    shade.putalpha(mask.filter(ImageFilter.GaussianBlur(22)))
    layer.alpha_composite(shade)
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle((30, 10, width + 70, ih + 68), radius=20, fill="#e6e9e3", outline="#cbd2c8", width=1)
    draw.rounded_rectangle((40, 45, width + 60, ih + 58), radius=8, fill="white")
    for i, col in enumerate(("#d2d9cd", "#d2d9cd", "#d2d9cd")):
        draw.ellipse((48 + i * 18, 24, 55 + i * 18, 31), fill=col)
    layer.alpha_composite(src.resize((width, ih), Image.Resampling.LANCZOS).convert("RGBA"), (50, 48))
    return layer


def paste(im, layer, xy):
    im.alpha_composite(layer, tuple(round(v) for v in xy))


def footer(im, dark=False):
    text(im, (100, 1028), "CHINASTUDYFREE", 19, "#a3bbab" if dark else "#65776b", True)
    text(im, (1820, 1028), "Web 修复分支预览 · 2026.10", 18,
         "#a3bbab" if dark else "#65776b", anchor="ra")


def scene(index, local):
    dark = index in (0, 4, 6)
    im = background(dark).copy()
    reveal = round((1 - ease(local / 1.2)) * 40)
    if index == 0:
        label(im, (144, 160 + reveal), "CONGCONG / A LITTLE CURIOSITY", True)
        text(im, (137, 278 + reveal), "让好奇心，\n成为第一步。", 126, "#f2f6ed", spacing=20)
        text(im, (145, 653 + reveal), "聪聪学堂", 46, "#a7d966")
        text(im, (147, 742 + reveal), "小学全科。免费，开源。", 32, "#b1c9bb")
        paste(im, phone("04-counting.jpg", 810), (1260, 110 + reveal))
    elif index == 1:
        label(im, (145, 226), "01 / LEARN BY DOING")
        text(im, (138, 330 + reveal), "点一下，\n理解多一点。", 105, spacing=18)
        text(im, (147, 630 + reveal), "从三个苹果开始。", 32, "#66786c")
        n = min(3, int(max(0, local - 1.2) / .85))
        names = ["04-counting-start.jpg", "counting-1.jpg", "counting-2.jpg", "04-counting.jpg"]
        paste(im, phone(names[n], 870), (1210, 60 + reveal))
        d = ImageDraw.Draw(im)
        for i in range(3):
            x = 149 + i * 68
            d.rounded_rectangle((x, 734, x + 42, 740), 3, fill=GREEN if i < n else "#d7dfd1")
    elif index == 2:
        label(im, (990, 245), "02 / A SMALL STEP FORWARD")
        text(im, (985, 340 + reveal), "每一次尝试，\n都有回应。", 94, spacing=20)
        text(im, (993, 625 + reveal), "选择、检查，再看懂为什么。", 31, "#66786c")
        name = "practice.jpg" if local < 1.3 else "answer-selected.jpg" if local < 2.3 else "05-feedback.jpg"
        paste(im, phone(name, 900), (270, 44 + reveal))
    elif index == 3:
        label(im, (W / 2 - 140, 92), "03 / READ & LISTEN")
        text(im, (W / 2, 156 + reveal), "把课文，读进心里。", 76, anchor="ma")
        name = "06-reading.jpg" if local < 1.9 else "reading-playing.jpg"
        paste(im, window(name, 1240), (290, 250 + reveal - 5 * min(local, 4)))
    elif index == 4:
        label(im, (140, 100), "04 / BEYOND THE TEXTBOOK", True)
        text(im, (135, 165 + reveal), "课本之外，还有一个世界。", 70, "#f2f6ed")
        paste(im, window("08-story-reader.jpg", 1240), (290, 250 + reveal - 4 * min(local, 4)))
    elif index == 5:
        label(im, (W / 2 - 130, 87), "05 / MAKE IT YOURS")
        text(im, (W / 2, 153 + reveal), "努力，也有自己的模样。", 76, anchor="ma")
        paste(im, window("09-wardrobe.jpg", 1240), (290, 250 + reveal - 4 * min(local, 4)))
    else:
        label(im, (144, 185), "CHINASTUDYFREE", True)
        text(im, (137, 300 + reveal), "每个孩子，\n都值得好的开始。", 96, "#f2f6ed", spacing=24)
        text(im, (145, 598 + reveal), "免费 · 开源 · 公益", 36, "#a7d966")
        text(im, (145, 704 + reveal), "和聪聪一起，开始今天的小探索。", 28, "#b1c9bb")
        paste(im, phone("02-subjects-mobile.jpg", 710), (1160, 165 + reveal))
        paste(im, phone("06-reading-mobile.jpg", 610), (1500, 280 + reveal))
    footer(im, dark)
    return im.convert("RGB")


STARTS = (0, 4.5, 10.5, 16, 21.5, 27, 32.5)


def frame(t):
    idx = max(i for i, start in enumerate(STARTS) if start <= t)
    local = t - STARTS[idx]
    im = scene(idx, local)
    if idx and local < .55:
        previous = scene(idx - 1, STARTS[idx] - STARTS[idx - 1] - .02)
        im = Image.blend(previous, im, ease(local / .55))
    if t < .6:
        im = Image.blend(Image.new("RGB", (W, H), "#0e1714"), im, ease(t / .6))
    if t > DURATION - .8:
        im = Image.blend(im, Image.new("RGB", (W, H), "#0e1714"), ease((t - DURATION + .8) / .8))
    return im


def hero():
    im = background().copy()
    label(im, (140, 140), "CONGCONG / CHINASTUDYFREE")
    text(im, (133, 270), "学习，\n从好奇心开始。", 108, spacing=24)
    text(im, (143, 608), "小学全科 · 免费开源", 35, "#637867")
    text(im, (145, 690), "互动练习   /   逐句听读   /   和聪聪一起成长", 25, "#637867")
    paste(im, phone("04-counting.jpg", 850), (1040, 90))
    paste(im, phone("05-feedback.jpg", 730), (1480, 235))
    footer(im)
    im.convert("RGB").save(SHOTS / "hero.jpg", quality=94, subsampling=0)
    poster = frame(7).convert("RGBA")
    # Editorial play mark, outside the application display.
    d = ImageDraw.Draw(poster)
    d.ellipse((145, 815, 219, 889), fill=INK)
    d.polygon(((176, 834), (176, 869), (201, 851)), fill="white")
    text(poster, (245, 832), "观看产品短片 · 38 秒", 28)
    poster.convert("RGB").save(OUT / "poster.jpg", quality=94, subsampling=0)


def soundtrack(path):
    """Original quiet pentatonic pad and bell notes. No sampled/licensed music."""
    sr = 48000
    timeline = np.arange(DURATION * sr, dtype=np.float64) / sr
    a = np.zeros_like(timeline)
    for start, chord in [(0, [130.81, 196., 261.63, 329.63]), (10.5, [146.83, 220., 293.66, 392.]),
                         (21.5, [164.81, 246.94, 329.63, 392.]), (32.5, [130.81, 196., 261.63, 392.])]:
        u = timeline - start
        envelope = (1 - np.exp(-np.maximum(u, 0) / 2.5)) * np.exp(-np.maximum(u, 0) / 13) * (u >= 0)
        for frequency in chord:
            a += .017 * np.sin(2 * np.pi * frequency * timeline) * envelope
    for start, frequency in [(5.9, 523.25), (6.75, 659.25), (7.6, 783.99), (13, 1046.5),
                             (17, 659.25), (22, 783.99), (28, 587.33), (33.2, 523.25)]:
        u = np.maximum(timeline - start, 0)
        env = (1 - np.exp(-u * 100)) * np.exp(-u / 1.3) * (timeline >= start)
        a += .032 * (np.sin(2 * np.pi * frequency * u) + .2 * np.sin(2 * np.pi * frequency * 2 * u)) * env
    a *= 3.2 * np.clip(timeline / 1.2, 0, 1) * np.clip((DURATION - timeline) / 1.5, 0, 1)
    stereo = np.stack((a, np.roll(a, 288)), axis=1)
    with wave.open(str(path), "wb") as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(sr)
        f.writeframes(np.int16(np.clip(stereo, -1, 1) * 32767).tobytes())


def write_manifest():
    probe = json.loads(subprocess.check_output(["ffprobe", "-v", "error", "-show_streams", "-show_format", "-of", "json", str(OUT / "congcong-demo.mp4")]))
    video = next(s for s in probe["streams"] if s["codec_type"] == "video")
    audio = next(s for s in probe["streams"] if s["codec_type"] == "audio")
    assert (video["width"], video["height"], video["avg_frame_rate"], video["pix_fmt"]) == (W, H, "30/1", "yuv420p")
    assert abs(float(probe["format"]["duration"]) - DURATION) < .05
    assert video["codec_name"] == "h264" and audio["codec_name"] == "aac"
    files = sorted([*SHOTS.glob("*.jpg"), *SOURCE.glob("*.jpg"), OUT / "congcong-demo.mp4", OUT / "poster.jpg", OUT / "preview.gif", OUT / "congcong-demo.zh-CN.vtt"])
    records = []
    for path in files:
        item = {"path": str(path.relative_to(ROOT)), "bytes": path.stat().st_size, "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
        if path.suffix in (".jpg", ".gif"):
            with Image.open(path) as image:
                item["pixels"] = [image.width, image.height]
        records.append(item)
    data = {"capture_date": "2026-10-15", "application_base_commit": "acde104e22321d4e0f84764fc62fd158a324a05f",
            "branch": "codex/ux-quality-repairs", "source": "Local production export; new demo records; real UI captures, editorial composition, not a continuous screen recording",
            "css_viewports": {"desktop": [1280, 720], "mobile": [390, 844]},
            "pixel_note": "Some browser captures exclude page edges; exact image dimensions are listed below. No UI content is altered.",
            "release_state": "unmerged; not deployed", "ios": "historical images retained separately; not recaptured",
            "media": {"seconds": DURATION, "fps": FPS, "width": W, "height": H, "video_codec": "h264", "audio_codec": "aac", "score": "original local synthesis, no samples or paid generation APIs"},
            "files": records}
    (OUT / "capture-manifest.json").write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def main():
    global CJK, LATIN
    ap = argparse.ArgumentParser()
    ap.add_argument("--stills-only", action="store_true")
    ap.add_argument("--manifest-only", action="store_true")
    ap.add_argument("--cjk-font")
    ap.add_argument("--latin-font")
    args = ap.parse_args()
    if args.manifest_only:
        write_manifest()
        return
    CJK = args.cjk_font or font_path(["/System/Library/Fonts/Hiragino Sans GB.ttc", "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"])
    LATIN = args.latin_font or font_path(["/System/Library/Fonts/Avenir Next.ttc", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"])
    OUT.mkdir(parents=True, exist_ok=True)
    WORK.mkdir(parents=True, exist_ok=True)
    hero()
    for idx, start in enumerate(STARTS):
        frame(start + 2.8).save(WORK / f"scene-{idx}.jpg", quality=90)
    if args.stills_only:
        return
    if not shutil.which("ffmpeg"):
        raise SystemExit("FFmpeg is required.")
    audio = WORK / "original-score.wav"
    soundtrack(audio)
    cmd = ["ffmpeg", "-y", "-loglevel", "warning", "-f", "rawvideo", "-vcodec", "rawvideo", "-pix_fmt", "rgb24",
           "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-", "-i", str(audio), "-c:v", "libx264", "-preset", "medium",
           "-crf", "19", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "160k", "-movflags", "+faststart",
           "-metadata", "title=聪聪学堂 · 从好奇心开始", "-metadata", "comment=Real local Web captures; edited product film, not continuous screen recording; original synthesized score.",
           str(OUT / "congcong-demo.mp4")]
    process = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    try:
        for i in range(FPS * DURATION):
            process.stdin.write(frame(i / FPS).tobytes())
            if i % (FPS * 5) == 0:
                print(f"Rendered {i // FPS}/{DURATION}s", flush=True)
    finally:
        process.stdin.close()
    if process.wait():
        raise SystemExit("Video encoding failed")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "warning", "-i", str(OUT / "congcong-demo.mp4"), "-ss", "4.5", "-t", "9",
                    "-filter_complex", "fps=8,scale=640:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=96[p];[b][p]paletteuse=dither=bayer:bayer_scale=4",
                    "-loop", "0", str(OUT / "preview.gif")], check=True)
    write_manifest()
    print("Created hero, poster, 1080p film and lightweight preview.", flush=True)


if __name__ == "__main__":
    main()
