"""Type glyphs for SquadCD: white 64x64 TGA masks, tinted in game with the type's glyph colour.

The shapes are the PartySignal app's type glyphs (src/PartySignal.App/TypeStyle.cs), drawn on a 10x10 grid.
Potion and Purge have no glyph there and get their own in the same style.
Run: python tools/type_glyphs.py
"""
import math
import re
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

SIZE, SUPER, PAD = 64, 8, 6
OUT = Path(__file__).resolve().parent.parent / "Media" / "Types"

SHIELD = "M5 0L9.6 1.7V5C9.6 7.6 7.6 9.3 5 10C2.4 9.3 0.4 7.6 0.4 5V1.7Z"
STAR4 = "M5 0L6.3 3.7L10 5L6.3 6.3L5 10L3.7 6.3L0 5L3.7 3.7Z"
GLYPHS = {
    "Personal": SHIELD,
    "Burst": "M5 0L10 9.5H0Z",
    "Racial": "M2.5 0.7H7.5L10 5L7.5 9.3H2.5L0 5Z",
    "Potion": "M3.6 0H6.4V3.2a3.6 3.6 0 1 1 -2.8 0Z",
    "External": "M5 9.6L1.1 5.6C-0.5 4 0.1 1.1 2.5 0.9C3.7 0.8 4.5 1.5 5 2.4C5.5 1.5 6.3 0.8 7.5 0.9C9.9 1.1 10.5 4 8.9 5.6Z",
    "Kick": "M6.2 0L1.2 5.8H4.6L3.4 10L8.8 3.8H5.3Z",
    "Control": STAR4,
    "Stun": STAR4,
    "CC": "M0 5a5 5 0 1 0 10 0a5 5 0 1 0 -10 0Z M1.7 5a3.3 3.3 0 1 0 6.6 0a3.3 3.3 0 1 0 -6.6 0Z M3.3 5a1.7 1.7 0 1 0 3.4 0a1.7 1.7 0 1 0 -3.4 0Z",
    "Group": "M0.2 7.4a2.3 2.3 0 1 0 4.6 0a2.3 2.3 0 1 0 -4.6 0Z M5.2 7.4a2.3 2.3 0 1 0 4.6 0a2.3 2.3 0 1 0 -4.6 0Z M2.7 2.6a2.3 2.3 0 1 0 4.6 0a2.3 2.3 0 1 0 -4.6 0Z",
    "Dispel": "M3.7 0H6.3V3.7H10V6.3H6.3V10H3.7V6.3H0V3.7H3.7Z",
    "Purge": "M1.8 0L5 3.2L8.2 0L10 1.8L6.8 5L10 8.2L8.2 10L5 6.8L1.8 10L0 8.2L3.2 5L0 1.8Z",
    "Movement": "M0 1L10 5L0 9L2.6 5Z",
}


def arc(p0, rx, ry, large, sweep, p1, steps=48):
    (x1, y1), (x2, y2) = p0, p1
    dx, dy = (x1 - x2) / 2, (y1 - y2) / 2
    lam = (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry)
    if lam > 1:
        rx, ry = rx * math.sqrt(lam), ry * math.sqrt(lam)
    num = rx * rx * ry * ry - rx * rx * dy * dy - ry * ry * dx * dx
    den = rx * rx * dy * dy + ry * ry * dx * dx
    k = math.sqrt(max(0.0, num / den)) * (-1 if large == sweep else 1)
    cx = k * rx * dy / ry + (x1 + x2) / 2
    cy = -k * ry * dx / rx + (y1 + y2) / 2
    a1 = math.atan2((y1 - cy) / ry, (x1 - cx) / rx)
    a2 = math.atan2((y2 - cy) / ry, (x2 - cx) / rx)
    delta = a2 - a1
    if sweep and delta < 0:
        delta += 2 * math.pi
    elif not sweep and delta > 0:
        delta -= 2 * math.pi
    return [(cx + rx * math.cos(a1 + delta * i / steps), cy + ry * math.sin(a1 + delta * i / steps)) for i in range(1, steps + 1)]


def cubic(p0, c1, c2, p1, steps=24):
    out = []
    for i in range(1, steps + 1):
        t = i / steps
        u = 1 - t
        out.append((
            u ** 3 * p0[0] + 3 * u * u * t * c1[0] + 3 * u * t * t * c2[0] + t ** 3 * p1[0],
            u ** 3 * p0[1] + 3 * u * u * t * c1[1] + 3 * u * t * t * c2[1] + t ** 3 * p1[1],
        ))
    return out


def subpaths(path):
    tokens = re.findall(r"[A-Za-z]|-?\d*\.?\d+", path)
    shapes, points, pos, start, cmd, i = [], [], (0.0, 0.0), (0.0, 0.0), None, 0

    def num():
        nonlocal i
        i += 1
        return float(tokens[i - 1])

    while i < len(tokens):
        if tokens[i].isalpha():
            cmd = tokens[i]
            i += 1
            if cmd in "Zz":
                if points:
                    shapes.append(points)
                points, pos = [], start
                continue
        rel = cmd.islower()
        base = pos if rel else (0.0, 0.0)
        c = cmd.upper()
        if c == "M":
            if points:
                shapes.append(points)
            pos = (base[0] + num(), base[1] + num())
            start, points = pos, [pos]
            cmd = "l" if rel else "L"
        elif c == "L":
            pos = (base[0] + num(), base[1] + num())
            points.append(pos)
        elif c == "H":
            pos = ((pos[0] if rel else 0) + num(), pos[1])
            points.append(pos)
        elif c == "V":
            pos = (pos[0], (pos[1] if rel else 0) + num())
            points.append(pos)
        elif c == "C":
            c1 = (base[0] + num(), base[1] + num())
            c2 = (base[0] + num(), base[1] + num())
            end = (base[0] + num(), base[1] + num())
            points += cubic(pos, c1, c2, end)
            pos = end
        elif c == "A":
            rx, ry, _, large, sweep = num(), num(), num(), num(), num()
            end = (base[0] + num(), base[1] + num())
            points += arc(pos, rx, ry, bool(large), bool(sweep), end)
            pos = end
        else:
            raise ValueError("unsupported command " + cmd)
    if points:
        shapes.append(points)
    return shapes


def render(path):
    big = SIZE * SUPER
    scale = (SIZE - 2 * PAD) * SUPER / 10
    off = PAD * SUPER
    mask = Image.new("L", (big, big), 0)
    for shape in subpaths(path):
        layer = Image.new("L", (big, big), 0)
        ImageDraw.Draw(layer).polygon([(off + x * scale, off + y * scale) for x, y in shape], fill=255)
        mask = ImageChops.logical_xor(mask.convert("1"), layer.convert("1")).convert("L")
    alpha = mask.resize((SIZE, SIZE), Image.LANCZOS)
    img = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 0))
    img.putalpha(alpha)
    return img


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, path in GLYPHS.items():
        render(path).save(OUT / (name + ".tga"))
    print("wrote", len(GLYPHS), "glyphs to", OUT)


if __name__ == "__main__":
    main()
