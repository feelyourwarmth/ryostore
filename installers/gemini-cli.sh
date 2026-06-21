#!/bin/bash

# gemini-cli: Google Gemini terminal agent.
# Upstream: https://github.com/google-gemini/gemini-cli

set -euo pipefail

if ryoku-cmd-present gemini; then
  echo "gemini-cli: already installed"
  exit 0
fi

npm install -g --prefix="$HOME/.local" @google/gemini-cli
