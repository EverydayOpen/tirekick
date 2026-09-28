"""Render site/static/og.png (1200x630 social preview: a Tirekick report card) and apple-touch-icon.png (180x180,
opaque: iOS fills transparent pixels with black), and copy favicon.png and icon.png from the app icon.

Stdlib only; reuses tools/make_icon.py (the icon master, coverage, compositing and PNG helpers). Text is drawn like
the icon: monoline strokes as signed distance functions (a small geometric font below), so edges get analytic
antialiasing. The card is centred, so previews that crop to a square still show the verdict and most rows.

Run from the repo root (about 2 minutes):  python tools/make_og.py
"""
import math
import os
import shutil
import struct
import zlib
from array import array

import make_icon as icon

W, H = 1200, 630
TOOLS = os.path.dirname(os.path.abspath(__file__))
STATIC = os.path.join(TOOLS, "..", "site", "static")
BG_TOP, BG_BOTTOM = (0.965, 0.968, 0.976), (0.890, 0.902, 0.925)
GLOW = (0.20, 0.78, 0.35)                   # the check's green
INK, MUTED, LINE = (0.114, 0.114, 0.122), (0.43, 0.43, 0.45), (0.90, 0.90, 0.92)
CARD = (170.0, 44.0, 1030.0, 586.0)         # left, top, right, bottom
X0 = CARD[0] + 56                           # content inset

# The card's text: a seller's card, everything checked out. Keep it to the glyphs in GLYPHS.
TITLE, SPECS, VERDICT = "Tirekick", "MacBook Pro · M3 Pro · 18 GB · 512 GB", "Clean"
ROWS = ["Activation Lock off", "No MDM, no company", "Battery 91%, 212 cycles", "SSD healthy",
        "Keyboard 78 of 78", "Gets macOS 27"]
FOOTER = "Checked on this Mac · Only trust a check you run yourself"

# Glyphs in x-height units, y up from the baseline, as stroke centrelines. Centrelines sit a default half stroke
# (0.1) inside the x-height (T), baseline (B), ascender (A), cap height (C) and descender (D).
T, B, A, C, D = 0.9, 0.1, 1.35, 1.3, -0.4
GLYPHS = {   # ("l", x0, y0, x1, y1) line; ("a", cx, cy, r, deg0, deg1) arc, counterclockwise; ("o", cx, cy, r) dot
    "a": [("a", 0.5, 0.5, 0.4, 0, 360), ("l", 0.9, T, 0.9, B)],
    "b": [("l", 0.1, A, 0.1, B), ("a", 0.5, 0.5, 0.4, 0, 360)],
    "c": [("a", 0.5, 0.5, 0.4, 50, 310)],
    "d": [("a", 0.5, 0.5, 0.4, 0, 360), ("l", 0.9, A, 0.9, B)],
    "e": [("l", 0.1, 0.5, 0.9, 0.5), ("a", 0.5, 0.5, 0.4, 0, 315)],
    "f": [("l", 0.3, B, 0.3, 1.05), ("a", 0.6, 1.05, 0.3, 90, 180), ("l", 0.02, T, 0.56, T)],
    "g": [("a", 0.5, 0.5, 0.4, 0, 360), ("l", 0.9, T, 0.9, 0.0), ("a", 0.5, 0.0, 0.4, 200, 360)],
    "h": [("l", 0.1, A, 0.1, B), ("a", 0.5, 0.5, 0.4, 0, 180), ("l", 0.9, 0.5, 0.9, B)],
    "i": [("l", 0.1, T, 0.1, B), ("o", 0.1, 1.27, 0.125)],
    "k": [("l", 0.1, A, 0.1, B), ("l", 0.78, T, 0.1, 0.32), ("l", 0.36, 0.54, 0.82, B)],
    "l": [("l", 0.1, A, 0.1, B)],
    "m": [("l", 0.1, T, 0.1, B), ("a", 0.4, 0.6, 0.3, 0, 180), ("l", 0.7, 0.6, 0.7, B),
          ("a", 1.0, 0.6, 0.3, 0, 180), ("l", 1.3, 0.6, 1.3, B)],
    "n": [("l", 0.1, T, 0.1, B), ("a", 0.5, 0.5, 0.4, 0, 180), ("l", 0.9, 0.5, 0.9, B)],
    "o": [("a", 0.5, 0.5, 0.4, 0, 360)],
    "p": [("l", 0.1, T, 0.1, D), ("a", 0.5, 0.5, 0.4, 0, 360)],
    "r": [("l", 0.1, T, 0.1, B), ("a", 0.5, 0.5, 0.4, 70, 180)],
    "s": [("a", 0.42, 0.695, 0.205, 30, 270), ("a", 0.42, 0.305, 0.205, 210, 450)],
    "t": [("l", 0.28, 1.22, 0.28, B), ("l", 0.02, T, 0.56, T)],
    "u": [("l", 0.1, T, 0.1, 0.5), ("a", 0.5, 0.5, 0.4, 180, 360), ("l", 0.9, T, 0.9, B)],
    "v": [("l", 0.08, T, 0.48, B), ("l", 0.48, B, 0.88, T)],
    "y": [("l", 0.1, T, 0.5, B), ("l", 0.9, T, 0.25, D)],
    "A": [("l", 0.1, B, 0.62, C), ("l", 0.62, C, 1.14, B), ("l", 0.28, 0.52, 0.96, 0.52)],
    "B": [("l", 0.1, B, 0.1, C), ("l", 0.1, C, 0.55, C), ("a", 0.55, 1.0, 0.3, 270, 450), ("l", 0.1, 0.7, 0.6, 0.7),
          ("a", 0.6, 0.4, 0.3, 270, 450), ("l", 0.6, B, 0.1, B)],
    "C": [("a", 0.72, 0.7, 0.6, 45, 315)],
    "D": [("l", 0.1, B, 0.1, C), ("l", 0.1, C, 0.5, C), ("a", 0.5, 0.7, 0.6, 270, 450), ("l", 0.5, B, 0.1, B)],
    "G": [("a", 0.72, 0.7, 0.6, 45, 360), ("l", 0.8, 0.7, 1.32, 0.7)],
    "K": [("l", 0.1, B, 0.1, C), ("l", 0.98, C, 0.1, 0.42), ("l", 0.44, 0.76, 1.02, B)],
    "L": [("l", 0.1, C, 0.1, B), ("l", 0.1, B, 0.82, B)],
    "M": [("l", 0.1, B, 0.1, C), ("l", 0.1, C, 0.72, 0.3), ("l", 0.72, 0.3, 1.34, C), ("l", 1.34, C, 1.34, B)],
    "N": [("l", 0.1, B, 0.1, C), ("l", 0.1, C, 1.02, B), ("l", 1.02, B, 1.02, C)],
    "O": [("a", 0.7, 0.7, 0.6, 0, 360)],
    "P": [("l", 0.1, B, 0.1, C), ("l", 0.1, C, 0.55, C), ("a", 0.55, 0.97, 0.33, 270, 450), ("l", 0.55, 0.64, 0.1, 0.64)],
    "S": [("a", 0.58, 1.0, 0.3, 30, 270), ("a", 0.58, 0.4, 0.3, 210, 450)],
    "T": [("l", 0.08, C, 1.02, C), ("l", 0.55, C, 0.55, B)],
    "1": [("l", 0.42, C, 0.42, B), ("l", 0.12, 1.05, 0.42, C)],
    "2": [("a", 0.5, 0.97, 0.33, 320, 520), ("l", 0.753, 0.758, 0.1, B), ("l", 0.1, B, 0.9, B)],
    "3": [("a", 0.48, 1.0, 0.3, 270, 510), ("a", 0.48, 0.4, 0.3, 210, 450)],
    "5": [("l", 0.86, C, 0.22, C), ("l", 0.22, C, 0.237, 0.668), ("a", 0.52, 0.43, 0.37, 220, 500)],
    "7": [("l", 0.1, C, 0.92, C), ("l", 0.92, C, 0.36, B)],
    "8": [("a", 0.5, 1.02, 0.28, 0, 360), ("a", 0.5, 0.42, 0.32, 0, 360)],
    "9": [("a", 0.5, 0.95, 0.35, 0, 360), ("l", 0.84, 0.86, 0.44, B)],
    ",": [("l", 0.12, 0.14, 0.02, -0.2)],
    "%": [("a", 0.28, 1.06, 0.2, 0, 360), ("a", 0.9, 0.34, 0.2, 0, 360), ("l", 1.02, C, 0.16, B)],
    "·": [("o", 0.1, 0.5, 0.1)],
}
GAP, SPACE = 0.14, 0.6   # between the visual edges of neighbouring glyphs; a space's width


def arc_points(s):
    _, cx, cy, r, a0, a1 = s
    return [(cx + r * math.cos(math.radians(a)), cy + r * math.sin(math.radians(a)))
            for a in list(range(int(a0), int(a1), 5)) + [a1]]


def stroke_dist(s, x, y, w):
    """Distance from (x, y) to stroke s with half width w (x-height units)."""
    if s[0] == "l":
        return icon.seg(x, y, *s[1:]) - w
    if s[0] == "o":
        return math.hypot(x - s[1], y - s[2]) - s[3]
    _, cx, cy, r, a0, a1 = s
    ang = math.degrees(math.atan2(y - cy, x - cx)) % 360
    if a1 - a0 >= 360 or a0 <= ang <= a1 or ang + 360 <= a1:
        return abs(math.hypot(x - cx, y - cy) - r) - w
    ends = [(cx + r * math.cos(math.radians(a)), cy + r * math.sin(math.radians(a))) for a in (a0, a1)]
    return min(math.hypot(x - ex, y - ey) for ex, ey in ends) - w


def x_extent(strokes, w):
    xs = []
    for s in strokes:
        if s[0] == "l":
            xs += [s[1] - w, s[3] - w, s[1] + w, s[3] + w]
        elif s[0] == "o":
            xs += [s[1] - s[3], s[1] + s[3]]
        else:
            xs += [x + d for x, _ in arc_points(s) for d in (-w, w)]
    return min(xs), max(xs)


def layout(text, w):
    """[(x offset, strokes, left, right)] in x-height units, and the total width."""
    placed, pen = [], 0.0
    for ch in text:
        if ch == " ":
            pen += SPACE - GAP
            continue
        lo, hi = x_extent(GLYPHS[ch], w)
        placed.append((pen - lo, GLYPHS[ch], pen, pen + hi - lo))
        pen += hi - lo + GAP
    return placed, pen - GAP


def text(px, s, x0, baseline, xh, colour, weight=0.1):
    """Draw s with its left edge at x0 and its baseline at `baseline` (pixels); returns the right edge."""
    placed, width = layout(s, weight)
    for y in range(int(baseline - (A + weight) * xh) - 2, int(baseline - (D - weight) * xh) + 3):
        v = (baseline - y - 0.5) / xh
        for x in range(int(x0) - 2, int(x0 + width * xh) + 3):
            u = (x + 0.5 - x0) / xh
            d = min((stroke_dist(st, u - off, v, weight) for off, strokes, lo, hi in placed
                     if lo - 0.2 <= u <= hi + 0.2 for st in strokes), default=1e9)
            a = icon.cov(d * xh)
            if a:
                icon.over(px, (y * W + x) * 4, *colour, a)
    return x0 + width * xh


def check_badge(px, cx, cy, r):
    """A filled green circle with a white check: the "OK" verdict symbol."""
    for y in range(int(cy - r) - 2, int(cy + r) + 3):
        for x in range(int(cx - r) - 2, int(cx + r) + 3):
            u, v = (x + 0.5 - cx) / r, (y + 0.5 - cy) / r
            i = (y * W + x) * 4
            icon.over(px, i, *GLOW, icon.cov((math.hypot(u, v) - 1) * r))
            d = min(icon.seg(u, v, -0.42, 0.02, -0.12, 0.32), icon.seg(u, v, -0.12, 0.32, 0.45, -0.3)) - 0.11
            icon.over(px, i, 1.0, 1.0, 1.0, icon.cov(d * r))


def rule(px, y, x0, x1):
    for x in range(int(x0), int(x1)):
        icon.over(px, (int(y) * W + x) * 4, *LINE, 1.0)


def resample(px, n, m):
    """Bilinear n -> m on a premultiplied square buffer (used for m > n / 2, then halved)."""
    out = array("f", bytes(m * m * 16))
    k = n / m
    for y in range(m):
        sy = min(n - 1.0, max(0.0, (y + 0.5) * k - 0.5))
        y0 = int(sy)
        y1, fy = min(y0 + 1, n - 1), sy - y0
        for x in range(m):
            sx = min(n - 1.0, max(0.0, (x + 0.5) * k - 0.5))
            x0 = int(sx)
            x1, fx = min(x0 + 1, n - 1), sx - x0
            i00, i01, i10, i11 = (y0 * n + x0) * 4, (y0 * n + x1) * 4, (y1 * n + x0) * 4, (y1 * n + x1) * 4
            o = (y * m + x) * 4
            for c in range(4):
                top = px[i00 + c] + (px[i01 + c] - px[i00 + c]) * fx
                bot = px[i10 + c] + (px[i11 + c] - px[i10 + c]) * fx
                out[o + c] = top + (bot - top) * fy
    return out


def render(master):
    px = array("f", bytes(W * H * 16))
    l, t, r, b = CARD
    cx, cy, hw, hh = (l + r) / 2, (t + b) / 2, (r - l) / 2, (b - t) / 2
    shadow_k = 1 / (22.0 * math.sqrt(2))
    for y in range(H):
        base = [BG_TOP[c] + (BG_BOTTOM[c] - BG_TOP[c]) * y / (H - 1) for c in range(3)]
        for x in range(W):
            i = (y * W + x) * 4
            px[i:i + 4] = array("f", base + [1.0])
            g = max(0.0, 1.0 - math.hypot((x - cx) / 1.7, y - cy) / 360) ** 2 * 0.10   # soft glow behind the card
            if g:
                icon.over(px, i, *GLOW, g)
            icon.over(px, i, 0.0, 0.0, 0.05, 0.16 * 0.5 * math.erfc(icon.rrect(x + 0.5, y + 0.5 - 14, cx, cy, hw, hh, 30) * shadow_k))
            icon.over(px, i, 1.0, 1.0, 1.0, icon.cov(icon.rrect(x + 0.5, y + 0.5, cx, cy, hw, hh, 30)))

    # Header: the app icon (1024 master -> bilinear to 2x -> 2x2 box filter), name and specs.
    size, top = 64, 74
    small = icon.half(resample(master, icon.N, 2 * size), 2 * size)
    for y in range(size):
        for x in range(size):
            s, d = (y * size + x) * 4, ((top + y) * W + int(X0) + x) * 4
            k = 1.0 - small[s + 3]
            for c in range(4):
                px[d + c] = small[s + c] + px[d + c] * k
    end = text(px, TITLE, X0 + size + 18, 104, 21, INK, 0.11)
    text(px, "report", end + 0.5 * 21, 104, 21, MUTED, 0.1)
    text(px, SPECS, X0 + size + 18, 132, 12.5, MUTED, 0.09)
    rule(px, 166, X0, r - 56)

    check_badge(px, X0 + 30, 226, 30)
    text(px, VERDICT, X0 + 78, 248, 36, INK, 0.12)

    for n, row in enumerate(ROWS):
        x, y = X0 + (n % 2) * 392, 318 + (n // 2) * 62
        check_badge(px, x + 15, y - 7, 15)
        text(px, row, x + 44, y, 16, INK, 0.1)
    rule(px, 488, X0, r - 56)
    text(px, FOOTER, X0, 530, 12.5, MUTED, 0.09)
    return px


def write_png(path, px, w, h):
    """Opaque RGB PNG."""
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        row = px[y * w * 4:(y + 1) * w * 4]
        for x in range(w):
            raw += bytes(min(255, int(row[4 * x + c] * 255 + 0.5)) for c in range(3))

    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data))

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)))
        f.write(chunk(b"sRGB", b"\0"))
        f.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        f.write(chunk(b"IEND", b""))


def main():
    os.makedirs(STATIC, exist_ok=True)
    shutil.copyfile(os.path.join(icon.OUT, "icon_32x32@2x.png"), os.path.join(STATIC, "favicon.png"))
    shutil.copyfile(os.path.join(icon.OUT, "icon_128x128@2x.png"), os.path.join(STATIC, "icon.png"))
    master = icon.render()
    # 180 px (Apple's size) on white; the macOS icon's ~10% margin gives iOS's mask room around the artwork.
    touch = icon.half(resample(master, icon.N, 360), 360)
    for i in range(0, len(touch), 4):
        k = 1.0 - touch[i + 3]   # premultiplied "over" white: c + (1 - a)
        for c in range(3):
            touch[i + c] += k
    write_png(os.path.join(STATIC, "apple-touch-icon.png"), touch, 180, 180)
    write_png(os.path.join(STATIC, "og.png"), render(master), W, H)
    print(f"wrote og.png, favicon.png, icon.png, apple-touch-icon.png to {os.path.normpath(STATIC)}")


if __name__ == "__main__":
    main()
