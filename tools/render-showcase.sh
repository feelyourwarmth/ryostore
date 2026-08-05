#!/usr/bin/env bash
# Render the eye-candy showcase covers for placeholder products and repair the
# manifest + registry hashes. Run from anywhere; the catalogue root is the
# parent of this tools/ directory unless --root is passed.
#
#   tools/render-showcase.sh                 # every motif category
#   tools/render-showcase.sh --categories rices,bundles
#
# Requires python3 with Pillow and numpy. Deterministic: re-running produces
# byte-identical covers, so a clean tree stays clean.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
exec python3 "$here/render-showcase.py" --root "$root" "$@"
