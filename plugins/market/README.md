# Market

Track a stock, index, or crypto pair on your desktop.

![Market on the desktop](assets/preview-widget.png)

## What it does

- Tracks any [Yahoo Finance](https://finance.yahoo.com) symbol - a crypto pair
  (`BTC-USD`), a stock (`AAPL`), or an index (`^GSPC`) - and shows its live
  price, change, and price history. No API key.
- Four **faces**, chosen by a setting, each drawn in the shell's dark
  carbon-dossier style:
  - **Dossier** - the flagship: a big tabular price, a green/vermilion change
    badge, a "compared to" baseline, and a layered **2.5D ridgeline** of the
    price history.
  - **Line** - a smooth line over an optional grid, with an end-point marker.
  - **Area** - a smooth line over a trend-tinted gradient fill.
  - **Minimal** - name, price, change, and a compact sparkline. The smallest.
- Rising is green, falling is vermilion, always - the accent only tints chrome.
- Pick the window (1 day / week / month / year); the chart and the "compared to"
  baseline follow it. The price flashes and the chart re-draws on each refresh.

## Install

**Ryoku Settings -> Plugins -> Discover -> Market -> Install**, then enable it.
Drag it where you like and scale it from the corner bracket, same as the clock.

## How it plugs in

The shell owns the draggable card, the motion, and the placement; the plugin
supplies the quote and the chart. It ships three parts:

- `service/Main.qml` - resolves settings, polls the fetch script on a timer, and
  exposes the parsed quote + history. It loads once and keeps its state while the
  tile is hidden. (`main` entry point.)
- `content/Widget.qml` - a selector that mounts one face per the `design` setting;
  each face reads the service and reports its size. (`content` entry point.)
- `bin/ryoku-market-fetch` - the small CLI that talks to the Yahoo Finance API
  (needs `curl` and `jq`).

## Settings

| Setting      | Default   | What it does                                             |
| ------------ | --------- | ------------------------------------------------------- |
| `design`     | `dossier` | Which face: dossier / line / area / minimal             |
| `symbol`     | `BTC-USD` | The ticker to track (`BTC-USD`, `AAPL`, `^GSPC`, ...)    |
| `window`     | `1D`      | History window: 1 day / week / month / year             |
| `refreshSec` | `60`      | Poll interval in seconds (30 - 600)                     |
| `accent`     | `wallust` | Chrome tint: follow wallpaper / brand / mono            |
| `showGrid`   | `true`    | Draw the grid behind the Line face                      |

## Develop

```
market/
  manifest.json              id, version, entry points, desktopWidget host, settings
  service/Main.qml           main: resolve settings + poll fetch + parse quote/history
  content/Widget.qml         content: the face selector
  content/MarketDossier.qml  face: hero price + 2.5D ridgeline
  content/MarketLine.qml     face: gridded line + end dot
  content/MarketArea.qml     face: line + gradient fill
  content/MarketMinimal.qml  face: compact price + sparkline
  content/Ridgeline.qml      part: the 2.5D layered surface
  content/Sparkline.qml      part: compact polyline
  content/ChangeBadge.qml    part: arrow + percent, hover reveal
  content/PriceText.qml      part: big tabular price, flash on change
  bin/ryoku-market-fetch     the Yahoo Finance CLI
  assets/preview-widget.png  the README image
```

## Credits

Official Ryoku plugin, MIT-licensed. Quote and history data from
[Yahoo Finance](https://finance.yahoo.com).
