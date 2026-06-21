#!/bin/bash

# claude-code: Anthropic terminal coding agent.
# Upstream: https://github.com/anthropics/claude-code

set -euo pipefail

if ryoku-cmd-present claude; then
  echo "claude-code: already installed"
  exit 0
fi

curl -fsSL https://claude.ai/install.sh | bash
