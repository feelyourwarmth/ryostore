# Obsidian widget — design

A quick-capture and workflow launcher for [Obsidian](https://obsidian.md),
built as a `ryoku-extras` desktop-widget plugin. It detects Obsidian, adopts the
user's existing vault and settings (daily-note folder, filename format,
template, attachment folder), and turns the everyday capture moves — open
today's daily note, open a note, append text / tasks / links / screenshots /
voice memos — into tap-sized blocks laid out as a small canvas of workflows on
the wallpaper, in the shell's dark carbon-dossier idiom.

## Goals

- One plugin, `obsidian`, that is **local-first and opt-in**: it reads the
  user's own vault config off disk and writes notes on disk. No accounts, no
  network, no telemetry. Nothing happens until the user picks a vault.
- **Detect and adopt.** Find the Obsidian binary and the vaults Obsidian already
  knows about (`~/.config/obsidian/obsidian.json`). Read each vault's
  `.obsidian/daily-notes.json`, `app.json`, `templates.json` so daily notes land
  in the user's folder, with the user's filename format and template, and
  attachments go where Obsidian puts them.
- **The everyday moves, one tap each:**
  - **Today** — create today's daily note (folder + Moment.js filename + template
    from the user's config) if missing, then open it in Obsidian.
  - **Open** a specific note.
  - **Append** text, a task (`- [ ] …`), or a link to a chosen note (or today's
    daily) — typed right on the tile.
  - **Screenshot** — region-grab into the vault's attachment folder and append an
    embed to a note.
  - **Voice memo** — record audio into the attachment folder and append an embed.
- **A canvas of workflow blocks.** Each saved action is a rectangular block on a
  vermilion spine — a graph/canvas feel at tile scale. Tap a block to run it.
  Blocks grow down the tile and scroll when there are many.
- **Expandable configuration.** A block builder opens in-tile: choose the action,
  the target (today / a note / capture type), and the template — step by step,
  add as many blocks as you like.
- Native to the shell: carbon surface (`Theme.cardTop→cardBot`), 力-style
  `MicroLabel` eyebrows, vermilion accent spent sparingly, `CornerTicks` framing,
  an Obsidian gem mark drawn as a `Shape`. A first-class RAM citizen — detection
  polls slowly and only while unconfigured; animations gate on visibility.

## Non-goals

- **No Templater/Dataview execution.** Community-plugin template *logic* (JS) is
  not run. Core template placeholders (`{{title}}`, `{{date}}`, `{{time}}`, and
  `{{date:FMT}}`) are substituted; anything else is copied verbatim, and Obsidian
  processes it on open as it always would.
- **No note editing in the widget.** Capture is append-only; real editing happens
  in Obsidian. The widget opens the note there.
- **No sync, no vault management, no graph of note links.** The "graph/canvas"
  is the *workflow* layout, not a render of the vault's link graph.
- **No new note-content append via `obsidian://`.** The native URI `append`
  parameter is unreliable in current Obsidian (1.8.x), and disk append is more
  local anyway — so appends are written to the file directly.

## References (patterns copied from)

- **Widget contract** (`plugins/market`, `plugins/photo-frame`): a plugin is a
  headless `service/Main.qml` (resolves settings behind defaults, kept alive by
  the host as `pluginApi.mainInstance`) plus an adaptive `content/Widget.qml`.
  The host sets `pluginApi`, `screen`, `density` (`"compact"`), `s` (`1`),
  `widthBudget` (`360`), `active` (`true`); the content reports
  `implicitWidth/implicitHeight`.
- **External work via Process** (`market/service/Main.qml`, `market` editor):
  ship a script under `bin/`, run it with a `Process` + `StdioCollector`, parse
  JSON. The **content** may also run a `Process` (market's ticker editor does).
- **On-tile text entry** (`market/content/Widget.qml`): the wallpaper layer is
  mouse-only, so a focused `TextField` sets `editing: true` on the content root;
  `widgets/shell.qml` reads it and raises an exclusive keyboard grab
  (`win.kbWanted`). Typed values persist with
  `ryoku-plugins-place <id> settings <json>`; the registry file-watch retunes the
  live tile.
- **Settings resolver** (`photo-frame/service/Main.qml`): `_has/_str/_num/_bool`;
  every value read behind a default because settings are not manifest-seeded.
- **Design language** (kit `Theme`/`MicroLabel`/`CornerTicks`/`GlyphIcon`): 力
  eyebrow, `Theme.cream` text, `Theme.brand` accent, `cardTop→cardBot` surface,
  `CornerTicks`. Vector marks drawn as `Shape`/`ShapePath` per the qt-qml perf
  rules (no animated `Canvas`).

## The backend CLI (`bin/ryoku-obsidian`)

One script, verbs on argv, one JSON object per call on stdout; failures still
exit 0 with `{ "error": "…" }` so the service keeps its last good state. Needs
`jq` (present on the base) and the capture tools (`grim`, `slurp`, `ffmpeg`) only
for the capture verbs.

| Verb | Args | Returns / effect |
|---|---|---|
| `detect` | — | `{ installed, launcher, vaults: [{ name, path, open }] }` from the binary lookup + `~/.config/obsidian/obsidian.json`. |
| `vault-info` | `<vaultPath>` | `{ daily: { folder, format, template }, attachments, newFileFolder }` merged from `.obsidian/daily-notes.json` + `app.json` + `templates.json`, with sane fallbacks (`format: "YYYY-MM-DD"`). |
| `list-notes` | `<vaultPath> [query] [limit]` | `{ notes: [relpath, …] }` — `*.md` under the vault (excluding `.obsidian`, `.trash`), newest first, filtered by a case-insensitive substring. |
| `daily` | `<vaultPath> <vaultName>` | Compute today's path (`folder` + Moment-format), create with the template applied (placeholder substitution) if missing, then open `obsidian://open`. `{ path, created, uri }`. |
| `append` | `<vaultPath> <vaultName> <relOrEmpty> <text>` | Append `text` (+ trailing newline) to the note; empty rel = today's daily (created if missing). `{ path }`. Text is passed via a file/env, never argv-escaped. |
| `open` | `<vaultName> <rel>` | `xdg-open "obsidian://open?vault=…&file=…"`. |
| `screenshot` | `<vaultPath> <vaultName> <relOrEmpty>` | `grim -g "$(slurp)"` into `<attachments>/…png`, append `![[png]]` to the note. `{ path, attachment }`. |
| `record-audio` | `<vaultPath> <relOrEmpty> <outName>` | `ffmpeg -f pulse` to an opus `.ogg` in attachments; **runs until signalled**, traps `TERM/INT` → sends `q`/`INT` to ffmpeg → finalizes. `{ attachment }`. The embed append is done by the service on exit. |

Moment→date: an ordered token map (`YYYY MMMM MMM MM M YY DD D dddd ddd HH mm ss`
→ `date` format), so a user's `dddd DD-MM-YYYY` or `YYYY/MMMM/DD` (subfolders via
`/`) name resolves correctly. Template placeholders: `{{title}}`, `{{date}}`,
`{{time}}`, `{{date:FMT}}`, `{{time:FMT}}`.

## Service contract (`service/Main.qml`)

Headless `Item`. Host sets `pluginApi`; everything else derived.

Settings (behind defaults):
- `vault` — selected vault absolute path (default `""` → setup state).
- `workflows` — a JSON **string**: `[{ id, label, icon, action, note, template }]`.
  Not a manifest schema field (it is edited on the tile, not the settings page);
  persisted with `ryoku-plugins-place`.
- `inbox` — default capture target relpath (default `""` → today's daily).
- `accent` — wallust | brand | mono (chrome tint).

Derived / state:
- `installed`, `launcher`, `vaults[]` from `detect` (polled every 25s **only**
  while not fully configured; once installed. Off otherwise).
- `vaultName` (basename of `vault`), `vaultInfo` (daily/attachments) from
  `vault-info`, re-read when `vault` changes.
- `notes[]` cache from `list-notes` (for the picker), refreshed on demand.
- `recording` (bool), `recordNote`, `recordProc` — audio lifecycle. `stop()` sets
  `recordProc.running=false`; on `onExited` the service appends the embed.
- `phase`: `"loading" | "notInstalled" | "noVault" | "ready"`.

Dispatch — `run(block)` maps a block to a backend command; `daily`/`open`/
`screenshot` run immediately; `appendText`/`appendTask` focus the capture bar
pre-targeted at `block.note`; `audio` toggles recording into `block.note`.
`workflows` mutations (add/update/remove/reorder) rewrite the JSON string and
persist it.

## Files

```
plugins/obsidian/
  manifest.json              id "obsidian", host desktopWidget, typed settings + deps
  bin/ryoku-obsidian         detect / vault-info / list-notes / daily / append /
                             open / screenshot / record-audio  (jq; capture tools)
  service/
    Main.qml                 headless: detect, resolve settings, vault info,
                             workflow model, run() dispatch, audio lifecycle
  content/
    Widget.qml               phase dispatcher; owns `editing`, capture + picker overlays
    ObsidianMark.qml         the Obsidian gem, drawn as a Shape (brand mark)
    SetupPanel.qml           not-installed hint + vault chooser (setup flow)
    MainFace.qml             header (mark + vault + gear) + spine of blocks + capture bar
    WorkflowBlock.qml        one action block: node on the spine, icon, label, run/edit
    BlockEditor.qml          step-by-step builder: action → target → template → save
    QuickCapture.qml         text field (task/note toggle) + mic + camera row
    NotePicker.qml           searchable note list (open / choose target)
  assets/
    preview-widget.png       README image (captured from the live tile)
```

Flat `content/` so QML resolves siblings without imports (matches market /
photo-frame). Marks and the spine are `Shape`/`ShapePath`.

## States & UX flow

1. **loading** — brief; the gem mark pulses.
2. **notInstalled** — the gem, "Obsidian not found", and a button that opens the
   download page (`xdg-open https://obsidian.md/download`); re-detects on a timer.
3. **noVault** — "Choose a vault": the detected vaults as tappable blocks (name +
   path). Tapping persists `vault` and re-reads its config. If none are detected,
   a line explains opening a vault in Obsidian once so it registers.
4. **ready** — the main face:
   - Header: gem + vault name + a status dot + a gear (opens the block builder).
   - A **Today** block always first, then the user's workflow blocks on the spine.
   - The **capture bar**: a text field (note/task toggle) + mic + camera. Enter
     appends to `inbox` (or today's daily); mic records; camera region-grabs.
   - **+ Add block** at the foot opens `BlockEditor`.

The tile grows with content; the block list scrolls past a cap. The header stays
drag chrome (the grip sits under the content, so blocks/fields keep their taps).

## Animation & RAM discipline

- Detection `Timer` runs only while `phase !== "ready"`; the poll is a cheap file
  read + `command -v`.
- The spine draws once (`Shape`); block hover/press use `Behavior on color`/
  `scale` (Animator where possible), gated on visibility.
- The gem's loading pulse is a `NumberAnimation` gated `running: phase==="loading"`.
- No `Behavior on implicitHeight` on the root — the host tweens the slot.

## Customization (manifest `metadata.settings`)

`accent` (choice wallust/brand/mono). `vault`, `inbox`, and `workflows` are set on
the tile (chooser / capture bar / block builder), not the settings page, so they
carry `default` values but are edited via `ryoku-plugins-place`. The right-click
menu still exposes `accent`.

## Registry + docs

Add an `obsidian` object to `plugins/registry.json` `plugins` (id, name, path,
version 1.0.0, official true, tagline, description, icon `"file"`, tags
`["obsidian","notes","desktop-widget"]`, hosts `["desktopWidget"]`, preview).
Ship `README.md` in the template's section order + a preview image captured from
the live tile.
