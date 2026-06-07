# Bundles

A bundle is a named set of tools you install together - packages, small installer scripts,
and Ryoku plugins. The Extras tab in Settings lists every bundle here and installs it (or
individual items) with one click, backed by `ryoku-extras-install`.

Each bundle lives in its own folder under `bundles/<id>/` with a `bundle.json`. The top-level
`registry.json` is the index the shell reads to discover them.

## `registry.json`

```jsonc
{
  "version": 1,
  "bundles": [
    {
      "id": "the-ricer",        // matches the folder name and bundle.json id
      "name": "The Ricer",      // display name
      "description": "...",     // one-line blurb for the card
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
  "items": [
    { "type": "package", "name": "cmatrix",   "detect": "cmatrix",   "summary": "Matrix rain screensaver." },
    { "type": "script",  "name": "claude-code", "detect": "claude",  "summary": "Anthropic CLI." },
    { "type": "plugin",  "name": "wallhaven",  "summary": "Wallhaven frame popout." }
  ]
}
```

Each item has a `type`, a `name`, an optional one-line `summary`, and (for packages and
scripts) a `detect` command used to tell whether it is already installed:

- **`package`** - installed via `ryoku-pkg-add` (handles pacman + AUR). `detect` is the
  command that proves it is present; it defaults to `name`. Already-installed packages are
  skipped, and missing ones across the whole bundle are deduped into a single install call.
- **`script`** - installed by running `installers/<name>.sh` (the curl pattern; see
  `installers/README.md`). `detect` is the command the script produces.
- **`plugin`** - installed through the shell's plugin install path, not by this command. The
  installer prints a pointer to **Settings → Plugins** instead.

`detect` and `summary` are optional; the installer tolerates their absence.
