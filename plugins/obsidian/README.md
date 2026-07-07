# Obsidian

Quick-capture into your Obsidian vault, right from the desktop.

![Obsidian on the desktop](assets/preview-widget.png)

![The vault graph](assets/preview-graph.png)

## What it does

Adopts your existing Obsidian vault and settings, then turns the everyday
capture moves into a **Board** of tappable workflow blocks and a **Graph** of
your vault, in the shell's dark carbon-dossier style. A `Board | Graph` switch
sits under the masthead.

- **Detects Obsidian and your vaults.** Finds the binary and reads the vaults
  Obsidian already knows (`~/.config/obsidian/obsidian.json`). Pick one on the
  tile; nothing happens until you do.
- **Respects your settings.** Reads each vault's `.obsidian/daily-notes.json`,
  `templates.json`, and `app.json`, so daily notes land in **your** folder, with
  **your** filename format and template, and attachments go where Obsidian puts
  them.
- **Board view.** A spine of workflow blocks you build yourself: Today
  (create/open the daily note, exactly as Obsidian would), open a note (from a
  template), append text, a task (`- [ ] …`), or a link, grab a screenshot, or
  record a voice memo. Tap to run; the edit toggle reorders and removes them.
- **Capture bar.** Type a note or a task into the chosen target (your inbox, or
  today's daily note); the labelled **Screenshot** key region-grabs into your
  attachments and embeds it; **Voice memo** records an Opus clip and embeds it.
  Links and `[[wikilinks]]` append verbatim, and a status line confirms each one
  so a quick capture never feels like it did nothing.
- **Graph view.** Your vault as a constellation — notes are nodes sized by how
  many links touch them, `[[wikilinks]]` are the edges. Tap a node to open it.
- **Local-first and opt-in.** Everything is read from and written to your own
  vault on disk. The only thing that leaves the machine is the `obsidian://`
  link handed to your browser opener to focus Obsidian. No accounts, no network,
  no telemetry.

## Install

**Ryoku Settings → Plugins → Discover → Obsidian → Install**, then enable it and
turn on Desktop Widgets. Drag it where you like and scale it from the corner
bracket, same as the clock. On first run it lists your vaults — tap one to
adopt it. Everything else (workflows, capture target) is set on the tile.

Needs `jq` and `xdg-open` (on the Ryoku base); the screenshot key needs `grim`
and `slurp`, and the voice memo needs `ffmpeg` (all on the base too).

## How it plugs in

The shell owns the draggable card, the motion, and the placement; the plugin
supplies the detection, the vault reads, and the writes. It ships three parts:

- `service/Main.qml` — headless: detects Obsidian, resolves the vault settings,
  holds the workflow model, and dispatches every action through the CLI. It
  loads once and keeps its state while the tile is hidden. (`main` entry point.)
- `content/Widget.qml` — the adaptive view: a phase dispatcher (setup → main
  face) with morph-in overlays for the note picker and the block builder. It
  reads everything from the service. (`content` entry point.)
- `bin/ryoku-obsidian` — the local bridge: `detect`, `vault-info`, `list-notes`,
  `daily`, `note`, `append`, `open`, `templates`, `graph`, `screenshot`,
  `record-audio`. It reads your `.obsidian` config and writes notes on disk.

The vault, the capture target, and workflows are set on the tile and persisted to
`plugins.json` via `ryoku-plugins-place`; the shell watches that file, so the
tile re-tunes live.

## Settings

The vault is chosen on the tile (or typed in settings as a fallback); workflows
and the capture target are built on the tile. The right-click menu carries the
accent.

| Setting  | Default      | What it does                                           |
| -------- | ------------ | ------------------------------------------------------ |
| `accent` | `brand`      | Chrome tint: fixed vermillion / wallust / mono         |
| `vault`  | *(on tile)*  | Absolute path to the vault; picked from the chooser    |
| `inbox`  | *(today)*    | Default capture note; empty means today's daily note   |

Settings are declared as the `metadata.settings` schema in `manifest.json`; the
shell renders the form and persists changes to `pluginApi.pluginSettings`.

## Develop

```
obsidian/
  manifest.json              id, version, entry points, desktopWidget host, deps, settings
  bin/ryoku-obsidian         local bridge: detect / vault-info / list-notes / daily /
                             note / append / open / templates / screenshot / record-audio
  service/Main.qml           main: detect + resolve settings + workflow model + dispatch
  content/Widget.qml         content: phase dispatcher + picker/editor overlays + editing
  content/Panel.qml          brutalist surface (flat + hairline + hard offset shadow)
  content/Eyebrow.qml        editorial kicker (tick + 力 + mono label)
  content/ObsidianMark.qml   the 黒 hanko seal
  content/SetupPanel.qml     detect state + vault chooser
  content/MainFace.qml       masthead + Board/Graph switch + spine + capture bar
  content/WorkflowBlock.qml  one action block: node on the spine
  content/BlockEditor.qml    the step-by-step block builder
  content/QuickCapture.qml   the note/task + screenshot + voice capture bar
  content/NotePicker.qml     searchable note chooser
  content/GraphPanel.qml     the vault graph (force layout, tap a node to open)
  assets/preview-widget.png  the README images
  assets/preview-graph.png
```

Copy `plugins/template/` and read `plugins/AUTHORING.md` for the full guide.

## Credits

Official Ryoku plugin, MIT-licensed. Works with [Obsidian](https://obsidian.md);
not affiliated with or endorsed by Obsidian.
