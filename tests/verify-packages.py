#!/usr/bin/env python3
"""Check every bundle package item still exists in the source it declares.

validate-catalogue.sh proves the catalogue is internally consistent: the registry
points at a manifest, the manifest points at files that exist. Nothing checked
that a package name is still real, so a rename or a drop upstream shipped a
bundle that fails on the user's machine. That is how cemu sat in the gaming
bundle flagged out-of-date, and how `proton-cachyos` became unresolvable after
CachyOS split it into -slr and -native.

Checks per declared source:
  official  -> exists in an Arch repo (core/extra/multilib)
  aur       -> exists in the AUR, is maintained, and is not flagged out-of-date
  cachyos   -> exists in the CachyOS repo

A package found only in a source other than the one declared is an error too:
the installer routes on that field, so a wrong value sends pacman after an AUR
package or an AUR helper after a repo package.

Upstream being unreachable is NOT an error. This gate must not block a merge
because someone else's server is down; it reports and skips.
"""

from __future__ import annotations

import json
import pathlib
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
UA = {"User-Agent": "ryoku-store-package-gate/1.0"}
OFFICIAL_REPOS = {"core", "extra", "multilib"}
CACHYOS_DB = "https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos.db.tar.zst"


class Unreachable(Exception):
    pass


def get_json(url: str) -> object:
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30) as r:
            return json.loads(r.read())
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, OSError) as e:
        raise Unreachable(str(e)) from e


def arch_repos(name: str) -> set[str]:
    q = urllib.parse.urlencode({"name": name})
    data = get_json(f"https://archlinux.org/packages/search/json/?{q}")
    return {r["repo"] for r in data.get("results", []) if isinstance(r, dict)}


def aur_info(names: list[str]) -> dict[str, dict]:
    out: dict[str, dict] = {}
    for i in range(0, len(names), 40):
        chunk = names[i : i + 40]
        q = "&".join(f"arg[]={urllib.parse.quote(n)}" for n in chunk)
        data = get_json(f"https://aur.archlinux.org/rpc/?v=5&type=info&{q}")
        for r in data.get("results", []):
            out[r["Name"]] = r
    return out


def cachyos_packages() -> set[str]:
    try:
        with urllib.request.urlopen(urllib.request.Request(CACHYOS_DB, headers=UA), timeout=60) as r:
            blob = r.read()
    except (urllib.error.URLError, TimeoutError, OSError) as e:
        raise Unreachable(str(e)) from e
    with tempfile.NamedTemporaryFile(suffix=".tar.zst") as tmp:
        tmp.write(blob)
        tmp.flush()
        p = subprocess.run(["tar", "--zstd", "-tf", tmp.name], capture_output=True, text=True)
    if p.returncode != 0:
        raise Unreachable(f"tar --zstd failed: {p.stderr.strip()[:120]}")
    names = set()
    for line in p.stdout.splitlines():
        head = line.split("/", 1)[0]
        if head:
            names.add(head.rsplit("-", 2)[0])
    return names


def collect() -> list[tuple[str, str, str]]:
    """(bundle, package name, declared source) for every package item."""
    rows = []
    for manifest in sorted(ROOT.glob("bundles/*/bundle.json")):
        data = json.loads(manifest.read_text())
        for item in data.get("items", []):
            if item.get("type") != "package":
                continue
            rows.append((manifest.parent.name, item.get("name", ""), item.get("source", "")))
    return rows


def main() -> int:
    rows = collect()
    if not rows:
        print("verify-packages: no package items found", file=sys.stderr)
        return 1

    names = sorted({n for _, n, _ in rows})
    skipped: list[str] = []

    try:
        aur = aur_info(names)
    except Unreachable as e:
        skipped.append(f"AUR unreachable ({e})")
        aur = None

    try:
        cachy = cachyos_packages() if any(s == "cachyos" for _, _, s in rows) else set()
    except Unreachable as e:
        skipped.append(f"CachyOS repo unreachable ({e})")
        cachy = None

    arch: dict[str, set[str]] | None = {}
    for n in names:
        try:
            arch[n] = arch_repos(n)
        except Unreachable as e:
            skipped.append(f"archlinux.org unreachable ({e})")
            arch = None
            break

    errors: list[str] = []
    for bundle, name, source in rows:
        label = f"bundles/{bundle}: {name}"
        in_arch = bool(arch and (arch.get(name, set()) & OFFICIAL_REPOS))
        in_aur = bool(aur and name in aur)
        in_cachy = bool(cachy and name in cachy)

        if source == "official":
            if arch is None:
                continue
            if not in_arch:
                where = "the AUR" if in_aur else ("the CachyOS repo" if in_cachy else "nowhere")
                errors.append(f"{label}: declared official but found in {where}")
        elif source == "aur":
            if aur is None:
                continue
            if in_arch:
                errors.append(f"{label}: declared aur but is an official package now")
            elif not in_aur:
                errors.append(f"{label}: not in the AUR")
            else:
                info = aur[name]
                if not info.get("Maintainer"):
                    errors.append(f"{label}: orphaned in the AUR")
                if info.get("OutOfDate"):
                    errors.append(f"{label}: flagged out-of-date in the AUR")
        elif source == "cachyos":
            if cachy is None:
                continue
            if not in_cachy:
                where = "an Arch repo" if in_arch else ("the AUR" if in_aur else "nowhere")
                errors.append(f"{label}: declared cachyos but found in {where}")
        else:
            errors.append(f"{label}: unknown source {source!r}")

    for note in dict.fromkeys(skipped):
        print(f"verify-packages: skipped a check, {note}", file=sys.stderr)
    if errors:
        for e in errors:
            print(f"FAIL: {e}", file=sys.stderr)
        print(f"{len(errors)} package error(s) found", file=sys.stderr)
        return 1
    checked = sum(
        1
        for _, _, source in rows
        if (source == "official" and arch is not None)
        or (source == "aur" and aur is not None)
        or (source == "cachyos" and cachy is not None)
    )
    if checked == 0:
        print(f"packages SKIPPED: nothing could be checked, all {len(rows)} items unverified")
    elif checked < len(rows):
        print(f"packages OK: {checked} of {len(rows)} bundle items verified, {len(rows) - checked} skipped")
    else:
        print(f"packages OK: all {len(rows)} bundle items resolve to their declared source")
    return 0


if __name__ == "__main__":
    sys.exit(main())
