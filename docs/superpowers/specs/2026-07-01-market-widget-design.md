# Market widget — design

A stock + BTC price tracker desktop widget for the Ryoku shell, built as a
`ryoku-extras` plugin. It tracks one configurable symbol (a crypto pair, a
stock, or an index) from a free no-key source and renders it through a family of
selectable faces, in the shell's dark carbon-dossier idiom.

## Goals

- One plugin, `market`, that tracks one symbol (default `BTC-USD`) and shows its
  live price, 24h/day change, and a price history chart.
- A family of **4 faces**, each its own file, chosen by a `design` setting —
  exactly how the deleted `media` plugin and `widgets/clock/Clock.qml` select a
  face:
  - **Dossier** — the flagship (matches the "Income" reference): big price,
    change badge, "compared to" subline, and a **2.5D layered ridgeline** chart.
  - **Line** — a gridded plot with a smooth line and end-point dot markers.
  - **Area** — a smooth line over a gradient fill.
  - **Minimal** — name, price, change, and a compact sparkline. The smallest.
- Native to the shell: carbon-dossier idiom (力 eyebrow, mono tabular figures,
  vermilion accent spent sparingly, `CornerTicks`), dark surface drawn by each
  face so the host slot's `bg:"none"` looks right.
- Free data, no API key. A first-class RAM citizen: the fetch poll and every
  animation are gated on visibility.

## Non-goals

- No portfolio, no order book, no multi-symbol grid in v1 (one symbol per tile;
  add more tiles for more symbols).
- No real WebGL 3D. The ridgeline is a 2.5D layered illusion.
- No trading, no auth, no persistence beyond the shell's own plugins.json.

## References (patterns copied from)

- **Widget contract** (`plugins/photo-frame`, deleted `plugins/media`): a plugin
  is a headless `service/Main.qml` (resolves settings behind defaults, kept alive
  by the host as `pluginApi.mainInstance`) plus an adaptive `content/Widget.qml`.
  The host sets `pluginApi`, `screen`, `density` (`"compact"`), `s` (`1`),
  `widthBudget` (`360`), `active` (`true`). The content reports
  `implicitWidth/implicitHeight`; the host measures it to size the draggable card.
- **Face selector** (deleted `media/content/Widget.qml`): a thin `switch(design)`
  → inline `Component` per face, each binding a shared `service`, each reporting
  its own `implicitHeight`. Unknown value falls back to the flagship.
- **External data via Process** (deleted `wallhaven/service/Main.qml`): ship a
  script under `bin/`, run it with a `Process` + `StdioCollector`, parse JSON
  lines. Poll on a `Timer` gated `running: active`.
- **Settings resolver** (`photo-frame/service/Main.qml`): `_has/_str/_num/_bool`,
  every value read behind a default because settings are not manifest-seeded.
- **Design language** (kit `Theme`/`MicroLabel`/`CornerTicks`/`WaveMeter`): 力
  eyebrow via `MicroLabel`, `Theme.cream` text, `Theme.brand` (#F25623) accent,
  `Theme.cardTop→cardBot` gradient surface, `CornerTicks` framing.

## Data source

**Yahoo Finance v8 chart** — one endpoint serves stocks, crypto, and indices:

```
https://query1.finance.yahoo.com/v8/finance/chart/<SYMBOL>?range=<R>&interval=<I>
```

One response carries everything a face needs:
- `meta.symbol`, `meta.shortName` (e.g. "Bitcoin USD"), `meta.currency`
- `meta.regularMarketPrice` (live price)
- `meta.chartPreviousClose` (→ change % = (price − prevClose) / prevClose)
- `indicators.quote[0].close[]` (the history array for the chart)

No API key. Requires a browser `User-Agent`. A bad symbol returns HTTP 404 with a
`.chart.error` body, so the fetch script must NOT use `curl -f` — it parses
`.chart.result` and emits a clean `{"error":...}` line when null.

`range`/`interval` come from a `window` setting: `1D` (`1d`/`5m`), `1W`
(`5d`/`15m`), `1M` (`1mo`/`1d`), `1Y` (`1y`/`1d`). The "compared to" baseline and
the change label track the chosen window's first close.

Dependencies: `curl`, `jq` (already required by the old wallhaven plugin; standard
on the Ryoku base).

## Files

```
plugins/market/
  manifest.json              id "market", host desktopWidget, typed settings
  bin/ryoku-market-fetch     curl+jq: emit one JSON line {symbol,name,price,
                             prevClose,changePct,currency,spark:[...]} or {error}
  service/
    Main.qml                 headless: resolve settings, poll fetch, parse, expose state
  content/
    Widget.qml               face selector (switch design -> Component)
    MarketDossier.qml        hero: price + ChangeBadge + subline + Ridgeline
    MarketLine.qml           gridded plot + smooth line + end dots
    MarketArea.qml           smooth line + gradient fill
    MarketMinimal.qml        name + price + change + Sparkline
    Sparkline.qml            compact polyline (Shape), draw-in animation
    Ridgeline.qml            2.5D stacked wave rows, blue->green gradient, skew
    ChangeBadge.qml          arrow + pct, green up / vermilion down, hover lift
    PriceText.qml            large tabular price, roll/flash on change
  assets/
    preview-widget.png       README image
```

Flat `content/` (not `content/faces/`) so QML resolves sibling components without
imports — matches how `media` and `photo-frame` actually shipped. All chart parts
use `Shape`/`ShapePath` (not `Canvas`) per the qt-qml perf rules, so paths render
on the render thread and animate cheaply.

## Service contract (`service/Main.qml`)

Headless `Item`. Host sets `pluginApi`; everything else is derived.

Settings (resolved behind defaults):
- `design` — dossier | line | area | minimal (default dossier)
- `symbol` — ticker string (default `BTC-USD`)
- `window` — 1D | 1W | 1M | 1Y (default 1D)
- `refreshSec` — poll interval, 30..600 (default 60)
- `accent` — wallust | brand | mono (default wallust; the up/down colour is
  always semantic green/vermilion, accent only tints chrome)
- `showGrid` — toggle for the Line face grid (default true)

State exposed to faces:
- `symbol`, `name`, `currency`
- `price`, `prevClose`, `changePct`, `changeAbs`, `up` (bool)
- `spark` (array of closes, nulls stripped), `sparkMin`, `sparkMax`
- `loading`, `error` (string; empty when ok), `lastUpdated`
- `fmtPrice(v)` / `fmtPct(v)` helpers (thousands sep, currency symbol, sign)

Fetch: a `Process` whose `command` is `[pluginDir + "/bin/ryoku-market-fetch",
symbol, range, interval]`, run by a `Timer` (`interval: refreshSec*1000`,
`running: active`, `triggeredOnStart: true`) plus a re-fetch whenever
`symbol`/`window` changes. `StdioCollector` → parse one JSON line → set state.
Errors set `error` and keep the last good values so the tile doesn't blank.

## Faces

Each face: `pragma ComponentBehavior: Bound`, root `Item`, props
`service`, `s`, `cw`. Designs at `s = 1`; content width from `cw` (the host's 360
budget). Each reports its own `implicitHeight` and draws its own
`Theme.cardTop→cardBot` surface with `CornerTicks`. No `Behavior on
implicitHeight` (the host tweens the slot).

| Face | Body |
|---|---|
| **Dossier** | 力 MARKET eyebrow (name), big `PriceText`, `ChangeBadge` beside it, "Compared to <prevClose> <window>" subline, `Ridgeline` hero filling the rest. The reference "Income" card, dark. |
| **Line** | 力 eyebrow + price header; a `Shape` smooth line across an optional faint grid (`showGrid`), a filled end-dot marker at the latest point, min/max y-ticks. |
| **Area** | 力 eyebrow + price header; a smooth `Shape` line with a vertical gradient fill beneath it (green when up, vermilion when down), fading to transparent at the bottom. |
| **Minimal** | One row: name + price stacked left, `ChangeBadge` and a compact `Sparkline` right. The smallest face. |

## Animation & RAM discipline

- **Sparkline / Line / Area / Ridgeline**: paths are `Shape`/`ShapePath`. On a
  data refresh, a `progress` 0→1 `NumberAnimation` (gated `running: visible`)
  reveals the path (path length or a clip sweep). No free-running timer.
- **Ridgeline crest drift**: a single slow `SequentialAnimation`/`Behavior` on a
  phase value, `running: visible` only, driving a subtle vertical wobble on the
  top rows. Off-screen → stopped.
- **PriceText**: on `price` change, a brief colour flash (green/vermilion) +
  small y-nudge via `Behavior`, settling back to `Theme.cream`.
- **ChangeBadge**: `HoverHandler` lifts/brightens the badge and reveals the
  absolute change; idle → resting state.
- Poll `Timer` and every animation bind `running` to `active`/`visible`, so an
  off-screen or torn-down tile costs nothing (host hardwires `active: true`, so
  visibility gating lives in the faces/service, per the media pattern).

## Customization (manifest `metadata.settings`)

`design` (choice), `symbol` (text, placeholder "e.g. BTC-USD, AAPL, ^GSPC"),
`window` (choice 1D/1W/1M/1Y), `refreshSec` (slider 30..600 step 30),
`accent` (choice wallust/brand/mono), `showGrid` (toggle). Field shapes match
photo-frame's exact schema (`type`, `label`, `group`, `default`,
`options`/`min`/`max`/`step`/`decimals`/`placeholder`).

## Registry + docs

Add a `market` object to `plugins/registry.json` `plugins` (id, name, path,
version 1.0.0, official true, tagline, description, icon "trending",
tags `["stocks","crypto","desktop-widget"]`, hosts `["desktopWidget"]`, preview).
Ship `README.md` in the wallhaven/photo-frame section order + a preview image.
