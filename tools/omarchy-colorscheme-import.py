#!/usr/bin/env python3
"""Import HANCORE-linux Omarchy color themes into the RyoStore colorschemes catalogue.

On disk everything stays in Noctalia format. This tool performs the one-way
Omarchy `colors.toml` -> Noctalia entry conversion (conversion A of the RyoStore
color-scheme design) and maintains `colorschemes/registry.json` alongside the 51
existing noctalia-dev schemes.

Subcommands (flags):

  --backfill
      Add `id`/`provider`/`accent`/`surface` to every registry entry that lacks
      them, without touching the `dark`/`light` blocks. `provider` defaults to
      "Noctalia" (the catalogue NOTICE attributes every existing scheme to
      noctalia-dev); any per-scheme provenance hint found under the scheme dir is
      honoured instead.

  --all ORG
      Enumerate ORG's public repos via the GitHub API (paginated), keep the ones
      matching `omarchy-*-theme`, fetch each repo's `colors.toml` from its raw
      branch (master, then main, then the API default branch), apply conversion A,
      and upsert both a per-theme `colorschemes/hancore-<slug>/hancore-<slug>.json`
      ({"<mode>": block}) and a registry row. If the API rate-limits enumeration,
      fall back to the explicit slug list derived from the org README.

  --golden
      Fetch HANCORE `omarchy-blackturq-theme/colors.toml`, run conversion A, and
      assert the known mapping. Prints PASS or FAIL; exits non-zero on FAIL.

  --org ORG
      Override the org used for --golden / raw URLs (default HANCORE-linux).

Conversion A (colors.toml -> a Noctalia block), dark = luma(background) < 0.5:
  mPrimary=accent (fallback color4); mOnPrimary/mOnSecondary/mOnTertiary/mOnError/
  mOnHover=background; mSecondary=color2; mTertiary=color3; mError=color1;
  mHover=accent; mSurface=background; mOnSurface=foreground;
  mSurfaceVariant=mix(background,color8,0.4); mOnSurfaceVariant=color7 (fallback
  foreground); mOutline=color5; mShadow=#000000; terminal.normal/bright from
  color0..15; terminal fg/bg/cursor/selection from the file.

Re-running is idempotent: registry rows upsert by `id`, per-theme files overwrite,
backfill only fills what is missing.

Stdlib only (Python 3.11+ for tomllib). Honours $GITHUB_TOKEN for API auth.
"""
from __future__ import annotations

import argparse
import json
import math
import os
import re
import sys
import tomllib
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATEGORY_DIR = ROOT / "colorschemes"
REGISTRY = CATEGORY_DIR / "registry.json"

GH_API = "https://api.github.com"
RAW = "https://raw.githubusercontent.com"
USER_AGENT = "ryoku-omarchy-colorscheme-import/1.0"
DEFAULT_ORG = "HANCORE-linux"

# Canonical registry-row key order (extra keys, if any, are appended after these).
CANON_ORDER = ("id", "name", "provider", "path", "accent", "surface",
               "source", "preview", "dark", "light")

# Explicit fallback list of HANCORE-linux `omarchy-*-theme` repos, derived from the
# org README/repo listing. Used only when the GitHub API rate-limits enumeration.
FALLBACK_REPOS = [
    "omarchy-aamis-theme", "omarchy-batou-theme", "omarchy-blackgold-theme",
    "omarchy-blackmoney-theme", "omarchy-blackturq-theme", "omarchy-demon-theme",
    "omarchy-dos-moos-theme", "omarchy-greek-noir-theme", "omarchy-harbor-theme",
    "omarchy-harbordark-theme", "omarchy-inkypinky-theme", "omarchy-kanso-theme",
    "omarchy-lasthorizon-theme", "omarchy-mechanoonna-theme", "omarchy-moodpeak-theme",
    "omarchy-oxford-theme", "omarchy-oxocarbon-theme", "omarchy-roseofdune-theme",
    "omarchy-ryu-theme", "omarchy-saga-theme", "omarchy-sapphire-theme",
    "omarchy-shadesofjade-theme", "omarchy-solitude-theme", "omarchy-thegreek-theme",
    "omarchy-turbonite-theme", "omarchy-velvetnight-theme", "omarchy-whitegold-theme",
]


# --- HTTP -----------------------------------------------------------------

def http_get(url: str, accept: str | None = None, attempts: int = 3) -> bytes:
    headers = {"User-Agent": USER_AGENT}
    if accept:
        headers["Accept"] = accept
    if "api.github.com" in url and os.environ.get("GITHUB_TOKEN"):
        headers["Authorization"] = "Bearer " + os.environ["GITHUB_TOKEN"]
    last: Exception | None = None
    for i in range(attempts):
        try:
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req, timeout=60) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            # Do not retry client errors other than rate limiting.
            if e.code in (403, 429) or e.code >= 500:
                last = e
                continue
            raise
        except urllib.error.URLError as e:
            last = e
    assert last is not None
    raise last


class RateLimited(Exception):
    pass


# --- Color math -----------------------------------------------------------

def hex_to_rgb(h: str) -> tuple[int, int, int]:
    h = h.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def luma(h: str) -> float:
    r, g, b = hex_to_rgb(h)
    return 0.2126 * (r / 255) + 0.7152 * (g / 255) + 0.0722 * (b / 255)


def _round(x: float) -> int:
    # round half away from zero (channels are non-negative here)
    return int(math.floor(x + 0.5))


def mix(a: str, b: str, t: float) -> str:
    ra, rb = hex_to_rgb(a), hex_to_rgb(b)
    return "#" + "".join("%02x" % _round(ra[i] + (rb[i] - ra[i]) * t) for i in range(3))


# --- Conversion A ---------------------------------------------------------

def convert(colors: dict) -> tuple[str, dict]:
    """colors.toml dict -> (mode, Noctalia block with terminal sub-object)."""
    def col(i: int):
        return colors.get(f"color{i}")

    background = colors["background"]
    foreground = colors["foreground"]
    accent = colors.get("accent") or col(4)

    block = {
        "mPrimary": accent,
        "mOnPrimary": background,
        "mSecondary": col(2),
        "mOnSecondary": background,
        "mTertiary": col(3),
        "mOnTertiary": background,
        "mError": col(1),
        "mOnError": background,
        "mSurface": background,
        "mOnSurface": foreground,
        "mHover": accent,
        "mOnHover": background,
        "mSurfaceVariant": mix(background, col(8), 0.4),
        "mOnSurfaceVariant": col(7) or foreground,
        "mOutline": col(5),
        "mShadow": "#000000",
        "terminal": {
            "normal": {
                "black": col(0), "red": col(1), "green": col(2), "yellow": col(3),
                "blue": col(4), "magenta": col(5), "cyan": col(6), "white": col(7),
            },
            "bright": {
                "black": col(8), "red": col(9), "green": col(10), "yellow": col(11),
                "blue": col(12), "magenta": col(13), "cyan": col(14), "white": col(15),
            },
            "foreground": foreground,
            "background": background,
            "cursor": colors.get("cursor"),
            "selectionFg": colors.get("selection_foreground"),
            "selectionBg": colors.get("selection_background"),
        },
    }
    mode = "dark" if luma(background) < 0.5 else "light"
    return mode, block


# --- Naming ---------------------------------------------------------------

def slug_of(repo: str) -> str:
    s = repo
    if s.startswith("omarchy-"):
        s = s[len("omarchy-"):]
    if s.endswith("-theme"):
        s = s[: -len("-theme")]
    return s


def title_of(slug: str) -> str:
    return " ".join(w.capitalize() for w in slug.split("-"))


def kebab(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", name.strip().lower()).strip("-")


# --- Registry helpers -----------------------------------------------------

def load_registry() -> dict:
    if REGISTRY.exists():
        return json.loads(REGISTRY.read_text())
    return {"version": 1, "themes": []}


def write_registry(data: dict) -> None:
    REGISTRY.write_text(json.dumps(data, indent=2) + "\n")


def canonicalize(entry: dict) -> dict:
    out = {k: entry[k] for k in CANON_ORDER if k in entry}
    for k, v in entry.items():
        if k not in out:
            out[k] = v
    return out


def upsert(themes: list, row: dict) -> None:
    for i, e in enumerate(themes):
        if e.get("id") == row["id"]:
            themes[i] = row
            return
    themes.append(row)


def provider_for(entry: dict) -> str:
    """Provider for an existing scheme: honour per-scheme provenance if present,
    else fall back to the catalogue NOTICE (noctalia-dev)."""
    path = entry.get("path")
    if path:
        d = ROOT / path
        for fn in ("PROVENANCE.txt", "PROVENANCE", "NOTICE", "SOURCE", "source.txt"):
            f = d / fn
            if f.exists():
                txt = f.read_text(errors="ignore").lower()
                if "omarchy" in txt or "hancore" in txt:
                    return "HANCORE-linux"
                # Otherwise fall through to the noctalia default below.
                break
    return "Noctalia"


# --- Subcommands ----------------------------------------------------------

def do_backfill() -> int:
    data = load_registry()
    themes = data["themes"]
    filled = 0
    for i, e in enumerate(themes):
        block = e.get("dark") or e.get("light") or {}
        before = tuple(e.get(k) for k in ("id", "provider", "accent", "surface"))
        e.setdefault("id", kebab(e["name"]))
        e.setdefault("provider", provider_for(e))
        if block:
            e.setdefault("accent", block.get("mPrimary"))
            e.setdefault("surface", block.get("mSurface"))
        after = tuple(e.get(k) for k in ("id", "provider", "accent", "surface"))
        if before != after:
            filled += 1
        themes[i] = canonicalize(e)
    write_registry(data)
    print(f"backfilled {filled} entries ({len(themes)} total)")
    return filled


def enumerate_repos(org: str) -> list[dict]:
    repos: list[dict] = []
    page = 1
    try:
        while True:
            body = http_get(
                f"{GH_API}/users/{org}/repos?per_page=100&page={page}",
                accept="application/vnd.github+json",
            )
            arr = json.loads(body)
            if not isinstance(arr, list) or not arr:
                break
            repos.extend(arr)
            if len(arr) < 100:
                break
            page += 1
    except urllib.error.HTTPError as e:
        if e.code in (403, 429):
            raise RateLimited() from e
        raise
    return repos


def theme_repos(org: str) -> list[dict]:
    """Return [{name, default_branch}] for org's omarchy-*-theme repos."""
    try:
        repos = enumerate_repos(org)
        out = [
            {"name": r["name"], "default_branch": r.get("default_branch")}
            for r in repos
            if r.get("name", "").startswith("omarchy-") and r["name"].endswith("-theme")
        ]
        if out:
            return sorted(out, key=lambda r: r["name"])
    except RateLimited:
        print("! GitHub API rate-limited; using README fallback slug list",
              file=sys.stderr)
    return [{"name": n, "default_branch": None} for n in FALLBACK_REPOS]


def fetch_colors(org: str, repo: str, default_branch: str | None):
    cands: list[str] = []
    for b in ("master", "main", default_branch):
        if b and b not in cands:
            cands.append(b)
    last: Exception | None = None
    for b in cands:
        try:
            raw = http_get(f"{RAW}/{org}/{repo}/{b}/colors.toml")
            return b, tomllib.loads(raw.decode("utf-8"))
        except urllib.error.HTTPError as e:
            last = e
    raise RuntimeError(f"colors.toml not found for {repo} (tried {cands}): {last}")


def import_theme(org: str, repo: str, default_branch: str | None,
                 themes: list) -> tuple[str, str]:
    branch, colors = fetch_colors(org, repo, default_branch)
    mode, block = convert(colors)
    slug = slug_of(repo)
    tid = f"hancore-{slug}"
    rel = f"colorschemes/{tid}"

    # per-theme file (Noctalia on-disk convention: 4-space indent, single mode)
    dst_dir = ROOT / rel
    dst_dir.mkdir(parents=True, exist_ok=True)
    (dst_dir / f"{tid}.json").write_text(
        json.dumps({mode: block}, indent=4) + "\n"
    )

    row = {
        "id": tid,
        "name": title_of(slug),
        "provider": org,
        "path": rel,
        "accent": block["mPrimary"],
        "surface": block["mSurface"],
        "source": f"https://github.com/{org}/{repo}",
        "preview": f"{RAW}/{org}/{repo}/{branch}/preview.png",
        mode: block,
    }
    upsert(themes, canonicalize(row))
    return tid, mode


def do_all(org: str) -> tuple[int, int, int, list[str]]:
    data = load_registry()
    themes = data["themes"]
    reps = theme_repos(org)
    dark = light = 0
    ids: list[str] = []
    for r in reps:
        try:
            tid, mode = import_theme(org, r["name"], r.get("default_branch"), themes)
        except Exception as e:  # noqa: BLE001 - report and continue
            print(f"! skip {r['name']}: {e}", file=sys.stderr)
            continue
        ids.append(tid)
        if mode == "dark":
            dark += 1
        else:
            light += 1
        print(f"  imported {tid} ({mode})")
    write_registry(data)
    print(f"imported {len(ids)} themes ({dark} dark, {light} light); "
          f"registry now {len(themes)} entries")
    return len(ids), dark, light, sorted(ids)


GOLDEN_EXPECT = {
    "mPrimary": "#ADF0E9",
    "mSurface": "#0a0a0a",
    "mOnSurface": "#c8dcdc",
    "mSecondary": "#8FECD5",
    "mTertiary": "#A9D1D7",
    "mError": "#D35F5F",
    "mOutline": "#485362",
}


def do_golden(org: str) -> bool:
    repo = "omarchy-blackturq-theme"
    _branch, colors = fetch_colors(org, repo, None)
    mode, block = convert(colors)
    ok = True
    checks = list(GOLDEN_EXPECT.items())
    checks.append(("terminal.normal.blue", "#ADF0E9"))
    for key, want in checks:
        if key.startswith("terminal."):
            _, sub, name = key.split(".")
            got = block["terminal"][sub][name]
        else:
            got = block[key]
        mark = "ok" if got == want else "MISMATCH"
        if got != want:
            ok = False
        print(f"  {key:24s} want {want:9s} got {got:9s} [{mark}]")
    print(f"  mode = {mode}")
    print("GOLDEN CHECK:", "PASS" if ok else "FAIL")
    return ok


# --- CLI ------------------------------------------------------------------

def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--backfill", action="store_true",
                    help="add id/provider/accent/surface to existing entries")
    ap.add_argument("--all", metavar="ORG",
                    help="import all omarchy-*-theme repos from ORG")
    ap.add_argument("--golden", action="store_true",
                    help="run the blackturq golden conversion check")
    ap.add_argument("--org", default=DEFAULT_ORG,
                    help=f"org for --golden / raw URLs (default {DEFAULT_ORG})")
    args = ap.parse_args(argv)

    if not (args.backfill or args.all or args.golden):
        ap.print_help()
        return 2

    if args.backfill:
        do_backfill()
    if args.all:
        do_all(args.all)
    if args.golden:
        if not do_golden(args.org):
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
