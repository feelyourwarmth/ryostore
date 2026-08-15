# Ryoku plugins

Shell plugins for Ryoku. Each plugin is a self-contained folder the shell installs as a
receipt-owned product (its files are fetched and SHA-verified per `product-manifest.json`)
and loads from Settings → Plugins.

## Folder layout

```
plugins/
  registry.json        # the installable list (see below)
  AUTHORING.md         # how to build a frame plugin
  template/            # minimal example - copy it to start
  photo-frame/         # the worked example
    manifest.json      # id, version, entry points, host placement
    README.md          # required; embeds assets/preview-widget.png
    assets/preview-widget.png
    service/Main.qml   # main entry point: persistent logic
    content/Widget.qml # content entry point: the adaptive view
    content/PhotoFrame.qml
```

## How registry.json works

`registry.json` is the catalogue the shell reads. It has two arrays: `plugins`, the
installable list, and `archived`, retired plugins kept for reference. Entries share one
shape:

```json
{
  "id": "my-plugin",
  "name": "My Plugin",
  "path": "plugins/my-plugin",
  "version": "1.0.0",
  "author": "Ryoku Team",
  "description": "One sentence shown in the catalogue.",
  "tags": ["frame"],
  "official": true,
  "lastUpdated": "2026-06-06"
}
```

A plugin folder is offered in Settings only while its entry is in `plugins`. Moving an entry
to `archived` retires it: the folder stays in the repo but the shell stops listing it.

## Contributing

Copy `template/` and read [`AUTHORING.md`](AUTHORING.md) for the full guide.
