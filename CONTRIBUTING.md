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

Each item declares a `type`, and may carry a one-line `summary`, a `source`, and an
`upstream` (shown on the card):

- `package` - a pacman/AUR package. `ryoku-extras-install` routes it automatically (official
  repos via `ryoku-pkg-add`, otherwise the AUR via `ryoku-pkg-aur-add`), so you only write
  the package name. Presence is decided by `pacman -Qq`; `detect` documents the command it
  provides.
- `script` - installed by running `bundles/<id>/installers/<name>.sh`. `detect` is the resulting command.
- `plugin` - installed through the shell's plugin path; `name` is the plugin id.

A bundle may also declare `"requires": ["multilib"]` to enable a repo before its packages
are routed (Gaming needs it for Steam and the 32-bit libraries).

See `bundles/the-ricer/` for the worked example.

## An installer script

For tools that install via a curl/script rather than a package, add
`bundles/<id>/installers/<name>.sh` inside the bundle that owns it. Keep it small
and auditable, pin the upstream URL, and use the Ryoku helpers
(`ryoku-cmd-present`, `ryoku-pkg-add`) rather than raw shell. A `script` bundle
item points at it by name. See `installers/README.md`.

## A Nautilus script pack

Right-click file-manager actions live in `nautilus/<id>/`. Copy the layout in
[`nautilus/AUTHORING.md`](nautilus/AUTHORING.md), list the pack in
`nautilus/registry.json`, and a bundle references it with an item
`{ "type": "nautilus-pack", "name": "<id>" }`. The scripts install to
`~/.local/share/nautilus/scripts/<subdir>/` and are removed cleanly on uninstall.

## Before you open a PR

Run the catalogue check:

```
tests/validate-catalogue.sh
```

It confirms every bundle item resolves to a real registry entry, manifest, and
installer, that each Nautilus manifest matches the scripts on disk, and that all
JSON parses, so a dangling reference never reaches a user as a failed install. CI
runs the same check on every push and pull request.
