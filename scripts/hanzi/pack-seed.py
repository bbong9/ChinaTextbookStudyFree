#!/usr/bin/env python3
"""把根目录 content 加入已有 seed；课程、录音均沿用原包，原子替换。"""
from __future__ import annotations

import os
from pathlib import Path
import sys
import tempfile
import zipfile


def pack(root: Path) -> None:
    content = root / "content"
    seed = root / "apps/mobile/ChinaTextbookStudy/Resources/seed-data.zip"
    required = ["hanzi/chinese-g1up/index.json", "hanzi/strokes/LICENSE",
                "hanzi/strokes/README.md", "hanzi/UNICODE-LICENSE"]
    for rel in required:
        if not (content / rel).is_file():
            raise ValueError(f"缺少内容或许可文件：{rel}，先运行 build-hanzi.ts")
    if not seed.is_file():
        raise ValueError("没有基础 seed 包，请先运行完整 build-seed-zip.sh")
    additions = {"data/" + p.relative_to(content).as_posix(): p for p in sorted(content.rglob("*"))
                 if p.is_file() and not p.name.startswith(".")}
    before = seed.stat().st_size
    fd, temporary = tempfile.mkstemp(prefix="rd12-seed-", suffix=".zip", dir=seed.parent)
    os.close(fd)
    try:
        with zipfile.ZipFile(seed) as source, zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_DEFLATED,
                                                           compresslevel=9) as dest:
            for item in source.infolist():
                # 删除旧汉字和拼音产物，避免内容缩减后 seed 留下已经移除的条目。
                if item.filename.startswith(("data/hanzi/", "data/story-pinyin/")) or item.filename in additions:
                    continue
                dest.writestr(item, source.read(item))
            for name, path in additions.items():
                item = zipfile.ZipInfo(name, date_time=(2026, 10, 20, 0, 0, 0))
                item.compress_type = zipfile.ZIP_DEFLATED
                item.external_attr = 0o100644 << 16
                dest.writestr(item, path.read_bytes(), compresslevel=9)
        os.replace(temporary, seed)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    print(f"seed 内容更新：{len(additions)} 个文件；{before} → {seed.stat().st_size} 字节；"
          f"增量 {seed.stat().st_size - before} 字节（没有新增录音）。")


if __name__ == "__main__":
    try:
        pack(Path(sys.argv[1]).resolve())
    except (ValueError, OSError, zipfile.BadZipFile) as error:
        sys.exit(f"seed 打包失败：{error}")
