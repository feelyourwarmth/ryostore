#!/usr/bin/env python3
"""Import curated public-domain launcher images into the RyoStore catalogue.

A launcher image is a curated public-domain artwork installed as the Ryoku
app-launcher HERO header - the wide band that sits behind the greeting and
weather, like the shipped Creation-of-Adam fallback. Every launcher image ships
two PNG variants: the raw image (`content/source.png`) and a pre-baked dithered
variant (`content/dither.png`, Ryoku's one-bit bone-on-transparent look). The
store's install offers a dither toggle to pick which variant lands on the
machine.

Two phases keep it reproducible:

  fetch  - resolve each source through the Wikimedia Commons API or the Met
           Collection API, VERIFY it is public-domain / CC0 from the API's own
           licence metadata, download it, normalise it to PNG at up to 1800px on
           the long edge as launcher-images/<id>/content/source.png, and write a
           PROVENANCE.txt (source URL + licence + attribution) at the product
           root.

  build  - bake launcher-images/<id>/content/dither.png with bin/art/ryodither
           (a Bayer dither to Ryoku bone on transparent; --invert inks
           dark-on-light sources), render assets/preview.webp by compositing that
           dither centred on a >=1280x720 #101010 canvas with `magick`, render
           assets/preview-raw.webp the same way from the raw source, sample an
           accent tone from the source, write each manifest.json (real byte sizes
           + sha256; source/dither/PROVENANCE install:true, preview install:false;
           destination ryoku-launchers/<id>) and rewrite launcher-images/
           registry.json with matching manifestSha256 values.

Usage:
    tools/import-launcher-images.py fetch    # download + normalise every source
    tools/import-launcher-images.py build    # bake dithers + previews + registry
    tools/import-launcher-images.py all      # fetch then build
    tools/import-launcher-images.py ids      # print curated ids

The dither tool defaults to ../ryoku-arch-unstable/bin/art/ryodither (override
with $RYODITHER). Requires ImageMagick (`magick`) and Pillow.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATEGORY = "launcher-images"
CATEGORY_DIR = ROOT / CATEGORY
VERSION = "1.0.0"

MAX_EDGE = 1800                       # long-edge cap for the normalised source PNG
BONE = "#e8d8c9"                      # Ryoku bone: the launcher-image ink colour
SURFACE = "#101010"                   # the dark ground the launcher image sits on
PREVIEW_MIN = (1280, 720)            # validator's minimum media frame
PREVIEW_FIT = 1500                    # longest edge of the art inside the preview
PREVIEW_PAD = 120                     # total #101010 margin around the art

RYODITHER = Path(
    os.environ.get("RYODITHER")
    or (ROOT.parent / "ryoku-arch-unstable" / "bin" / "art" / "ryodither")
)
COMMONS_API = "https://commons.wikimedia.org/w/api.php"
MET_OBJECT = "https://collectionapi.metmuseum.org/public/collection/v1/objects/{}"
USER_AGENT = "ryoku-import-launcher-images/1.0 (RyoStore catalogue tooling)"

# Curated set: wide / landscape public-domain art that reads as a striking
# full-bleed launcher backdrop behind text and dithers into a clean one-bit
# bone. `invert` inks the dark tones, for dark-on-light sources (woodblock
# prints, engravings, storm-dark skies).
CURATED = [
    dict(
        id="great-wave", name="The Great Wave", source="commons", invert=True,
        title="File:The Great Wave off Kanagawa.jpg",
        author="Katsushika Hokusai (c.1831)",
        summary="Hokusai's great wave curling over a distant Fuji, in bone.",
        description="Under the Wave off Kanagawa (The Great Wave) from Hokusai's Thirty-six Views of Mount Fuji - the towering breaker and its claw of foam above a small Fuji - reduced to Ryoku's one-bit bone.",
        tags=["woodblock", "hokusai", "ukiyo-e", "seascape"],
    ),
    dict(
        id="shono", name="Driving Rain at Shono", source="commons", invert=True,
        title="File:Clevelandart 1948.306.jpg",
        author="Utagawa Hiroshige (c.1833)",
        summary="Hiroshige's travellers bent under a grey downpour at Shono.",
        description="Driving Rain at Shono (Shono hakuu), station 46 of Hiroshige's Fifty-three Stations of the Tokaido - porters and a palanquin hurrying through slanting rain - baked to Ryoku's one-bit bone.",
        tags=["woodblock", "hiroshige", "ukiyo-e", "landscape"],
    ),
    dict(
        id="sea-of-ice", name="The Sea of Ice", source="commons", invert=True,
        title="File:Caspar David Friedrich - Das Eismeer - Hamburger Kunsthalle - 02.jpg",
        author="Caspar David Friedrich (1823-1824)",
        summary="Friedrich's shattered polar ice heaved over a lost ship.",
        description="The Sea of Ice (Das Eismeer) - Caspar David Friedrich's slabs of polar ice piled into a jagged pyramid above a crushed hull - reduced to Ryoku's one-bit bone.",
        tags=["romanticism", "friedrich", "landscape", "dramatic"],
    ),
    dict(
        id="wheatfield-crows", name="Wheatfield with Crows", source="commons", invert=True,
        title="File:Vincent van Gogh - Wheatfield with crows - Google Art Project.jpg",
        author="Vincent van Gogh (1890)",
        summary="Van Gogh's crows scattering over a storm-dark wheatfield.",
        description="Wheatfield with Crows - Van Gogh's turbulent sky, golden wheat, and a flock of black crows over three diverging paths - baked to Ryoku's one-bit bone.",
        tags=["post-impressionism", "van-gogh", "landscape", "dramatic"],
    ),
    dict(
        id="ninth-wave", name="The Ninth Wave", source="commons", invert=False,
        title="File:Aivazovsky, Ivan - The Ninth Wave.jpg",
        author="Ivan Aivazovsky (1850)",
        summary="Aivazovsky's dawn breaking over survivors and a vast swell.",
        description="The Ninth Wave - Ivan Aivazovsky's shipwreck survivors clinging to a mast as a warm dawn breaks over the towering sea - reduced to Ryoku's one-bit bone.",
        tags=["romanticism", "aivazovsky", "seascape", "dramatic"],
    ),
    dict(
        id="carina-nebula", name="The Carina Nebula", source="commons", invert=False,
        title="File:NGC 3372a-full.jpg",
        author="NASA, ESA / STScI (Hubble)",
        summary="A wide Hubble panorama of the Carina Nebula in bone light.",
        description="The Hubble Space Telescope's panorama of the Carina Nebula (NGC 3372) - towers and clouds of glowing gas around unstable young stars - dithered so the nebular light reads as Ryoku bone.",
        tags=["astronomy", "nasa", "nebula", "space"],
    ),
]

CURATED_BY_ID = {entry["id"]: entry for entry in CURATED}


# --------------------------------------------------------------------------- #
# helpers
# --------------------------------------------------------------------------- #
def http_get(url: str, *, retries: int = 5) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                return response.read()
        except urllib.error.HTTPError as error:
            # Wikimedia thumbnailing rate-limits (429) and occasionally 503s;
            # back off (honouring Retry-After) and retry rather than bail.
            if error.code not in (429, 503) or attempt == retries - 1:
                raise
            delay = float(error.headers.get("Retry-After") or 0) or 2.0 * (attempt + 1)
            time.sleep(min(delay, 30.0))
    raise RuntimeError("unreachable")


def api_get(base: str, params: dict[str, str]) -> dict:
    return json.loads(http_get(f"{base}?{urllib.parse.urlencode(params)}"))


def magick(*args: str) -> str:
    return subprocess.run(["magick", *args], check=True, capture_output=True, text=True).stdout


def identify(path: Path) -> tuple[int, int]:
    width, height = magick("identify", "-format", "%w %h", str(path)).split()
    return int(width), int(height)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def dump_json(value: object) -> bytes:
    return (json.dumps(value, indent=2, ensure_ascii=False) + "\n").encode("utf-8")


def write_file(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    os.chmod(path, 0o644)


def selected(ids: list[str]) -> list[dict]:
    if not ids:
        return CURATED
    chosen = []
    for wanted in ids:
        if wanted not in CURATED_BY_ID:
            raise SystemExit(f"unknown launcher-image id: {wanted}")
        chosen.append(CURATED_BY_ID[wanted])
    return chosen


def ok_license(short: str) -> bool:
    text = short.lower()
    return "public domain" in text or "cc0" in text or text.startswith("pd")


def commons_page(title: str) -> str:
    return "https://commons.wikimedia.org/wiki/" + urllib.parse.quote(title.replace(" ", "_"))


# --------------------------------------------------------------------------- #
# fetch
# --------------------------------------------------------------------------- #
def resolve_commons(entry: dict) -> dict:
    data = api_get(COMMONS_API, {
        "action": "query", "prop": "imageinfo",
        "iiprop": "url|size|extmetadata", "iiurlwidth": str(MAX_EDGE),
        "format": "json", "titles": entry["title"],
    })
    page = next(iter(data["query"]["pages"].values()))
    if "missing" in page or not page.get("imageinfo"):
        raise SystemExit(f"{entry['id']}: commons file not found: {entry['title']}")
    info = page["imageinfo"][0]
    short = (info.get("extmetadata", {}).get("LicenseShortName", {}).get("value") or "").strip()
    if not ok_license(short):
        raise SystemExit(f"{entry['id']}: refusing non-free commons licence: {short!r}")
    return {
        "url": info["thumburl"],
        "page": info.get("descriptionurl") or commons_page(entry["title"]),
        "license": f"{short} (Wikimedia Commons)",
    }


def resolve_met(entry: dict) -> dict:
    obj = json.loads(http_get(MET_OBJECT.format(entry["object_id"])))
    if not obj.get("isPublicDomain"):
        raise SystemExit(f"{entry['id']}: Met object {entry['object_id']} is not public domain")
    image = obj.get("primaryImage") or ""
    if not image:
        raise SystemExit(f"{entry['id']}: Met object {entry['object_id']} has no image")
    return {
        "url": image,
        "page": obj.get("objectURL") or f"https://www.metmuseum.org/art/collection/search/{entry['object_id']}",
        "license": "CC0 1.0 / public domain (The Met, Open Access)",
    }


def to_source_png(raw: bytes, dest: Path) -> tuple[int, int]:
    """Normalise a downloaded image to PNG, long edge capped at MAX_EDGE."""
    staging = dest.with_name("source.download")
    write_file(staging, raw)
    magick(str(staging), "-resize", f"{MAX_EDGE}x{MAX_EDGE}>", "-strip", str(dest))
    staging.unlink()
    os.chmod(dest, 0o644)
    return identify(dest)


def provenance_text(entry: dict, meta: dict) -> str:
    return (
        f"{entry['name']} - Ryoku launcher image\n\n"
        f"Subject: {entry['description']}\n"
        f"Source: {meta['page']}\n"
        f"Download: {meta['url']}\n"
        f"Attribution: {entry['author']}\n"
        f"License: {meta['license']}\n\n"
        "content/source.png is the raw public-domain image, normalised to PNG at "
        f"up to {MAX_EDGE}px on the long edge. content/dither.png is the Ryoku "
        "one-bit bone-on-transparent variant baked with bin/art/ryodither. "
        "assets/preview.webp (the dithered look on a dark ground) and "
        "assets/preview-raw.webp (the raw art on the same ground) are catalogue "
        "media and are not installed with the runtime payload.\n"
    )


def fetch(ids: list[str]) -> None:
    for index, entry in enumerate(selected(ids)):
        if index:
            time.sleep(1.0)   # be polite to the source APIs / thumbnailers
        meta = resolve_commons(entry) if entry["source"] == "commons" else resolve_met(entry)
        product = CATEGORY_DIR / entry["id"]
        content = product / "content"
        content.mkdir(parents=True, exist_ok=True)
        width, height = to_source_png(http_get(meta["url"]), content / "source.png")
        write_file(product / "PROVENANCE.txt", provenance_text(entry, meta).encode("utf-8"))
        print(f"fetched {entry['id']}: source.png {width}x{height}  licence={meta['license']}")


# --------------------------------------------------------------------------- #
# build: dither + preview + colours + manifest + registry
# --------------------------------------------------------------------------- #
def luminance(rgb: tuple[int, int, int]) -> float:
    r, g, b = rgb
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def saturation(rgb: tuple[int, int, int]) -> float:
    hi, lo = max(rgb), min(rgb)
    return 0.0 if hi == 0 else (hi - lo) / hi


def hexof(rgb: tuple[int, int, int]) -> str:
    return "#{:02x}{:02x}{:02x}".format(*rgb)


def histogram(path: Path, colors: int = 16) -> list[tuple[int, tuple[int, int, int]]]:
    text = magick(str(path), "-resize", "120x", "-colors", str(colors),
                  "-depth", "8", "-format", "%c", "histogram:info:")
    out: list[tuple[int, tuple[int, int, int]]] = []
    for line in text.splitlines():
        line = line.strip()
        if not line or "(" not in line:
            continue
        count = int(line.split(":", 1)[0].strip())
        srgb = line[line.find("(") + 1:line.find(")")].split(",")
        rgb = tuple(int(float(component)) for component in srgb[:3])
        out.append((count, rgb))
    return out


def sample_accent(source: Path) -> str:
    """Accent = the most saturated prominent tone in a usable luminance band;
    bone (#e8d8c9) for monochrome sources with no colour to sample."""
    bins = histogram(source)
    if not bins:
        return BONE
    total = sum(count for count, _ in bins) or 1
    # A near-black or blown-out tone is a poor UI accent against #101010, so
    # only consider mid-range, sufficiently saturated colours; if none exist
    # (a grey engraving or sepia plate), fall back to bone.
    usable = [(count, rgb) for count, rgb in bins
              if 60 <= luminance(rgb) <= 235 and saturation(rgb) >= 0.15]
    if not usable:
        return BONE
    accent = max(usable, key=lambda item: saturation(item[1]) * (0.4 + 0.6 * item[0] / total))[1]
    return hexof(accent)


def bake_dither(entry: dict, content: Path) -> Path:
    dither = content / "dither.png"
    if dither.exists():
        dither.unlink()
    args = [sys.executable, str(RYODITHER), str(content / "source.png"),
            "--out", str(content), "--name", "dither"]
    if entry.get("invert"):
        args.append("--invert")
    subprocess.run(args, check=True, capture_output=True, text=True)
    if not dither.is_file():
        raise SystemExit(f"{entry['id']}: ryodither did not produce {dither}")
    os.chmod(dither, 0o644)
    return dither


def render_preview(dither: Path, preview: Path) -> tuple[int, int]:
    """Composite the bone-on-transparent dither centred on a >=1280x720 ground."""
    width, height = identify(dither)
    scale = min(PREVIEW_FIT / width, PREVIEW_FIT / height, 1.0)
    fit_w, fit_h = max(1, round(width * scale)), max(1, round(height * scale))
    canvas_w = max(PREVIEW_MIN[0], fit_w + PREVIEW_PAD)
    canvas_h = max(PREVIEW_MIN[1], fit_h + PREVIEW_PAD)
    preview.parent.mkdir(parents=True, exist_ok=True)
    magick("-size", f"{canvas_w}x{canvas_h}", f"xc:{SURFACE}",
           "(", str(dither), "-resize", f"{fit_w}x{fit_h}", ")",
           "-gravity", "center", "-composite", "-quality", "90", str(preview))
    os.chmod(preview, 0o644)
    return identify(preview)


def declared_files(product: Path) -> list[dict]:
    rows = []
    for path in sorted(product.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(product).as_posix()
        if rel == "manifest.json":
            continue
        if rel.startswith("assets/"):
            destination, install = Path(rel).name, False   # media installs nowhere
        elif rel.startswith("content/"):
            destination, install = rel[len("content/"):], True
        else:                                               # PROVENANCE.txt, LICENSE
            destination, install = rel, True
        data = path.read_bytes()
        rows.append({
            "source": rel, "destination": destination, "mode": "0644",
            "size": len(data), "sha256": sha256_bytes(data), "install": install,
        })

    def order(row: dict) -> tuple:
        source = row["source"]
        bucket = 0 if source in ("LICENSE", "PROVENANCE.txt", "NOTICE") else 1 if source.startswith("assets/") else 2
        return (bucket, source)

    rows.sort(key=order)
    return rows


def build(ids: list[str]) -> None:
    registry_path = CATEGORY_DIR / "registry.json"
    if registry_path.is_file():
        registry = json.loads(registry_path.read_text(encoding="utf-8"))
    else:
        registry = {"schema": 1, CATEGORY: []}
    entries = {entry["id"]: entry for entry in registry.get(CATEGORY, [])}

    for entry in selected(ids):
        pid = entry["id"]
        product = CATEGORY_DIR / pid
        content = product / "content"
        source = content / "source.png"
        if not source.is_file():
            print(f"SKIP {pid}: no content/source.png (run fetch first)")
            continue

        dither = bake_dither(entry, content)
        preview_w, preview_h = render_preview(dither, product / "assets" / "preview.webp")
        render_preview(source, product / "assets" / "preview-raw.webp")
        accent = sample_accent(source)

        files = declared_files(product)
        manifest = {
            "schema": 1, "id": pid, "category": CATEGORY, "version": VERSION,
            "destination": f"ryoku-launchers/{pid}", "files": files,
        }
        manifest_bytes = dump_json(manifest)
        write_file(product / "manifest.json", manifest_bytes)

        entries[pid] = {
            "id": pid, "name": entry["name"], "version": VERSION,
            "path": f"{CATEGORY}/{pid}", "author": entry["author"],
            "summary": entry["summary"], "description": entry["description"],
            "tags": list(entry["tags"]), "accent": accent, "surface": SURFACE,
            "preview": "assets/preview.webp", "previewRaw": "assets/preview-raw.webp", "screenshots": [],
            "manifest": "manifest.json", "manifestSha256": sha256_bytes(manifest_bytes),
        }
        print(f"built {pid}: preview {preview_w}x{preview_h} accent={accent} "
              f"invert={bool(entry.get('invert'))} files={len(files)}")

    ordered = sorted(entries.values(), key=lambda entry: entry["id"])
    registry = {"schema": 1, CATEGORY: ordered}
    write_file(registry_path, dump_json(registry))
    print(f"registry.json updated: {len(ordered)} launcher images")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Import curated public-domain launcher images into RyoStore")
    sub = parser.add_subparsers(dest="command", required=True)
    for name, help_text in (("fetch", "download + normalise every source"),
                            ("build", "bake dithers + previews + registry"),
                            ("all", "fetch then build")):
        cmd = sub.add_parser(name, help=help_text)
        cmd.add_argument("ids", nargs="*", help="launcher-image ids (default: all curated)")
    sub.add_parser("ids", help="print curated ids")

    args = parser.parse_args(argv)
    if args.command == "fetch":
        fetch(args.ids)
    elif args.command == "build":
        build(args.ids)
    elif args.command == "all":
        fetch(args.ids)
        build(args.ids)
    elif args.command == "ids":
        print(" ".join(entry["id"] for entry in CURATED))
    return 0


if __name__ == "__main__":
    sys.exit(main())
