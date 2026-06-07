# Ryoku plugins

Shell plugins for Ryoku. Each plugin is a self-contained folder the shell git-clones from
this repo and loads from Settings → Plugins.

## Folder layout

```
plugins/
  registry.json        # the installable list (see below)
  AUTHORING.md         # how to build a frame plugin
  template/            # minimal example - copy it to start
  wallhaven/           # the worked example
    manifest.json      # id, version, entry points, frame placement
    README.md          # required; embeds assets/preview.gif
    assets/preview.gif
    service/Main.qml   # main entry point: persistent logic
    ui/Panel.qml       # framePanel entry point: the popout
    ui/Settings.qml    # settings entry point (optional)
    bin/...            # any commands the plugin ships
```

## How registry.json works

`registry.json` is the catalogue the shell reads. Every installable plugin has one entry:

```json
{
  "id": "wallhaven",
  "name": "Wallhaven",
  "path": "plugins/wallhaven",
  "version": "1.0.0",
  "author": "Ryoku Team",
  "description": "Browse wallhaven.cc and set wallpapers from the top-right frame corner.",
  "tags": ["wallpaper", "frame"],
  "official": true,
  "lastUpdated": "2026-06-06"
}
```

A plugin folder is not offered in Settings until it is listed here.

## Contributing

Copy `template/` and read [`AUTHORING.md`](AUTHORING.md) for the full guide.
