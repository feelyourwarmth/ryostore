#!/bin/bash

# httpx: Fast HTTP probing toolkit.
# Upstream: https://github.com/projectdiscovery/httpx

set -euo pipefail

if ryoku-cmd-present httpx; then
  echo "httpx: already installed"
  exit 0
fi

GOBIN="$HOME/.local/bin" go install github.com/projectdiscovery/httpx/cmd/httpx@latest
