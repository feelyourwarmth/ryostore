#!/bin/bash

# subfinder: Passive subdomain discovery.
# Upstream: https://github.com/projectdiscovery/subfinder

set -euo pipefail

if ryoku-cmd-present subfinder; then
  echo "subfinder: already installed"
  exit 0
fi

GOBIN="$HOME/.local/bin" go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
