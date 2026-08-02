#!/bin/bash

# codex: OpenAI terminal coding agent.
# Upstream: https://github.com/openai/codex

set -euo pipefail

if ryoku-cmd-present codex; then
  echo "codex: already installed"
  exit 0
fi

npm install -g --prefix="$HOME/.local" @openai/codex
