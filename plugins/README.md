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
`wallhaven` lives there now.

## Contributing

Copy `template/` and read [`AUTHORING.md`](AUTHORING.md) for the full guide.
