# Market

Track a stock, index, or crypto pair on your desktop.

![Market on the desktop](assets/preview-widget.png)

## What it does

- Tracks **any** [Yahoo Finance](https://finance.yahoo.com) symbol - a crypto
  pair (`BTC-USD`), a stock (`AAPL`, `F` for Ford), or an index (`^GSPC`) -
  showing its live price, change, and price history. No API key. Type the ticker
  right on the tile: hover for the **`$`** button, enter a symbol (a leading `$`
  like `$SPY` is fine), press Enter.
- Four **faces**, chosen by a setting, each drawn in the shell's dark
  carbon-dossier style:
  - **Dossier** - the flagship: a big tabular price, a green/vermilion change
    badge, a "compared to" baseline, and a **3D ridgeline** of the price history
    with numbered price and time axes.
  - **Line** - a smooth line over an optional grid, with price/time axes and an
    end-point marker.
  - **Area** - a smooth line over a trend-tinted gradient fill, with axes.
  - **Minimal** - name, price, change, and a compact sparkline. The smallest.
- Rising is green, falling is vermilion, always - the accent only tints chrome.
- Pick the window (1 day / week / month / year); the chart and the "compared to"
  baseline follow it. The price flashes and the chart re-draws on each refresh.

## Install

**Ryoku Settings -> Plugins -> Discover -> Market -> Install**, then enable it.
Drag it where you like and scale it from the corner bracket, same as the clock.
Hover the tile and click the **`$`** button to type a new symbol; the design,
window, and other options live in the tile's right-click menu.

## How it plugs in

The shell owns the draggable card, the motion, and the placement; the plugin
supplies the quote and the chart. It ships three parts:

- `service/Main.qml` - resolves settings, polls the fetch script on a timer, and
  exposes the parsed quote + history. It loads once and keeps its state while the
  tile is hidden. (`main` entry point.)
- `content/Widget.qml` - the face selector plus the ticker editor; mounts one
  face per the `design` setting and persists a typed symbol. (`content` entry.)
- `bin/ryoku-market-fetch` - the small CLI that talks to the Yahoo Finance API
  (needs `curl` and `jq`).

Typing a symbol writes it to `plugins.json` via `ryoku-plugins-place`; the shell
watches that file, so the tile re-fetches the new ticker live.

## Settings

The `symbol` is typed on the tile (the `$` button); the rest are editable from
the tile's right-click menu (chips, switch, slider).

| Setting      | Default   | What it does                                             |
| ------------ | --------- | ------------------------------------------------------- |
| `design`     | `dossier` | Which face: dossier / line / area / minimal             |
| `symbol`     | `BTC-USD` | Any Yahoo ticker, typed on the tile (`$SPY`, `F`, `AAPL`, `BTC-USD`, `^GSPC`) |
| `window`     | `1D`      | History window: 1 day / week / month / year             |
| `refreshSec` | `60`      | Poll interval in seconds (30 - 600)                     |
| `accent`     | `wallust` | Chrome tint: follow wallpaper / brand / mono            |
| `showGrid`   | `true`    | Draw the grid behind the Line face                      |

## Develop

```
market/
  manifest.json              id, version, entry points, desktopWidget host, settings
  service/Main.qml           main: resolve settings + poll fetch + parse quote/history
  content/Widget.qml         content: face selector + ticker editor
  content/MarketDossier.qml  face: hero price + 3D ridgeline
  content/MarketLine.qml     face: gridded line + axes + end dot
  content/MarketArea.qml     face: line + gradient fill + axes
  content/MarketMinimal.qml  face: compact price + sparkline
  content/Ridgeline.qml      part: the 3D ridgeline surface + axes
  content/Sparkline.qml      part: compact polyline
  content/ChangeBadge.qml    part: arrow + percent, hover reveal
  content/PriceText.qml      part: big tabular price, flash on change
  bin/ryoku-market-fetch     the Yahoo Finance CLI
  assets/preview-widget.png  the README image
```

## Credits

Official Ryoku plugin, MIT-licensed. Quote and history data from
[Yahoo Finance](https://finance.yahoo.com).
