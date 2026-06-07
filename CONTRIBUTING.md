# Contributing to ryoku-extras

This repo is a set of catalogues. Every catalogue has a `registry.json` that lists what is
installable; an item is invisible to the shell until it is listed there. Add your folder,
add the registry entry, open a PR.

## A color scheme

Add a folder under `colorschemes/<name>/` and an entry to `colorschemes/registry.json`.
Follow an existing scheme for the file layout.

## A plugin

Plugins live in `plugins/<id>/`. Copy `plugins/template/` to start, then read
[`plugins/AUTHORING.md`](plugins/AUTHORING.md) for the full guide - it covers the manifest,
the three entry points, how the shell hosts your frame popout, settings persistence, and
the README + GIF requirements. List the plugin in `plugins/registry.json` when it is ready.

## A bundle

A bundle installs a curated set of packages, scripts, and plugins together. Add:

1. `bundles/<id>/bundle.json` - the full item list and metadata.
2. `bundles/<id>/README.md` - what it installs and why.
3. An entry in `bundles/registry.json`.

Each item declares a `type`:

- `package` - installed with `ryoku-pkg-add` (pacman + AUR). `detect` is the command that
  proves it is already present.
- `script` - installed by running `installers/<name>.sh`. `detect` is the resulting command.
- `plugin` - installed through the shell's plugin path; `name` is the plugin id.

See `bundles/the-ricer/` for the worked example.

## An installer script

For tools that install via a curl/script rather than a package, add
`installers/<name>.sh`. Keep it small and auditable, pin the upstream URL, and use the
Ryoku helpers (`ryoku-cmd-present`, `ryoku-pkg-add`) rather than raw shell. A `script`
bundle item points at it by name. See `installers/README.md`.
