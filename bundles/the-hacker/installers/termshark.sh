#!/bin/bash

# termshark: Terminal UI for tshark.
# Upstream: https://github.com/gcla/termshark

set -euo pipefail

if ryoku-cmd-present termshark; then
  echo "termshark: already installed"
  exit 0
fi

GOBIN="$HOME/.local/bin" go install github.com/gcla/termshark/v2/cmd/termshark@latest
