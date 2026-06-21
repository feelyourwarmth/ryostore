#!/bin/bash

# ffuf: Fast web fuzzer.
# Upstream: https://github.com/ffuf/ffuf

set -euo pipefail

if ryoku-cmd-present ffuf; then
  echo "ffuf: already installed"
  exit 0
fi

GOBIN="$HOME/.local/bin" go install github.com/ffuf/ffuf/v2@latest
