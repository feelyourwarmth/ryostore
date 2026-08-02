#!/usr/bin/env python3
"""Render eye-candy showcase covers for products that have no real capture yet.

The Store shows every product's ``preview`` as artwork and overlays its own
name, category, and status on top. A cover therefore has to be pure imagery in
the product's own palette, with no baked-in text to duplicate the overlay. This
tool owns exactly ``assets/preview.webp``: a product that ships a real capture
under any other name (for example ``assets/hero.png``) is left untouched.

Each cover is a textless, on-brand composition built from the product's accent
and surface colours, with a motif chosen per category:

  rices      an abstract desktop: wallpaper glow, a floating window, a bar with
             islands, and a dock
  bundles    a grid of tool cards, a few lit in the accent, reading as a set
  barstyles  a prominent bar of islands seated above a window

Rendering is deterministic: the seed comes from the product id, so re-running
produces byte-identical output and stable hashes. After writing a cover the tool
repairs the delivery chain it would otherwise break: the preview row's size and
sha256 in the product manifest, and the manifest's own sha256 in the category
registry.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

WIDTH, HEIGHT = 1280, 720
OWNED_PREVIEW = "assets/preview.webp"


def hex_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def darker(c, f):
    return tuple(max(0, int(c[i] / f)) for i in range(3))


def rounded(draw, box, radius, fill=None, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def base_wall(accent, surface, glow_xy, glow_r, tilt):
    top = mix(surface, accent, 0.42)
    bottom = darker(surface, 1.5)
    rows = np.linspace(0, 1, HEIGHT)[:, None]
    cols = np.linspace(0, 1, WIDTH)[None, :]
    ramp = np.clip(rows * 0.8 + (1 - cols) * tilt, 0, 1)
    wall = np.zeros((HEIGHT, WIDTH, 3), np.float32)
    for i in range(3):
        wall[:, :, i] = top[i] * (1 - ramp) + bottom[i] * ramp
    img = Image.fromarray(wall.astype(np.uint8), "RGB")

    mask = Image.new("L", (WIDTH, HEIGHT), 0)
    gx, gy = int(WIDTH * glow_xy[0]), int(HEIGHT * glow_xy[1])
    gr = int(WIDTH * glow_r)
    ImageDraw.Draw(mask).ellipse([gx - gr, gy - gr, gx + gr, gy + gr], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(170))
    glow = np.asarray(img, np.float32) + (np.asarray(mask, np.float32) / 255 * 0.5)[:, :, None] * np.array(
        mix(accent, (255, 255, 255), 0.4)
    )
    return Image.fromarray(np.clip(glow, 0, 255).astype(np.uint8), "RGB")


def finish(img, seed):
    rng = np.random.default_rng(seed)
    noise = rng.normal(0, 1, (HEIGHT, WIDTH)).astype(np.float32) * 8.0
    current = np.asarray(img, np.float32) + noise[:, :, None]
    ys, xs = np.mgrid[0:HEIGHT, 0:WIDTH]
    dist = np.sqrt(((xs - WIDTH / 2) / (WIDTH / 2)) ** 2 + ((ys - HEIGHT / 2) / (HEIGHT / 2)) ** 2)
    vignette = np.clip(1 - (dist - 0.72) * 0.7, 0.42, 1.0)
    return Image.fromarray(np.clip(current * vignette[:, :, None], 0, 255).astype(np.uint8), "RGB")


def rice_desktop(accent, surface, seed):
    img = base_wall(accent, surface, (0.7, 0.15), 0.55, 0.3)
    overlay = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    lift = mix(surface, (255, 255, 255), 0.06)
    ink = mix(surface, (255, 255, 255), 0.5)

    rounded(draw, [70, 54, WIDTH - 70, 104], 16, fill=darker(surface, 1.1) + (220,))
    rounded(draw, [86, 64, 250, 94], 10, fill=accent + (210,))
    for x0 in (WIDTH / 2 - 150, WIDTH / 2 - 40, WIDTH / 2 + 70):
        rounded(draw, [x0, 64, x0 + 90, 94], 10, fill=lift + (220,))
    rounded(draw, [WIDTH - 250, 64, WIDTH - 86, 94], 10, fill=lift + (220,))

    wx, wy, ww, wh = 150, 180, 560, 360
    rounded(draw, [wx, wy, wx + ww, wy + wh], 20, fill=lift + (240,), outline=accent + (120,), width=2)
    rounded(draw, [wx, wy, wx + ww, wy + 46], 20, fill=darker(lift, 1.15) + (255,))
    for i, cx in enumerate((wx + 26, wx + 50, wx + 74)):
        draw.ellipse([cx - 6, wy + 17, cx + 6, wy + 29], fill=(accent if i == 0 else ink) + (230,))
    for i in range(5):
        yl = wy + 90 + i * 46
        line = ww - 90 if i % 2 else ww - 180
        rounded(draw, [wx + 30, yl, wx + 30 + line, yl + 16], 8, fill=ink + (70 if i else 150,))

    rounded(draw, [wx + ww + 40, wy, WIDTH - 150, wy + wh], 20, fill=darker(surface, 1.05) + (220,),
            outline=accent + (60,), width=2)
    for i in range(6):
        yl = wy + 40 + i * 54
        draw.ellipse([wx + ww + 70, yl, wx + ww + 94, yl + 24], fill=accent + (150,) if i == 0 else ink + (60,))
        rounded(draw, [wx + ww + 110, yl + 4, WIDTH - 190, yl + 18], 6, fill=ink + (60,))

    dock = 6 * 72
    dx = (WIDTH - dock) // 2
    rounded(draw, [dx - 16, HEIGHT - 104, dx + dock + 16, HEIGHT - 40], 18, fill=darker(surface, 1.2) + (210,))
    for i in range(6):
        colour = accent if i in (0, 3) else lift
        rounded(draw, [dx + i * 72 + 8, HEIGHT - 96, dx + i * 72 + 56, HEIGHT - 48], 12, fill=colour + (230,))

    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    return finish(img, seed)


def bundle_tiles(accent, surface, seed):
    img = base_wall(accent, surface, (0.78, 0.1), 0.5, 0.25)
    overlay = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    lift = mix(surface, (255, 255, 255), 0.07)
    ink = mix(surface, (255, 255, 255), 0.5)

    cols, rows = 4, 3
    tw, th, gx, gy = 210, 150, 44, 40
    grid_w = cols * tw + (cols - 1) * gx
    grid_h = rows * th + (rows - 1) * gy
    ox = (WIDTH - grid_w) // 2
    oy = (HEIGHT - grid_h) // 2 + 6
    for r in range(rows):
        for c in range(cols):
            x = ox + c * (tw + gx)
            y = oy + r * (th + gy)
            hot = (r * cols + c) in (0, 5, 10)
            fill = mix(surface, accent, 0.5) if hot else lift
            rounded(draw, [x, y, x + tw, y + th], 18, fill=fill + (235,),
                    outline=accent + (90,) if hot else ink + (40,), width=2)
            rounded(draw, [x + 22, y + 22, x + 70, y + 70], 12,
                    fill=(mix(accent, (255, 255, 255), 0.15) if hot else accent) + (200,))
            rounded(draw, [x + 86, y + 30, x + tw - 24, y + 44], 6,
                    fill=(ink if not hot else mix(accent, (255, 255, 255), 0.4)) + (150,))
            rounded(draw, [x + 86, y + 54, x + tw - 52, y + 66], 6, fill=ink + (80,))
            for li in range(2):
                rounded(draw, [x + 22, y + 92 + li * 22, x + tw - 24 - (li * 40), y + 104 + li * 22], 6,
                        fill=ink + (70,))

    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    return finish(img, seed)


def bar_style(accent, surface, seed):
    img = base_wall(accent, surface, (0.5, 0.62), 0.6, 0.0)
    overlay = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    lift = mix(surface, (255, 255, 255), 0.08)
    ink = mix(surface, (255, 255, 255), 0.55)
    bar_bg = darker(surface, 1.15)

    by, bh = 150, 76
    rounded(draw, [70, by, WIDTH - 70, by + bh], 22, fill=bar_bg + (235,), outline=accent + (70,), width=2)
    rounded(draw, [92, by + 16, 300, by + bh - 16], 14, fill=lift + (230,))
    for i in range(5):
        cx = 112 + i * 36
        draw.ellipse([cx, by + bh // 2 - 7, cx + 14, by + bh // 2 + 7], fill=(accent if i == 1 else ink) + (230,))
    rounded(draw, [WIDTH / 2 - 190, by + 16, WIDTH / 2 + 190, by + bh - 16], 14, fill=lift + (230,))
    rounded(draw, [WIDTH / 2 - 150, by + bh // 2 - 8, WIDTH / 2 - 30, by + bh // 2 + 8], 6, fill=accent + (210,))
    rounded(draw, [WIDTH / 2 - 10, by + bh // 2 - 8, WIDTH / 2 + 150, by + bh // 2 + 8], 6, fill=ink + (120,))
    rounded(draw, [WIDTH - 300, by + 16, WIDTH - 92, by + bh - 16], 14, fill=lift + (230,))
    for i, frac in enumerate((0.6, 0.35, 0.8)):
        x0 = WIDTH - 286 + i * 66
        rounded(draw, [x0, by + bh - 30, x0 + 48, by + bh - 22], 4, fill=ink + (70,))
        rounded(draw, [x0, by + bh - 30, int(x0 + 48 * frac), by + bh - 22], 4, fill=accent + (200,))

    rounded(draw, [210, by + bh + 70, WIDTH - 210, HEIGHT - 70], 20,
            fill=mix(surface, (255, 255, 255), 0.04) + (200,), outline=accent + (45,), width=2)
    rounded(draw, [210, by + bh + 70, WIDTH - 210, by + bh + 116], 20, fill=bar_bg + (220,))
    for i, cx in enumerate((246, 276, 306)):
        draw.ellipse([cx - 6, by + bh + 86, cx + 6, by + bh + 98], fill=(accent if i == 0 else ink) + (220,))
    for i in range(4):
        yl = by + bh + 150 + i * 46
        rounded(draw, [250, yl, WIDTH - 260 - (i % 2) * 120, yl + 16], 8, fill=ink + (60 if i else 130,))

    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    return finish(img, seed)


MOTIFS = {"rices": rice_desktop, "bundles": bundle_tiles, "barstyles": bar_style}
DEFAULT_ACCENT = "#cdc4ba"
DEFAULT_SURFACE = "#101010"


def seed_for(product_id: str) -> int:
    return int.from_bytes(hashlib.sha256(product_id.encode()).digest()[:8], "big")


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def dump_json(value) -> bytes:
    return (json.dumps(value, indent=2, ensure_ascii=False) + "\n").encode("utf-8")


def render_cover(category: str, accent_hex: str, surface_hex: str, product_id: str) -> bytes:
    accent = hex_rgb(accent_hex if isinstance(accent_hex, str) and accent_hex else DEFAULT_ACCENT)
    surface = hex_rgb(surface_hex if isinstance(surface_hex, str) and surface_hex else DEFAULT_SURFACE)
    image = MOTIFS[category](accent, surface, seed_for(product_id))
    import io

    buffer = io.BytesIO()
    image.save(buffer, "WEBP", quality=90, method=6)
    return buffer.getvalue()


def regenerate(root: Path, category: str) -> list[str]:
    changed: list[str] = []
    registry_path = root / category / "registry.json"
    registry = json.loads(registry_path.read_text(encoding="utf-8"))
    for entry in registry.get(category, []):
        preview = entry.get("preview")
        if preview != OWNED_PREVIEW:
            continue
        product = root / entry["path"]
        cover = render_cover(category, entry.get("accent"), entry.get("surface"), entry["id"])
        (product / preview).write_bytes(cover)

        manifest_name = entry["manifest"]
        manifest_path = product / manifest_name
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        for row in manifest["files"]:
            if row.get("source") == preview:
                row["size"] = len(cover)
                row["sha256"] = sha256_bytes(cover)
                break
        else:
            raise SystemExit(f"{category}/{entry['id']}: manifest does not declare {preview}")
        manifest_bytes = dump_json(manifest)
        manifest_path.write_bytes(manifest_bytes)
        entry["manifestSha256"] = sha256_bytes(manifest_bytes)
        changed.append(f"{category}/{entry['id']}")
    registry_path.write_bytes(dump_json(registry))
    return changed


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Render eye-candy showcase covers and repair the delivery hashes")
    parser.add_argument("--root", default=".", help="catalogue root")
    parser.add_argument("--categories", default=",".join(MOTIFS), help="comma-separated categories to render")
    args = parser.parse_args(argv)
    root = Path(args.root).resolve()
    selected = [c.strip() for c in args.categories.split(",") if c.strip()]
    for category in selected:
        if category not in MOTIFS:
            raise SystemExit(f"no showcase motif for category {category!r}")
    total: list[str] = []
    for category in selected:
        rendered = regenerate(root, category)
        total.extend(rendered)
        print(f"{category}: rendered {len(rendered)} cover(s)")
    print(f"showcase: {len(total)} product cover(s) refreshed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
