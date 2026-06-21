#!/bin/bash

# aider: Terminal pair programmer over git.
# Upstream: https://aider.chat

set -euo pipefail

if ryoku-cmd-present aider; then
  echo "aider: already installed"
  exit 0
fi

pipx install aider-chat
