#!/bin/bash

# capture-website-cli: Render a URL or HTML to an image.
# Upstream: https://github.com/sindresorhus/capture-website-cli

set -euo pipefail

if ryoku-cmd-present capture-website; then
  echo "capture-website-cli: already installed"
  exit 0
fi

npm install -g --prefix="$HOME/.local" capture-website-cli
