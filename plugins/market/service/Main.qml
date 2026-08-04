pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Ryoku.PluginKit.Singletons

/**
 * Market plugin service: headless settings resolver + a gated poll of the
 * bin/ryoku-market-fetch script + parsed quote/history state. The desktop-widget
 * host keeps one of these alive across mounts and hands it to the content as
 * pluginApi.mainInstance, so every face binds the same watchlist, quotes, and
 * settings.
 *
 * The tracked instruments are a watchlist (comma-separated `symbols` setting);
 * one of them is the ACTIVE instrument that owns the chart and the headline
 * numbers, the rest ride along as compact rows. One fetch per tick pulls the
 * whole list, active first at full resolution. Switching the active symbol
 * promotes that row's data immediately (a coarse but correct chart), then a
 * refresh fills in the resolution.
 *
 * Change math is window-aware: for 1D the baseline is Yahoo's previous close,
 * for wider windows it is the first sample of the window, so the headline
 * change always describes the chart under it.
 *
 * Host-agnostic and headless: it owns no UI, only resolved settings and live
 * quotes. A soft error line keeps the last good values so a transient network
 * blip never blanks the tile; `stale` flags that state for the faces.
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

  // Comma/space separated user text -> normalised, deduped list, capped so one
  // poll stays a handful of sequential requests.
  function parseSymbols(text) {
    var out = [];
    var parts = String(text || "").split(/[,\s]+/);
    for (var i = 0; i < parts.length; i++) {
      var t = normSymbol(parts[i]);
      if (t.length > 0 && out.indexOf(t) < 0)
        out.push(t);
    }
    return out.slice(0, 6);
  }

  // ── settings ──────────────────────────────────────────────────────────────
  readonly property string design: _str("design", "dossier")
  // `symbols` is the watchlist; a lone legacy `symbol` still resolves so a
  // pre-watchlist install keeps its instrument.
  property string _symbolsOverride: ""
  readonly property string symbolsText: {
    var raw = _symbolsOverride.length > 0 ? _symbolsOverride
      : _str("symbols", _str("symbol", "BTC-USD"));
    return raw;
  }
  readonly property var watchlist: {
    var l = parseSymbols(symbolsText);
    return l.length > 0 ? l : ["BTC-USD"];
  }
  // String mirror of the list: `var` bindings mint a fresh array on every
  // re-evaluation (so their change signal fires for unrelated settings writes),
  // but a string only signals on a real value change. The refetch keys off this.
  readonly property string watchKey: watchlist.join(",")
  // The active instrument owns the chart. Persisted outside the settings form
  // (like obsidian's `workflows`): it is tile state, not configuration.
  property string _activeOverride: ""
  readonly property string activeSymbol: {
    var a = _activeOverride.length > 0 ? _activeOverride : normSymbol(_str("active", ""));
    return watchlist.indexOf(a) >= 0 ? a : watchlist[0];
  }
  property string _winOverride: ""
  readonly property string winKey: _winOverride.length > 0 ? _winOverride : _str("window", "1D")
  readonly property int refreshSec: Math.max(30, _num("refreshSec", 60))
  readonly property string accent: _str("accent", "wallpaper")
  readonly property bool showGrid: _bool("showGrid", true)

  // drop an optimistic override once the persisted file catches up to it.
  onSettingsChanged: {
    if (_winOverride.length > 0 && _str("window", "1D") === _winOverride)
      _winOverride = "";
    if (_activeOverride.length > 0 && normSymbol(_str("active", "")) === _activeOverride)
      _activeOverride = "";
    if (_symbolsOverride.length > 0 && _str("symbols", "") === _symbolsOverride)
      _symbolsOverride = "";
  }

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
  readonly property var windowKeys: ["1D", "1W", "1M", "1Y"]

  // ── live quote state ────────────────────────────────────────────────────────
  // One enriched row per watchlist symbol: { sym, name, currency, market, kind,
  // price, prevClose, winBase, changeAbs, changePct, up, spark, times, error }.
  property var quotes: []

  // The active row, flattened (what the faces headline).
  property string sym: ""
  property string name: ""
  property string currency: "USD"
  property string market: ""
  property string kind: ""
  property real price: 0
  property real prevClose: 0
  // `winBase`, not `baseline`: Item.baseline is a FINAL anchor-line property.
  property real winBase: 0
  property real changePct: 0
  property real changeAbs: 0
  property var spark: []
  property var times: []
  property bool loading: false
  property string error: ""
  property double lastUpdated: 0

  readonly property bool up: changeAbs >= 0
  readonly property bool hasData: Array.isArray(spark) && spark.length > 1
  // Data exists at all (gates the "—" cold-start placeholders).
  readonly property bool priceReady: hasData || price > 0
  // Last refresh failed but older numbers are still on screen.
  readonly property bool stale: error.length > 0 && hasData
  // Semantic trend colours are fixed (green up, vermilion down). Theme.brand
  // follows the wallpaper accent, so it is deliberately NOT used here: a rising
  // asset must never read as a warning, and a falling one must stay red on any
  // wallpaper. Theme.sun is the fixed vermilion.
  readonly property color upColor: "#33d685"
  readonly property color downColor: Theme.sun
  readonly property color trendColor: up ? upColor : downColor
  function trendFor(isUp) { return isUp ? upColor : downColor; }

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

  // ── persistence (mirrors the obsidian service) ──────────────────────────────
  function pluginId() {
    var d = (pluginApi && pluginApi.pluginDir) ? String(pluginApi.pluginDir) : "";
    var parts = d.split("/").filter(p => p.length > 0);
    return parts.length > 0 ? parts[parts.length - 1] : "market";
  }
  function persist(obj) {
    if (!ready)
      return;
    persistProc.command = ["ryoku-plugins-place", pluginId(), "settings", JSON.stringify(obj)];
    persistProc.running = true;
  }
  Process { id: persistProc }

  function setWindow(k) {
    if (windowKeys.indexOf(k) < 0 || k === winKey)
      return;
    _winOverride = k;
    persist({ window: k });
  }
  function setActive(s) {
    var t = normSymbol(s);
    if (watchlist.indexOf(t) < 0 || t === activeSymbol)
      return;
    _activeOverride = t;
    persist({ active: t });
    _promote(t);
    refresh();
  }
  function setSymbols(text) {
    var list = parseSymbols(text);
    if (list.length === 0)
      return;
    var joined = list.join(", ");
    _symbolsOverride = joined;
    // keep the active instrument valid; fall back to the new list's head.
    var act = watchlist.indexOf(activeSymbol) >= 0 && list.indexOf(activeSymbol) >= 0
      ? activeSymbol : list[0];
    _activeOverride = act;
    persist({ symbols: joined, active: act });
  }

  // ── fetch/poll ──────────────────────────────────────────────────────────────
  function cmdPath() { return (pluginApi ? pluginApi.pluginDir : "") + "/bin/ryoku-market-fetch"; }

  function refresh() {
    if (!ready || fetchProc.running)
      return;
    loading = true;
    _stdout = "";
    // active first: the script gives the first symbol the full-resolution spark.
    var order = [activeSymbol];
    for (var i = 0; i < watchlist.length; i++)
      if (watchlist[i] !== activeSymbol)
        order.push(watchlist[i]);
    fetchProc.command = [cmdPath(), order.join(","), winCfg.range, winCfg.interval];
    fetchProc.running = true;
  }

  function _rowFor(s) {
    for (var i = 0; i < quotes.length; i++)
      if (quotes[i].sym === s)
        return quotes[i];
    return null;
  }

  // Shape one fetched quote into a row, with the window-aware baseline: prev
  // close for 1D, else the first in-window sample, so the change describes the
  // span the chart shows.
  function _enrich(q) {
    var sp = Array.isArray(q.spark) ? q.spark : [];
    var p = Number(q.price) || 0;
    var pc = Number(q.prevClose) || 0;
    var base = (winKey === "1D" || sp.length < 1) ? pc : (Number(sp[0]) || pc);
    var abs = p - base;
    return {
      sym: normSymbol(q.symbol), name: q.name || normSymbol(q.symbol),
      currency: q.currency || "USD", market: q.market || "", kind: q.kind || "",
      price: p, prevClose: pc, winBase: base,
      changeAbs: abs, changePct: base !== 0 ? abs / base * 100 : 0, up: abs >= 0,
      spark: sp, times: Array.isArray(q.times) ? q.times : [], error: ""
    };
  }

  // Flatten a row into the headline props the faces bind.
  function _promote(s) {
    var r = _rowFor(s);
    if (!r || r.error.length > 0 || !Array.isArray(r.spark))
      return;
    sym = r.sym; name = r.name; currency = r.currency;
    market = r.market; kind = r.kind;
    price = r.price; prevClose = r.prevClose; winBase = r.winBase;
    changeAbs = r.changeAbs; changePct = r.changePct;
    spark = r.spark; times = r.times;
  }

  property string _stdout: ""
  function _finish() {
    loading = false;
    var line = _stdout.split("\n").filter(l => l.trim().length > 0).pop() || "";
    if (line.length === 0) {
      error = qsTr("No response");
      return;
    }
    var d;
    try {
      d = JSON.parse(line);
    } catch (e) {
      error = qsTr("Parse error");
      return;
    }
    if (d.error) {
      // Whole-run failure: keep every last good value, just surface the message.
      error = String(d.error);
      return;
    }
    var fetched = Array.isArray(d.quotes) ? d.quotes : [];
    var bySym = {};
    for (var i = 0; i < fetched.length; i++)
      bySym[normSymbol(fetched[i].symbol || "")] = fetched[i];
    // Rebuild rows in watchlist order. A failed symbol keeps its last good row
    // (marked with the error) so one bad ticker never blanks the list.
    var out = [];
    var okCount = 0;
    for (var j = 0; j < watchlist.length; j++) {
      var s = watchlist[j];
      var q = bySym[s];
      if (!q)
        continue;
      if (q.error) {
        var old = _rowFor(s);
        if (old) {
          var kept = Object.assign({}, old);
          kept.error = String(q.error);
          out.push(kept);
        } else {
          out.push({ sym: s, name: s, currency: "USD", market: "", kind: "",
                     price: 0, prevClose: 0, winBase: 0, changeAbs: 0,
                     changePct: 0, up: true, spark: [], times: [],
                     error: String(q.error) });
        }
      } else {
        out.push(_enrich(q));
        okCount++;
      }
    }
    quotes = out;
    var act = _rowFor(activeSymbol);
    if (act && act.error.length === 0) {
      _promote(activeSymbol);
      error = "";
    } else {
      error = act ? act.error : qsTr("No data");
    }
    if (okCount > 0)
      lastUpdated = Date.now();
  }

  Process {
    id: fetchProc
    stdout: StdioCollector { onStreamFinished: root._stdout = text }
    onExited: root._finish()
  }

  // First fetch as soon as the dir is known; re-fetch when the watchlist or
  // window changes. refresh() no-ops while a fetch is in flight, so these can't
  // stack.
  onReadyChanged: if (ready) refresh();
  onWatchKeyChanged: if (ready) refresh();
  onWinKeyChanged: if (ready) refresh();

  Timer {
    interval: root.refreshSec * 1000
    running: root.ready
    repeat: true
    onTriggered: root.refresh()
  }

  // ── formatting + accent helpers ─────────────────────────────────────────────
  function currencySymbol(cur) {
    switch (cur) {
    case "USD": return "$";
    case "AUD": return "A$";
    case "CAD": return "C$";
    case "EUR": return "\u20ac";
    case "GBP": return "\u00a3";
    case "JPY": return "\u00a5";
    case "CNY": return "CN\u00a5";
    default: return cur && cur.length > 0 ? cur + " " : "";
    }
  }

  // Price with thousands separators; decimals scale with magnitude so a
  // sub-dollar coin still reads (0.0421) while BTC drops the cents ($59,952),
  // and a mid-priced equity keeps them ($1,234.56). `q` picks the instrument
  // (defaults to the active one); index levels are unit-less points, no prefix.
  function fmtPrice(v, q) {
    var cur = q ? (q.currency || "USD") : currency;
    var kd = q ? (q.kind || "") : kind;
    var neg = v < 0;
    var a = Math.abs(Number(v) || 0);
    var dec = a >= 10000 ? 0 : (a >= 1 ? 2 : 4);
    var pre = kd === "INDEX" ? "" : currencySymbol(cur);
    return (neg ? "-" : "") + pre + a.toLocaleString(Qt.locale(), 'f', dec);
  }

  function fmtPct(v) { return (Math.abs(Number(v) || 0)).toFixed(2) + "%"; }

  // Compact price for axis ticks: 1.2M / 60.1k / 294 / 0.0421. No currency
  // symbol (the axis is understood to be price), tuned to stay short. `span`
  // (the plotted hi-lo) sets the decimals from the tick STEP (span/3, the
  // four-tick axes' interval), so a quiet day still resolves ("1.83k .. 1.80k"
  // instead of four "1.8k") and every tick on one axis formats alike - a
  // per-tick threshold would flip only some of them near the boundary.
  function fmtCompact(v, span) {
    var a = Math.abs(Number(v) || 0);
    var step = Math.max(0, Number(span) || 0) / 3;
    if (a >= 1e6) return (a / 1e6).toFixed(step > 0 && step < 1e4 ? 3 : 2) + "M";
    if (a >= 1e3) return (a / 1e3).toFixed(step > 0 && step < 100 ? 2 : 1) + "k";
    if (a >= 100) return a.toFixed(step > 0 && step < 1 ? 1 : 0);
    if (a >= 1) return a.toFixed(step > 0 && step < 0.1 ? 2 : 1);
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

  // Wall-clock stamp for the "as of" line, from a Date.now() millis value.
  function fmtClock(ms) {
    var t = Number(ms) || 0;
    return t > 0 ? new Date(t).toLocaleTimeString(Qt.locale(), "hh:mm") : "";
  }

  // Session-state chrome for the meta line. Crypto has no session, so both
  // return empties and the dot simply doesn't render.
  function marketLabel(m) {
    switch (m) {
    case "OPEN":   return qsTr("OPEN");
    case "PRE":    return qsTr("PRE-MKT");
    case "POST":   return qsTr("AFTER-HRS");
    case "CLOSED": return qsTr("CLOSED");
    default:       return "";
    }
  }
  function marketColor(m) {
    switch (m) {
    case "OPEN": return upColor;
    case "PRE": case "POST": return Theme.gold;
    case "CLOSED": return Theme.faint;
    default: return Theme.faint;
    }
  }

  // Faces call this for chrome tints (window chips, active row tick, grid) so
  // the wallpaper vs brand vs mono choice lives in one place. Trend green/red
  // stays semantic (above).
  function accentColor() {
    return accent === "brand" ? Theme.sun
      : accent === "mono" ? Theme.cream
      : (Theme.accent !== undefined ? Theme.accent : Theme.brand);
  }
}
