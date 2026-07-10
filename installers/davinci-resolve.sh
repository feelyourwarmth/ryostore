#!/bin/bash

# davinci-resolve: DaVinci Resolve (Free) via the AUR package.
# Upstream: https://www.blackmagicdesign.com/products/davinciresolve
#
# Resolve is proprietary and its EULA forbids redistribution, so it CANNOT be
# bundled or auto-downloaded (the AUR PKGBUILD requires the installer .zip you
# download yourself from Blackmagic). This is an interactive fetch: it opens the
# download page, waits for the .zip, then builds the AUR package. If you exit
# before the .zip is present, the Hub marks it "needs a manual download" and you
# can re-run this item when ready.
#
# Note: the free Linux build cannot import H.264/H.265 + AAC. Use the Creator
# "Transcode for DaVinci (DNxHR)" right-click action first.

set -euo pipefail

if ryoku-cmd-present davinci-resolve || [ -x /opt/resolve/bin/resolve ]; then
  echo "davinci-resolve: already installed"
  exit 0
fi

echo "==> DaVinci Resolve (Free) is a manual, one-time download from Blackmagic."
echo "    It is proprietary and cannot be auto-installed."

# base-devel + git are needed to build the AUR package.
ryoku-cmd-present git || ryoku-pkg-add git
ryoku-cmd-present makepkg || ryoku-pkg-add base-devel

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
echo "==> Fetching the davinci-resolve AUR build files..."
git clone --depth 1 https://aur.archlinux.org/davinci-resolve.git "$work/davinci-resolve"
cd "$work/davinci-resolve"

pkgver="$(sed -n 's/^pkgver=//p' PKGBUILD | head -1)"
zip_name="$(sed -n 's/.*\(DaVinci_Resolve_[^"'"'"' ]*\.zip\).*/\1/p' PKGBUILD | head -1)"
[ -n "$zip_name" ] || zip_name="DaVinci_Resolve_${pkgver}_Linux.zip"

echo ""
echo "    1. A browser is opening the Blackmagic download page."
echo "    2. Download the FREE 'DaVinci Resolve for Linux' (version ${pkgver:-latest})."
echo "    3. Save the .zip to ~/Downloads (expected name: ${zip_name})."
echo ""
command -v xdg-open >/dev/null && xdg-open "https://www.blackmagicdesign.com/products/davinciresolve" >/dev/null 2>&1 || true

found=""
for _ in $(seq 1 60); do
  for cand in "$HOME/Downloads/$zip_name" "$HOME/Downloads/"DaVinci_Resolve_*Linux.zip "$PWD/$zip_name"; do
    if [ -f "$cand" ]; then
      found="$cand"
      break 2
    fi
  done
  printf '\r    Waiting for the .zip in ~/Downloads (Ctrl-C to finish later)... '
  sleep 10
done
echo ""

if [ -z "$found" ]; then
  echo "davinci-resolve: no installer .zip found yet. Download it, then re-run this item."
  exit 0
fi

echo "==> Found $found"
cp -f "$found" "$PWD/$(basename "$found")"
# the local .zip is user-provided; regenerate the checksum so makepkg accepts it.
command -v updpkgsums >/dev/null && updpkgsums || true
echo "==> Building and installing (this takes a while; enter your password if asked)..."
makepkg -si --noconfirm
