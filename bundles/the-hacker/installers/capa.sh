#!/bin/bash

# capa: Identifies capabilities in executables.
# Upstream: https://github.com/mandiant/capa

set -euo pipefail

if ryoku-cmd-present capa; then
  echo "capa: already installed"
  exit 0
fi

pipx install flare-capa
