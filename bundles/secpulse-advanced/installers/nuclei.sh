#!/bin/bash

# nuclei: Template-based vulnerability scanner.
# Upstream: https://github.com/projectdiscovery/nuclei

set -euo pipefail

if ryoku-cmd-present nuclei; then
  echo "nuclei: already installed"
  exit 0
fi

GOBIN="$HOME/.local/bin" go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
