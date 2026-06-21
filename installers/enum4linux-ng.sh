#!/bin/bash

# enum4linux-ng: SMB and Windows host enumeration.
# Upstream: https://github.com/cddmp/enum4linux-ng

set -euo pipefail

if ryoku-cmd-present enum4linux-ng; then
  echo "enum4linux-ng: already installed"
  exit 0
fi

pipx install git+https://github.com/cddmp/enum4linux-ng.git
