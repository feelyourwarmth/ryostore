# Installers

Small, auditable scripts for tools that don't come from pacman/AUR - the curl-into-shell
pattern, pinned to an official upstream. A bundle references one with a `script` item and
`ryoku-extras-install` runs it when the tool is missing.

`claude-code.sh` is the worked example.

## Adding an installer

1. Create `installers/<name>.sh`. `<name>` is the bundle item name without the `.sh`.
2. Start with `#!/bin/bash` and `set -euo pipefail`.
3. Name the official source URL in a header comment so the script stays auditable.
4. Be idempotent: detect first, and exit `0` early when the tool is already present.

   ```bash
   if ryoku-cmd-present <command>; then
     echo "<name>: already installed"
     exit 0
   fi
   ```

5. Install from the official upstream. Let failures surface - `set -e` plus a non-zero exit
   tells the installer the item failed.

## Referencing it from a bundle

Add a `script` item to the bundle's `bundle.json`:

```jsonc
{ "type": "script", "name": "claude-code", "detect": "claude", "summary": "Anthropic CLI." }
```

- `name` matches the script filename without `.sh` (`claude-code` → `installers/claude-code.sh`).
- `detect` is the command the script produces; the installer skips the item when it already
  exists.
