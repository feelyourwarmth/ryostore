# Installers

Small, auditable scripts for tools that don't come from pacman/AUR: the curl, npm,
go, cargo, and pipx install paths, each pinned to an official upstream. A bundle
references one with a `script` item, and `ryoku-extras-install` runs it when the
tool is missing.

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

5. Install into `~/.local/bin` without root. Installers run under bash, which does
   not carry the interactive shell's environment, so set the destination
   explicitly:

   - npm: `npm install -g --prefix="$HOME/.local" <pkg>`
   - go: `GOBIN="$HOME/.local/bin" go install <module>@latest`
   - cargo: `cargo install --root "$HOME/.local" <crate>`
   - pipx: `pipx install <pkg>` (pipx already targets `~/.local/bin`)
   - curl: the vendor's own installer, when `~/.local/bin` is its documented target

6. Let failures surface: `set -e` plus a non-zero exit tells the actuator the item
   failed.

## Referencing it from a bundle

Add a `script` item to the bundle's `bundle.json`:

```jsonc
{ "type": "script", "name": "claude-code", "detect": "claude", "summary": "Anthropic CLI.",
  "source": "curl", "upstream": "https://github.com/anthropics/claude-code" }
```

- `name` matches the script filename without `.sh` (`claude-code` -> `installers/claude-code.sh`).
- `detect` is the command the script produces; the actuator skips the item when that
  command is already on `PATH`.
