# ryoku-extras

Downloadable content for the Ryoku desktop. Each subdirectory is an
independent catalogue the shell fetches on demand:

- `colorschemes/` - color schemes (Settings -> Color scheme -> Download)
- `livewalls/` - live (video) wallpapers (ryowalls -> Ryoku source). Posters live
  here; the clips are Release assets. See [`livewalls/README.md`](livewalls/README.md).
- `plugins/` - shell plugins: desktop widgets and frame popouts (Settings -> Plugins). See
  [`plugins/AUTHORING.md`](plugins/AUTHORING.md).
- `bundles/` - extras bundles: curated sets of packages, scripts, and plugins
  installed together (Settings -> Extras).
- `installers/` - small, auditable scripts for the curl/script install method that
  bundles can reference.

Each catalogue keeps a `registry.json` listing its items; add or remove an item by
editing it and committing.

Contributing a plugin, bundle, or installer? See [`CONTRIBUTING.md`](CONTRIBUTING.md).
