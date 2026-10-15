#!/usr/bin/env python3
"""Local-only docs preview with byte ranges for native MP4 seeking."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import argparse
import re


class MediaHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Accept-Ranges", "bytes")
        super().end_headers()

    def send_head(self):
        self.remaining = None
        value = self.headers.get("Range")
        if not value:
            return super().send_head()
        path = Path(self.translate_path(self.path))
        if not path.is_file():
            return super().send_head()
        size = path.stat().st_size
        match = re.fullmatch(r"bytes=(\d*)-(\d*)", value)
        try:
            if not match or not any(match.groups()):
                raise ValueError("Unsupported range")
            first, last = match.groups()
            if first:
                start = int(first)
                end = min(int(last), size - 1) if last else size - 1
            else:
                suffix = int(last)
                if suffix <= 0:
                    raise ValueError("Empty suffix")
                start, end = max(0, size - suffix), size - 1
            if start > end or start >= size:
                raise ValueError("Unsatisfiable range")
        except ValueError:
            self.send_response(416)
            self.send_header("Content-Range", f"bytes */{size}")
            self.send_header("Content-Length", "0")
            self.end_headers()
            return None
        f = path.open("rb")
        f.seek(start)
        self.remaining = end - start + 1
        self.send_response(206)
        self.send_header("Content-Type", self.guess_type(str(path)))
        self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
        self.send_header("Content-Length", str(self.remaining))
        self.end_headers()
        return f

    def copyfile(self, source, outputfile):
        if self.remaining is None:
            return super().copyfile(source, outputfile)
        remaining = self.remaining
        while remaining:
            block = source.read(min(64 * 1024, remaining))
            if not block:
                break
            outputfile.write(block)
            remaining -= len(block)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=3037)
    args = parser.parse_args()
    docs = Path(__file__).resolve().parents[2] / "docs"
    server = ThreadingHTTPServer(("127.0.0.1", args.port), partial(MediaHandler, directory=str(docs)))
    print(f"Preview: http://127.0.0.1:{args.port}/web-showcase.html", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        server.server_close()
