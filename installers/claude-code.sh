#!/bin/bash

# Worked example of the curl/script install method. Pulls Claude Code from the
# official Anthropic installer: https://claude.ai/install.sh
# Not part of any bundle; copy this as a template for new script installers.

set -euo pipefail

if ryoku-cmd-present claude; then
  echo "claude-code: already installed"
  exit 0
fi

curl -fsSL https://claude.ai/install.sh | bash
