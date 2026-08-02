#!/bin/bash

# opencode: Open source terminal coding agent.
# Upstream: https://github.com/sst/opencode

set -euo pipefail

if ryoku-cmd-present opencode; then
  echo "opencode: already installed"
  exit 0
fi

npm install -g --prefix="$HOME/.local" opencode-ai
