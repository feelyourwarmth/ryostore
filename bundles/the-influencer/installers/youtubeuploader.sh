#!/bin/bash

# youtubeuploader: Scripted YouTube uploads.
# Upstream: https://github.com/porjo/youtubeuploader

set -euo pipefail

if ryoku-cmd-present youtubeuploader; then
  echo "youtubeuploader: already installed"
  exit 0
fi

GOBIN="$HOME/.local/bin" go install github.com/porjo/youtubeuploader/cmd/youtubeuploader@latest
