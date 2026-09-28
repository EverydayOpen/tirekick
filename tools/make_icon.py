"""Render the Tirekick app icon and write App/Assets.xcassets/AppIcon.appiconset.

Stdlib only (no Pillow). Shapes are signed distance functions, so every edge gets exact analytic antialiasing at
1024 px; smaller sizes are box-filtered down from the 1024 master in premultiplied alpha.

Layout follows the macOS (Big Sur and later) icon grid: 1024 canvas, 824 px body with continuous-looking corners,
soft drop shadow. Body: dark rubber with a faint directional tire tread. Glyph: a white laptop whose screen shows a
green check, the one shape that still reads at 16 px.

Run from the repo root (about a minute):  python tools/make_icon.py
"""
import json
import math
import os
import struct
import zlib
from array import array

N = 1024
OUT = os.path.join(os.path.dirname(__file__), "..", "App", "Assets.xcassets", "AppIcon.appiconset")

# Body: 824 px square centred on the canvas. A p=3 superellipse corner with a larger radius approximates Apple's
# continuous corner (curvature ramps in instead of jumping like a circle).
HALF, CORNER, P = 412.0, 278.0, 3.0
TOP, BOTTOM = (0.25, 0.27, 0.31), (0.07, 0.08, 0.10)          # charcoal -> near black
# Tread: rows of chevrons pointing up, like a directional tyre, faint enough to vanish at small sizes.
TREAD_PERIOD, TREAD_ROW, TREAD_SLOPE, TREAD_W, TREAD_A = 128.0, 112.0, 0.6, 18.0, 0.08

# Laptop (canvas coordinates, y down): lid, screen inset, base with a thumb notch, and the check on the screen.
LID = (512.0, 452.0, 270.0, 178.0, 34.0)                       # cx, cy, half width, half height, corner radius
SCREEN = (512.0, 452.0, 242.0, 150.0, 12.0)
BASE = (512.0, 668.0, 332.0, 24.0, 24.0)
NOTCH = (512.0, 644.0, 62.0, 13.0, 13.0)
CHECK = [(410.0, 456.0), (482.0, 526.0), (618.0, 382.0)]
CHECK_W = 33.0
GREEN_TOP, GREEN_BOTTOM = (0.22, 0.84, 0.43), (0.10, 0.63, 0.31)


def cov(d):
    """Pixel coverage from a signed distance in pixels (negative = inside)."""
    return 0.0 if d >= 0.5 else 1.0 if d <= -0.5 else 0.5 - d


def seg(px, py, ax, ay, bx, by):
    """Distance from (px, py) to segment a-b."""
    dx, dy = bx - ax, by - ay
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - ax - t * dx, py - ay - t * dy)


def rrect(x, y, cx, cy, hw, hh, r):
    """Signed distance to a rounded rectangle."""
    qx, qy = abs(x - cx) - hw + r, abs(y - cy) - hh + r
    return math.hypot(max(qx, 0.0), max(qy, 0.0)) + min(max(qx, qy), 0.0) - r


def body_sdf(x, y):
    qx, qy = abs(x - 512.0) - (HALF - CORNER), abs(y - 512.0) - (HALF - CORNER)
    if qx > 0 and qy > 0:
        return (qx ** P + qy ** P) ** (1 / P) - CORNER
    return max(qx, qy) - CORNER


def tread_sdf(x, y):
    u = abs(((x - 512.0) % TREAD_PERIOD) - TREAD_PERIOD / 2)   # 0 at a chevron's tip, half a period at its ends
    v = (y - u * TREAD_SLOPE) % TREAD_ROW - TREAD_ROW / 2
    # max(): each chevron's arms stop short of its neighbours', so rows read as tread blocks, not a zigzag.
    return max(abs(v) / math.sqrt(1 + TREAD_SLOPE ** 2) - TREAD_W, u - 0.36 * TREAD_PERIOD)


def laptop(x, y):
    """Signed distances for: whole laptop (for the shadow), lid, screen, base, check."""
    lid, base = rrect(x, y, *LID), max(rrect(x, y, *BASE), -rrect(x, y, *NOTCH))
    check = min(seg(x, y, *CHECK[0], *CHECK[1]), seg(x, y, *CHECK[1], *CHECK[2])) - CHECK_W
    return min(lid, base), lid, rrect(x, y, *SCREEN), base, check


def over(px, i, r, g, b, a):
    """Composite straight-alpha colour (r, g, b, a) over premultiplied pixel i."""
    k = 1.0 - a
    px[i] = r * a + px[i] * k
    px[i + 1] = g * a + px[i + 1] * k
    px[i + 2] = b * a + px[i + 2] * k
    px[i + 3] = a + px[i + 3] * k


def mix(a, b, t):
    return [a[c] + (b[c] - a[c]) * t for c in range(3)]


def render():
    px = array("f", bytes(N * N * 16))
    union = array("f", [1e9]) * (N * N)        # laptop distance per pixel, reused for its shadow
    shadow_k = 1 / (14.0 * math.sqrt(2))       # body shadow: sigma 14 px, 10 px down, 32 %
    gshadow_k = 1 / (12.0 * math.sqrt(2))      # laptop shadow: sigma 12 px, 12 px down, 45 %
    for yi in range(N):
        y = yi + 0.5
        base = mix(TOP, BOTTOM, min(1.0, max(0.0, (y - 100) / 824)))
        for xi in range(N):
            x = xi + 0.5
            i = (yi * N + xi) * 4
            d_body = body_sdf(x, y)
            if d_body > -1:
                a = 0.32 * 0.5 * math.erfc(body_sdf(x, y - 10) * shadow_k)
                if a > 1 / 1024:
                    over(px, i, 0.0, 0.0, 0.0, a)
            a = cov(d_body)
            if a == 0.0:
                continue
            glow = max(0.0, 1.0 - ((x - 512) ** 2 + (y - 110) ** 2) / 640.0 ** 2) * 0.14   # soft light from the top
            over(px, i, *mix(base, (1, 1, 1), glow), a)
            over(px, i, 1.0, 1.0, 1.0, TREAD_A * cov(tread_sdf(x, y)) * min(1.0, max(0.0, -(d_body + 24) / 64)))   # fades out at the rim
            over(px, i, 1.0, 1.0, 1.0, 0.12 * cov(abs(d_body + 2.0) - 1.5))   # thin rim: keeps the edge on dark Docks
            if not (200 < x < 860 and 240 < y < 730):   # laptop + its shadow
                continue
            whole, lid, screen, deck, check = laptop(x, y)
            union[i // 4] = whole
            d_shadow = union[i // 4 - 12 * N]           # 12 px above casts onto here
            if d_shadow < 40:
                over(px, i, 0.0, 0.0, 0.0, 0.45 * 0.5 * math.erfc(d_shadow * gshadow_k))
            over(px, i, *mix((1.0, 1.0, 1.0), (0.90, 0.91, 0.93), (y - 274) / 356), cov(lid))
            over(px, i, *mix((0.93, 0.95, 0.98), (0.80, 0.84, 0.90), (y - 302) / 300), cov(screen))
            over(px, i, *mix((0.97, 0.97, 0.98), (0.72, 0.74, 0.78), (y - 644) / 48), cov(deck))
            over(px, i, *mix(GREEN_TOP, GREEN_BOTTOM, (y - 350) / 210), cov(check))
    return px


def half(px, n):
    """2x2 box filter (premultiplied, so edges don't darken)."""
    m = n // 2
    out = array("f", bytes(m * m * 16))
    row = n * 4
    for y in range(m):
        r0 = 2 * y * row
        r1 = r0 + row
        o = y * m * 4
        for x in range(m):
            i, j, k = r0 + 8 * x, r1 + 8 * x, o + 4 * x
            for c in range(4):
                out[k + c] = (px[i + c] + px[i + 4 + c] + px[j + c] + px[j + 4 + c]) * 0.25
    return out


def write_png(path, px, n):
    raw = bytearray()
    for y in range(n):
        raw.append(0)  # filter: none
        for x in range(n):
            i = (y * n + x) * 4
            a = px[i + 3]
            if a < 1 / 512:
                raw += b"\0\0\0\0"
                continue
            raw += bytes(min(255, int(px[i + c] / a * 255 + 0.5)) for c in range(3))
            raw.append(min(255, int(a * 255 + 0.5)))

    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data))

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", n, n, 8, 6, 0, 0, 0)))
        f.write(chunk(b"sRGB", b"\0"))
        f.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        f.write(chunk(b"IEND", b""))


def main():
    os.makedirs(OUT, exist_ok=True)
    images, by_size = [], {N: render()}
    n = N
    while n > 16:
        by_size[n // 2] = half(by_size[n], n)
        n //= 2
    for pt in (16, 32, 128, 256, 512):
        for scale in (1, 2):
            name = f"icon_{pt}x{pt}{'@2x' if scale == 2 else ''}.png"
            write_png(os.path.join(OUT, name), by_size[pt * scale], pt * scale)
            images.append({"filename": name, "idiom": "mac", "scale": f"{scale}x", "size": f"{pt}x{pt}"})
    with open(os.path.join(OUT, "Contents.json"), "w", newline="\n") as f:
        json.dump({"images": images, "info": {"author": "xcode", "version": 1}}, f, indent=2)
        f.write("\n")
    with open(os.path.join(OUT, "..", "Contents.json"), "w", newline="\n") as f:
        json.dump({"info": {"author": "xcode", "version": 1}}, f, indent=2)
        f.write("\n")
    print(f"wrote {len(images)} PNGs to {os.path.normpath(OUT)}")


if __name__ == "__main__":
    main()
