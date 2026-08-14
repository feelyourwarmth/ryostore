# Bundles

A bundle is a named set of tools you install together: packages, small installer
scripts, and (later) Ryoku plugins. The Hub's Extras section lists every bundle
here and installs it, or individual items, with one click, backed by
`ryostore-install`.

Each bundle lives in its own folder under `bundles/<id>/` with a `bundle.json`.
The top-level `registry.json` is the index the Hub reads to discover them.

## `registry.json`

```jsonc
{
  "version": 1,
  "bundles": [
    {
      "id": "the-ricer",                 // matches the folder name and bundle.json id
      "name": "The Ricer",               // display name
      "description": "...",              // one-line blurb for the card
      "sources": "pacman / AUR",         // where its items come from, for the card label
      "path": "bundles/the-ricer"
    }
  ]
}
```

## `bundle.json`

```jsonc
{
  "id": "the-ricer",
  "name": "The Ricer",
  "description": "Eye-candy and theming tools that don't ship with Ryoku by default.",
  "requires": ["multilib"],              // optional: repos to enable before installing
  "items": [
    { "type": "package", "name": "gpick", "detect": "gpick",
      "summary": "GTK color picker.", "source": "official", "upstream": "https://..." },
    { "type": "script", "name": "ffuf", "detect": "ffuf",
      "summary": "Fast web fuzzer.", "source": "go", "upstream": "https://..." }
  ]
}
```

Each item has a `type`, a `name`, an optional one-line `summary`, an optional
`source` and `upstream` (shown on the card), and a `detect` command:

- **`package`** a pacman/AUR package. `ryostore-install` routes it
  automatically: a package that resolves with `pacman -Si` installs from the
  official repos via `ryoku-pkg-add`, the rest from the AUR via
  `ryoku-pkg-aur-add`, so you only ever write the package name. Presence is
  decided by `pacman -Qq <name>`; `detect` just documents the command the package
  provides. Repo packages are batched into one install and AUR packages into
  another; anything already present is skipped.
- **`script`** installed by running `bundles/<id>/installers/<name>.sh` (see
  [`installers/README.md`](../installers/README.md)). `detect` is the command the script produces, and the
  item is present when that command is on `PATH`.
- **`plugin`** installed through the shell's plugin path, not this command. The
  actuator marks it deferred; install it from the Plugins tab.

`requires` lists prerequisites the actuator satisfies before a bundle's packages
are routed, each idempotent and safe to repeat:

- `multilib` enables the `[multilib]` repo (Steam and every `lib32-` package
  live there).
- `cachyos` adds the `[cachyos-v3]` repo (the CachyOS Kernel bundle).
- `gpu-lib32` runs `ryoku-gpu-lib32` to install the 32-bit GPU drivers matching
  the machine (Gaming lists it after `multilib`, so the repo is on first).

An unrecognised requirement aborts with a "run ryoku update" message rather than
mis-routing the bundle's packages.

## How installs run

Installs are per item with real feedback:

- The Extras section runs `ryostore-install` inside a **floating terminal** so
  the `sudo` and AUR prompts have a TTY; package installs cannot complete from a
  silent background process. You watch progress there and type your password if
  asked.
- The command writes a per-bundle JSON report
  (`$XDG_RUNTIME_DIR/ryostore/<id>.json`) with each item's `status`
  (`present` | `installing` | `installed` | `removing` | `removed` | `absent` |
  `failed` | `deferred` | `skipped`) that the Hub watches to drive per-item state.
  `ryostore-install status bundle <id>` reports presence without changing
  anything.
- **Uninstall all** (or a single tool) removes the bundle's package items with
  `ryoku-pkg-remove`. Scripts are not auto-removed; plugins are removed from the
  Plugins tab.

## Tiers, interactive items, code guests, and imagery

Each item may set `"tier": "core"` (default) or `"tier": "optional"`. **Install
all** installs only core items; optional items install one at a time from the
card. A `script` item may set `"interactive": true` when it needs the user to
act (for example a manual download that cannot be automated); an aborted
interactive install reports as *deferred*, not *failed*.

A bundle can also ship its own code as guests, all living in this repo:

- `{ "type": "plugin", "name": "<id>" }` a shell plugin from `plugins/<id>/`
  (see [`plugins/AUTHORING.md`](../plugins/AUTHORING.md)): a desktop widget or a
  frame popout, enabled and placed from Settings.
- `{ "type": "nautilus-pack", "name": "<id>" }` a right-click file-manager
  script pack from `nautilus/<id>/` (see
  [`nautilus/AUTHORING.md`](../nautilus/AUTHORING.md)).

Store imagery: a bundle carries `"icon"` (a Material glyph name), `"accent"` (a
hex colour), `"preview"` (a hero image), and `"screenshots": [...]`, all
relative to `bundles/<id>/assets/`. The Hub resolves them to absolute URLs when
it builds the catalogue.
