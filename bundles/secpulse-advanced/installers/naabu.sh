#!/bin/bash

# naabu: Fast Go port scanner.
# Upstream: https://github.com/projectdiscovery/naabu

set -euo pipefail

if ryoku-cmd-present naabu; then
  echo "naabu: already installed"
  exit 0
fi

GOBIN="$HOME/.local/bin" go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
