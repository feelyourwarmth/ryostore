# Writing a frame plugin

A frame plugin adds a popout that slides in when you hover a corner of the screen frame.
You write two things — a service and a panel — and tell the shell which corner to use. The
shell does the hover detection, the slide animation, the focus and keyboard grab, and the
input region. You never touch any of that.

`plugins/wallhaven/` is the worked example throughout this guide. `plugins/template/` is
the smallest possible version — copy it to start.

## Quickstart

```
cp -r plugins/template plugins/my-plugin
```

1. Edit `plugins/my-plugin/manifest.json`: set `id` to `my-plugin`, pick a `name`,
   `author`, `description`, and the `frame` corner.
2. Rewrite `service/Main.qml` and `ui/Panel.qml`.
3. Replace `assets/preview.gif` and rewrite `README.md`.
4. Add an entry to `plugins/registry.json` so it shows up in Settings.

## The manifest

`manifest.json` describes the plugin. Required fields: `id`, `name`, `version` (x.y.z),
`author`, `description`, `entryPoints`. The rest are optional.

| Field                       | What it is                                                        |
| --------------------------- | ---------------------------------------------------------------- |
| `id`                        | Folder name and unique key. Lowercase, no spaces.                 |
| `name`                      | Display name in Settings.                                         |
| `version`                   | `x.y.z`. Bump it when you publish a change.                       |
| `author`                    | `Name <email>`.                                                   |
| `description`               | One sentence shown in the catalogue.                             |
| `license`                   | SPDX id, e.g. `MIT`.                                              |
| `tags`                      | Strings for filtering, e.g. `["wallpaper", "frame"]`.            |
| `entryPoints`               | The QML files the shell loads (see below).                       |
| `frame`                     | Where the popout lives (see below).                              |
| `commands`                  | Executables the plugin ships, e.g. `["bin/ryoku-foo"]`.         |
| `dependencies.commands`     | Commands that must be present on the system.                     |
| `metadata.defaultSettings`  | The settings object and its starting values.                    |

## The three entry points

```json
"entryPoints": {
  "main": "service/Main.qml",
  "framePanel": "ui/Panel.qml",
  "settings": "ui/Settings.qml"
}
```

- **`main`** — persistent, non-visual logic. It loads once when the plugin is enabled and
  stays alive while the popout opens and closes, so its state survives. Wallhaven keeps
  the search results and current page here. This is your service.
- **`framePanel`** — the popout UI. The shell mounts it in the frame and shows it on hover.
  It reads everything from your service. This is the only visible piece.
- **`settings`** — an optional options page shown in Settings → Plugins → your plugin → ⚙.

## How your panel reaches the frame

You do not write hover, sliding, focus, or input-region code. You hand the shell a service
and a panel, and you name a corner with the `frame` block:

```json
"frame": {
  "edge": "top",          // top | bottom — which edge it slides from
  "align": "end",         // start | center | end — position along that edge
  "activationWidth": 320, // optional px: how wide the hover zone is (default: a sane band)
  "activationHeight": 16, // optional px: how tall the hover zone is (default: the frame border)
  "key": "w",             // optional: your key in the Super+X plugins menu (toggles the popout)
  "label": "Wallhaven",
  "icon": "wallpaper"
}
```

Wallhaven is `top` + `end`, so it lives in the top-right corner. That is the whole
integration: ship a service, ship a panel, name your corner.

You own the **activation zone** and the **shortcut**:

- `activationWidth` / `activationHeight` set the size (px) of the corner/edge region that
  opens the popout on hover. Leave them out for the default band. The shell builds the
  hover detection and the input region from these — you write none of it.
- `key` is a single key (e.g. `"w"`, `"b"`) inside Ryoku's **plugins menu**: the user
  presses the leader (`Super+X` by default), then your key, and your popout toggles. This
  keeps plugin shortcuts out of the crowded `Super+<key>` space and never collides with
  other plugins. The user can rebind your key (or clear it) in **Settings → Plugins →
  Edit**, and their choice always wins over your default.

## The properties the shell sets

The shell sets these for you — declare them and read them, do not assign them.

On your **`framePanel`** (`ui/Panel.qml`):

| Property    | Type          | What it is                                              |
| ----------- | ------------- | ------------------------------------------------------ |
| `pluginApi` | `var`         | Your handle to the service, settings, and plugin dir.   |
| `screen`    | `ShellScreen` | The screen this panel is on (import `Quickshell`).      |
| `active`    | `bool`        | True while the popout is open.                          |

On your **`main`** and **`settings`** files: just `pluginApi`.

The panel must size itself with `implicitWidth` / `implicitHeight`; the host slides in
whatever size you declare.

## Reading your service from the panel

`pluginApi.mainInstance` is the live `main` instance. Derive a convenience property and
read state through it:

```qml
readonly property var service: pluginApi ? pluginApi.mainInstance : null
// ...
text: qsTr("Clicked %1 times").arg(service?.clickCount ?? 0)
onClicked: service.increment()
```

Use the `?.` and `?? default` guards — `service` is null until `main` has loaded.

## Settings that persist

`pluginApi.pluginSettings` is your settings object, seeded from
`metadata.defaultSettings`. Read it anywhere. To persist a change, write the field and
call `pluginApi.saveSettings()`. The host calls `saveSettings()` on your settings page
when the user hits Apply, so put the writes there:

```qml
function saveSettings() {
  pluginApi.pluginSettings.greeting = greetingField.text.trim();
  pluginApi.saveSettings();
}
```

## Imports you can use

In the service and panel:

- `Ryoku.Config` — `Tokens` (spacing, padding, rounding, font sizes) and `Colours`
  (`Colours.palette.m3*`, `Colours.tPalette.m3*`, `Colours.layer(...)`).
- `qs.components` — `StyledRect`, `StyledText`, `MaterialIcon`, and friends.
- `qs.components.controls` — `IconButton`, `IconTextButton`, `StyledTextField`, `Menu`, etc.
- `qs.services` — shell services like `Wallpapers`, `Toaster`.

In the settings page only, use the settings-gui toolkit instead:

- `qs.settingsgui.Commons` — `Style`, `Color`, `I18n`.
- `qs.settingsgui.Widgets` — `NText`, `NTextInput`, and the other `N*` widgets.

Match the existing usage in `plugins/wallhaven/`; do not invent parallel styling.

## README and GIF (required)

Every plugin ships a `README.md` and an `assets/preview.gif` it embeds. Follow the section
order in `plugins/wallhaven/README.md`: title, one-liner, the GIF, What it does, Install,
How it plugs into the frame, Settings table, Develop tree, Credits. The GIF should show the
popout actually doing its thing.

## List it in the registry

Add an object to the `plugins` array in `plugins/registry.json` so it appears in
Settings → Plugins → Available:

```json
{
  "id": "my-plugin",
  "name": "My Plugin",
  "path": "plugins/my-plugin",
  "version": "0.1.0",
  "author": "Your Name",
  "description": "One sentence.",
  "tags": ["frame"],
  "official": false,
  "lastUpdated": "2026-06-06"
}
```

`official: false` for community plugins. Keep `path` as `plugins/<id>` and `lastUpdated`
in `YYYY-MM-DD`.
