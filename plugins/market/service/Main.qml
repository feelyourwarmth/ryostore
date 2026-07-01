pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Ryoku.PluginKit.Singletons

/**
 * Market plugin service: headless settings resolver + a gated poll of the
 * bin/ryoku-market-fetch script + parsed quote/history state. The desktop-widget
 * host keeps one of these alive across mounts and hands it to the content as
 * pluginApi.mainInstance, so every face binds the same symbol, quote, and
 * settings.
 *
 * Host-agnostic and headless: it owns no UI, only the resolved settings and the
 * live quote it fetches. The fetch shells out to the plugin's own CLI (Yahoo
 * Finance v8, no key), the same way the old wallhaven service did. A soft error
 * line keeps the last good values so a transient network blip never blanks the
 * tile.
 *
 * Plugin settings are NOT auto-seeded from the manifest at runtime, so every
 * value is read behind a default (resolver matches plugins/photo-frame).
 */
Item {
  id: root

  property var pluginApi
  readonly property var settings: pluginApi ? pluginApi.pluginSettings : null
  // The host wires pluginApi after this service loads, so pluginDir (and the
  // command path built from it) is empty until then. Gate the first fetch on it.
  readonly property bool ready: !!(pluginApi && pluginApi.pluginDir && pluginApi.pluginDir.length > 0)

  function _has(k) {
    return settings && settings[k] !== undefined && settings[k] !== null && settings[k] !== "";
  }
  function _str(k, d) { return _has(k) ? String(settings[k]) : d; }
  function _num(k, d) { return _has(k) ? Number(settings[k]) : d; }
  function _bool(k, d) {
    if (!settings || settings[k] === undefined || settings[k] === null)
      return d;
    return settings[k] === true || settings[k] === "true";
  }

  // Normalise a user-typed ticker: drop a leading "$" ($SPY -> SPY, $f -> F),
  // trim, uppercase. Yahoo tickers are uppercase and keep ^ (indices) and - / .
  // (BTC-USD, BRK-B). Applied here so a value typed in the hub or hand-edited
  // into plugins.json normalises too, not only the in-widget editor.
  function normSymbol(s) {
    var t = String(s || "").trim();
    while (t.charAt(0) === "$") t = t.slice(1);
    return t.toUpperCase();
  }

  // ── settings ──────────────────────────────────────────────────────────────
  readonly property string design: _str("design", "dossier")
  readonly property string symbol: {
    var n = normSymbol(_str("symbol", "BTC-USD"));
    return n.length > 0 ? n : "BTC-USD";
  }
  readonly property string winKey: _str("window", "1D")
  readonly property int refreshSec: Math.max(30, _num("refreshSec", 60))
  readonly property string accent: _str("accent", "wallust")
  readonly property bool showGrid: _bool("showGrid", true)

  // window key -> Yahoo range/interval + a human label for the "compared to" line.
  readonly property var winCfg: {
    switch (winKey) {
    case "1W": return { range: "5d",  interval: "15m", label: qsTr("last week") };
    case "1M": return { range: "1mo", interval: "1d",  label: qsTr("last month") };
    case "1Y": return { range: "1y",  interval: "1d",  label: qsTr("last year") };
    default:   return { range: "1d",  interval: "5m",  label: qsTr("prev close") };
    }
  }
  readonly property string windowLabel: winCfg.label

  // ── live quote state ────────────────────────────────────────────────────────
  property string sym: ""
  property string name: ""
  property string currency: "USD"
  property real price: 0
  property real prevClose: 0
  property real changePct: 0
  property real changeAbs: 0
  property var spark: []
  property var times: []
  property bool loading: false
  property string error: ""
  property double lastUpdated: 0

  readonly property bool up: changeAbs >= 0
  readonly property bool hasData: Array.isArray(spark) && spark.length > 1
  // Semantic trend colours are fixed (green up / vermilion down) regardless of
  // the chrome accent, so a rising asset never reads as a warning and vice versa.
  readonly property color upColor: "#33d685"
  readonly property color downColor: Theme.brand
  readonly property color trendColor: up ? upColor : downColor

  readonly property real sparkMin: {
    if (!hasData) return 0;
    var m = spark[0];
    for (var i = 1; i < spark.length; i++) if (spark[i] < m) m = spark[i];
    return m;
  }
  readonly property real sparkMax: {
    if (!hasData) return 1;
    var m = spark[0];
    for (var i = 1; i < spark.length; i++) if (spark[i] > m) m = spark[i];
    return m;
  }

  // ── fetch/poll ──────────────────────────────────────────────────────────────
  function cmdPath() { return (pluginApi ? pluginApi.pluginDir : "") + "/bin/ryoku-market-fetch"; }

  function refresh() {
    if (!ready || fetchProc.running)
      return;
    loading = true;
    _stdout = "";
    fetchProc.command = [cmdPath(), symbol, winCfg.range, winCfg.interval];
    fetchProc.running = true;
  }

  property string _stdout: ""
  function _finish() {
    loading = false;
    var line = _stdout.split("\n").filter(l => l.trim().length > 0).pop() || "";
    if (line.length === 0) {
      error = qsTr("No response");
      return;
    }
    try {
      var d = JSON.parse(line);
      if (d.error) {
        // Keep the last good values; just surface the message.
        error = String(d.error);
        return;
      }
      sym = d.symbol || symbol;
      name = d.name || sym;
      currency = d.currency || "USD";
      price = Number(d.price) || 0;
      prevClose = Number(d.prevClose) || 0;
      changeAbs = Number(d.changeAbs) || 0;
      changePct = Number(d.changePct) || 0;
      spark = Array.isArray(d.spark) ? d.spark : [];
      times = Array.isArray(d.times) ? d.times : [];
      error = "";
      lastUpdated = Date.now();
    } catch (e) {
      error = qsTr("Parse error");
    }
  }

  Process {
    id: fetchProc
    stdout: StdioCollector { onStreamFinished: root._stdout = text }
    onExited: root._finish()
  }

  // First fetch as soon as the dir is known; re-fetch when the tracked symbol or
  // window changes. refresh() no-ops while a fetch is in flight, so these can't
  // stack.
  onReadyChanged: if (ready) refresh();
  onSymbolChanged: if (ready) refresh();
  onWinKeyChanged: if (ready) refresh();

  Timer {
    interval: root.refreshSec * 1000
    running: root.ready
    repeat: true
    onTriggered: root.refresh()
  }

  // ── formatting + accent helpers ─────────────────────────────────────────────
  function currencySymbol() {
    switch (currency) {
    case "USD": case "AUD": case "CAD": return "$";
    case "EUR": return "\u20ac";
    case "GBP": return "\u00a3";
    case "JPY": case "CNY": return "\u00a5";
    default: return "";
    }
  }

  // Price with thousands separators; decimals scale with magnitude so a
  // sub-dollar coin still reads (0.0421) while BTC drops the cents ($59,952).
  function fmtPrice(v) {
    var neg = v < 0;
    var a = Math.abs(Number(v) || 0);
    var dec = a >= 1000 ? 0 : (a >= 1 ? 2 : 4);
    return (neg ? "-" : "") + currencySymbol() + a.toLocaleString(Qt.locale(), 'f', dec);
  }

  function fmtPct(v) { return (Math.abs(Number(v) || 0)).toFixed(2) + "%"; }

  // Compact price for axis ticks: 1.2M / 60.1k / 294 / 0.0421. No currency
  // symbol (the axis is understood to be price), tuned to stay short.
  function fmtCompact(v) {
    var a = Math.abs(Number(v) || 0);
    if (a >= 1e6) return (a / 1e6).toFixed(2) + "M";
    if (a >= 1e3) return (a / 1e3).toFixed(1) + "k";
    if (a >= 1) return a.toFixed(a >= 100 ? 0 : 1);
    return a.toFixed(4);
  }

  // Time tick from a unix-seconds stamp, formatted for the active window:
  // intraday -> HH:mm, week -> weekday, month -> D/M, year -> MMM.
  function fmtTime(unixSec) {
    var t = Number(unixSec) || 0;
    if (t <= 0) return "";
    var d = new Date(t * 1000);
    var loc = Qt.locale();
    switch (winKey) {
    case "1W": return d.toLocaleDateString(loc, "ddd");
    case "1M": return d.toLocaleDateString(loc, "d/M");
    case "1Y": return d.toLocaleDateString(loc, "MMM");
    default:   return d.toLocaleTimeString(loc, "hh:mm");
    }
  }

  // Faces call this for chrome tints (eyebrow dot, grid) so the wallust vs brand
  // vs mono choice lives in one place. Trend green/red stays semantic (above).
  function accentColor() {
    return accent === "brand" ? Theme.brand
      : accent === "mono" ? Theme.cream
      : (Wallust.accent !== undefined ? Wallust.accent : Theme.brand);
  }
}
