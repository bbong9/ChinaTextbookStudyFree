"""从仓库根目录之外也可运行：核对全部 SVG 渐变的色标、透明度和几何参数。"""

import ast
from pathlib import Path
import re

root = Path(__file__).resolve().parents[4]
art = (root / "docs/redesign-v2/design/art.js").read_text()
swift = (root / "apps/mobile/ChinaTextbookStudy/Clay/ClayTokens.swift").read_text()
names = dict(re.findall(r'case (\w+) = "([gp]-[^"]+)"', swift))
geometry = swift.split("var geometry: Geometry", 1)[1].split("var stops:", 1)[0]
stops = swift.split("var stops:", 1)[1].split("var view:", 1)[0]
swift_stops = dict(re.findall(r"case \.(\w+): return \[(.*)\]", stops))
checked = []

for kind, name, raw_args in re.findall(r"\$\{(lg|rg)\('([gp]-[^']+)', (.+)\)\}", art):
    args = ast.literal_eval("[" + raw_args + "]")
    case = next(key for key, value in names.items() if value == name)
    expected = [(color.upper(), offset, opacity[0] if opacity else 1)
                for offset, color, *opacity in args[0]]
    actual = [("#" + color, float(offset), float(opacity) if opacity else 1)
              for color, opacity, offset in re.findall(
                  r"\.init\(color: ClayColor\.hex\(0x([0-9A-F]+)\)(?:\.opacity\(([\d.]+)\))?, location: ([\d.]+)\)",
                  swift_stops[case])]
    assert actual == expected, (name, "色标或透明度不一致", expected, actual)
    if kind == "rg":
        expected_geometry = args[1:] or [0.38, 0.3, 0.78]
        match = re.search(r"case \." + case + r": return \.radial\(center: UnitPoint\(x: ([\d.]+), y: ([\d.]+)\), radius: ([\d.]+)\)", geometry)
    else:
        expected_geometry = args[1:] or [0, 1]
        match = re.search(r"case \." + case + r": return \.linear\(end: UnitPoint\(x: ([\d.]+), y: ([\d.]+)\)\)", geometry)
    assert match and list(map(float, match.groups())) == expected_geometry, (name, "几何参数不一致")
    checked.append(name)
    print(f"通过 {name}: {expected}; {kind} {expected_geometry}")

assert len(checked) == 43 and set(checked) == set(names.values())
print("全部 43 个 g-* / p-* 渐变与 art.js 一致；0 项差异。")
