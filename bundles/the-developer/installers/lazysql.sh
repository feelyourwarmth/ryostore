#!/bin/bash

# lazysql: Terminal UI database client.
# Upstream: https://github.com/jorgerojas26/lazysql

set -euo pipefail

if ryoku-cmd-present lazysql; then
  echo "lazysql: already installed"
  exit 0
fi

GOBIN="$HOME/.local/bin" go install github.com/jorgerojas26/lazysql@latest
