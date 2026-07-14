import QtQuick
import Quickshell
import "../content/gate.js" as Gate

/**
 * Stargate service: the headless brain the desktop-widget host keeps alive and
 * hands to the content as pluginApi.mainInstance. It owns everything the faces
 * read and never draws anything itself:
 *
 *  - resolved settings (behind defaults, so the widget works out of the box),
 *  - the loaded glyph font (FontLoader) and whether to fall back to procedural
 *    constellations,
 *  - the live clock and the current gate address it encodes,
 *  - the dial state machine (which chevrons are locked, the ring's turn, whether
 *    the wormhole is open) that drives every face's animation in lock-step.
 */
Item {
    id: root

    property var pluginApi
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null

    function _has(k) { return settings && settings[k] !== undefined && settings[k] !== null && settings[k] !== ""; }
    function _str(k, d) { return _has(k) ? String(settings[k]) : d; }
    function _num(k, d) { return _has(k) ? Number(settings[k]) : d; }
    function _bool(k, d) {
        if (!settings || settings[k] === undefined || settings[k] === null) return d;
        return settings[k] === true || settings[k] === "true";
    }

    // ── resolved settings ────────────────────────────────────────────────────
    readonly property string design: _str("design", "naquadah")
    readonly property string mode: _str("mode", "clock")
    readonly property bool animate: _bool("animate", true)
    readonly property bool showTime: _bool("showTime", true)
    readonly property bool showDesignation: _bool("showDesignation", true)
    readonly property bool wallustGlow: _bool("wallustGlow", false)
    // Inscription face: free text the user types, transliterated to gate glyphs.
    readonly property string text: _str("text", "chevron seven locked")
    readonly property bool showTranslation: _bool("showTranslation", true)

    // ── glyph font ───────────────────────────────────────────────────────────
    // glyphSet picks a look; an installed cap_resources font is used by its known
    // family name. glyphFontPath overrides with a file the user points at (loaded
    // live via FontLoader) or a bare installed family name.
    readonly property string glyphSet: _str("glyphSet", "procedural")
    readonly property string glyphFontPath: _str("glyphFontPath", "").trim()

    readonly property bool _pathLike: glyphFontPath.length > 0
        && (glyphFontPath.indexOf("/") >= 0 || glyphFontPath.indexOf("~") === 0
            || /\.(ttf|otf|ttc)$/i.test(glyphFontPath))

    readonly property url _fontUrl: {
        if (!_pathLike) return "";
        var p = glyphFontPath;
        if (p.indexOf("://") >= 0) return p;
        if (p.indexOf("~/") === 0) p = (Quickshell.env("HOME") || "") + p.substring(1);
        return "file://" + p;
    }

    FontLoader { id: fontLoader; source: root._fontUrl }

    // The family the faces should render glyphs in; empty means fall back to the
    // procedural constellation renderer (never a blank cell).
    readonly property string glyphFamily: {
        if (_pathLike) return fontLoader.status === FontLoader.Ready ? fontLoader.name : "";
        if (glyphFontPath.length > 0) return glyphFontPath;           // bare installed family
        if (glyphSet !== "procedural") return Gate.family(glyphSet);  // known set family
        return "";
    }
    readonly property bool useProcedural: glyphFamily.length === 0

    // ── live clock + address ─────────────────────────────────────────────────
    property var now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    readonly property string timeText: Qt.formatTime(now, "HH:mm")
    readonly property string secText: Qt.formatTime(now, "ss")
    readonly property string dateText: Qt.formatDate(now, "ddd dd MMM").toUpperCase()

    // seed is an int, so it only signals a change when the minute (clock) or day
    // (date) rolls over - not every one-second tick. address/designation follow.
    readonly property int seed: Gate.seedFor(now, mode)
    readonly property var address: Gate.address(seed, 6)
    readonly property string designation: Gate.designation(address)
    readonly property int total: address ? address.length : 6

    // ── dial state machine ───────────────────────────────────────────────────
    property int locked: 0
    property string phase: "open"          // "dialing" | "open"
    property real spin: 0                   // ring turn the faces animate toward
    readonly property bool established: phase === "open"
    readonly property real progress: total > 0 ? locked / total : 0

    Timer {
        id: dialTimer
        interval: 470; repeat: true; running: false
        onTriggered: root._step()
    }

    function _beginDial() {
        if (root.design === "inscription") { root.locked = root.total; root.phase = "open"; return; }
        if (!animate) { root.locked = root.total; root.phase = "open"; return; }
        root.locked = 0;
        root.phase = "dialing";
        root.spin += 47;
        dialTimer.restart();
    }
    function _step() {
        if (root.locked < root.total) {
            root.locked += 1;
            root.spin += 41 + (root.locked % 2 === 0 ? 23 : -13);
        } else {
            dialTimer.stop();
            root.phase = "open";
        }
    }

    onAddressChanged: root._beginDial()
    Component.onCompleted: root._beginDial()

    // A user "dial now" from a face menu can re-run the sequence on demand.
    function redial() { root._beginDial(); }
}
