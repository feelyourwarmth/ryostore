pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Ryoku.PluginKit.Singletons

/**
 * Obsidian plugin service: headless detection + settings resolver + workflow
 * model + the run() dispatch that shells out to bin/ryoku-obsidian. The
 * desktop-widget host keeps one alive across mounts and hands it to the content
 * as pluginApi.mainInstance, so the setup flow, the block canvas, and the
 * capture bar all read one truth.
 *
 * Local-first: every action reads the user's own vault config off disk and
 * writes notes on disk; the only thing that leaves is the obsidian:// URI handed
 * to xdg-open. Nothing runs until a vault is chosen.
 *
 * Plugin settings are NOT auto-seeded from the manifest at runtime, so every
 * value is read behind a default (resolver matches plugins/photo-frame). vault /
 * inbox / workflows are edited on the tile and persisted with ryoku-plugins-place;
 * an optimistic override makes those edits feel instant before the file-watch
 * round-trips.
 */
Item {
    id: root

    property var pluginApi
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null
    // pluginDir (and the command path built from it) is empty until the host
    // wires pluginApi after this service loads. Gate the first detect on it.
    readonly property bool ready: !!(pluginApi && pluginApi.pluginDir && pluginApi.pluginDir.length > 0)

    function _has(k) {
        return settings && settings[k] !== undefined && settings[k] !== null && settings[k] !== "";
    }
    function _str(k, d) { return _has(k) ? String(settings[k]) : d; }

    function cmd() { return (pluginApi ? pluginApi.pluginDir : "") + "/bin/ryoku-obsidian"; }
    function pluginId() {
        var d = (pluginApi && pluginApi.pluginDir) ? String(pluginApi.pluginDir) : "";
        var parts = d.split("/").filter(p => p.length > 0);
        return parts.length > 0 ? parts[parts.length - 1] : "obsidian";
    }

    // ── settings (behind defaults, with optimistic overrides) ───────────────────
    property string _vaultOverride: ""
    property string _wfOverride: ""
    readonly property string vault: _vaultOverride.length > 0 ? _vaultOverride : _str("vault", "")
    readonly property string inbox: _str("inbox", "")
    readonly property string accent: _str("accent", "brand")
    readonly property string wfRaw: _wfOverride.length > 0 ? _wfOverride : _str("workflows", "[]")

    readonly property string vaultName: {
        var p = vault.replace(/\/+$/, "");
        var i = p.lastIndexOf("/");
        return i >= 0 ? p.substring(i + 1) : p;
    }

    // drop an optimistic override once the persisted file catches up to it.
    onSettingsChanged: {
        if (_vaultOverride.length > 0 && _str("vault", "") === _vaultOverride)
            _vaultOverride = "";
        if (_wfOverride.length > 0 && _str("workflows", "[]") === _wfOverride)
            _wfOverride = "";
    }

    // ── workflow model ──────────────────────────────────────────────────────────
    // Each workflow block: { id, label, icon, action, note, template }.
    //   action: daily | open | appendText | appendTask | screenshot | audio
    //   note:   target relpath ("" = today's daily for capture actions)
    readonly property var workflowList: {
        try {
            var a = JSON.parse(wfRaw);
            return Array.isArray(a) ? a : [];
        } catch (e) {
            return [];
        }
    }

    function newId() { return "w" + Date.now().toString(36) + Math.floor(Math.random() * 1296).toString(36); }

    function persist(obj) {
        if (!ready)
            return;
        persistProc.command = ["ryoku-plugins-place", pluginId(), "settings", JSON.stringify(obj)];
        persistProc.running = true;
    }
    function setVault(p) { _vaultOverride = p; persist({ vault: p }); redetect(); }
    function setInbox(rel) { persist({ inbox: rel }); }
    function saveWorkflows(arr) {
        var s = JSON.stringify(arr);
        _wfOverride = s;
        persist({ workflows: s });
    }
    function addWorkflow(b) {
        var arr = workflowList.slice();
        b.id = b.id || newId();
        arr.push(b);
        saveWorkflows(arr);
    }
    function updateWorkflow(id, b) {
        var arr = workflowList.map(w => w.id === id ? Object.assign({}, w, b, { id: id }) : w);
        saveWorkflows(arr);
    }
    function removeWorkflow(id) { saveWorkflows(workflowList.filter(w => w.id !== id)); }
    function moveWorkflow(id, dir) {
        var arr = workflowList.slice();
        var i = arr.findIndex(w => w.id === id);
        var j = i + dir;
        if (i < 0 || j < 0 || j >= arr.length)
            return;
        var t = arr[i]; arr[i] = arr[j]; arr[j] = t;
        saveWorkflows(arr);
    }

    Process { id: persistProc }

    // ── detection ────────────────────────────────────────────────────────────────
    property bool detected: false
    property bool installed: false
    property string launcher: ""
    property var vaults: []

    readonly property string phase: {
        if (!detected) return "loading";
        if (vault.length > 0) return "ready";     // a configured vault always wins
        if (!installed) return "notInstalled";
        return "noVault";
    }

    function redetect() {
        if (!ready || detectProc.running)
            return;
        detectProc.command = [cmd(), "detect"];
        detectProc.running = true;
    }
    property string _detOut: ""
    Process {
        id: detectProc
        stdout: StdioCollector { onStreamFinished: root._detOut = text }
        onExited: {
            try {
                var d = JSON.parse((root._detOut.split("\n").filter(l => l.trim().length > 0).pop()) || "{}");
                root.installed = d.installed === true;
                root.launcher = d.launcher || "";
                root.vaults = Array.isArray(d.vaults) ? d.vaults : [];
            } catch (e) {
                root.vaults = [];
            }
            root.detected = true;
            root._detOut = "";
        }
    }

    onReadyChanged: if (ready) { redetect(); refreshVaultInfo(); refreshTemplates(); }
    // keep looking while unconfigured (cheap: a file read + command -v); stop
    // once a vault is chosen.
    Timer {
        interval: 25000
        running: root.ready && root.phase !== "ready"
        repeat: true
        onTriggered: root.redetect()
    }

    // ── vault info (daily folder/format/template + attachments) ──────────────────
    property var vaultInfo: null
    readonly property string dailyRel: (vaultInfo && vaultInfo.dailyRel) ? vaultInfo.dailyRel : ""
    function refreshVaultInfo() {
        if (!ready || vault.length === 0 || infoProc.running)
            return;
        infoProc.command = [cmd(), "vault-info", vault];
        infoProc.running = true;
    }
    onVaultChanged: if (ready && vault.length > 0) { refreshVaultInfo(); refreshTemplates(); refreshGraph(); }
    property string _infoOut: ""
    Process {
        id: infoProc
        stdout: StdioCollector { onStreamFinished: root._infoOut = text }
        onExited: {
            try {
                var d = JSON.parse((root._infoOut.split("\n").filter(l => l.trim().length > 0).pop()) || "{}");
                root.vaultInfo = d.error ? null : d;
            } catch (e) {
                root.vaultInfo = null;
            }
            root._infoOut = "";
        }
    }

    // ── note list (for the picker) ───────────────────────────────────────────────
    property var notes: []
    property bool notesLoading: false
    function refreshNotes(query) {
        if (!ready || vault.length === 0)
            return;
        notesLoading = true;
        notesProc.command = [cmd(), "list-notes", vault, query || "", "80"];
        notesProc.running = true;
    }
    property string _notesOut: ""
    Process {
        id: notesProc
        stdout: StdioCollector { onStreamFinished: root._notesOut = text }
        onExited: {
            try {
                var d = JSON.parse((root._notesOut.split("\n").filter(l => l.trim().length > 0).pop()) || "{}");
                root.notes = Array.isArray(d.notes) ? d.notes : [];
            } catch (e) {
                root.notes = [];
            }
            root.notesLoading = false;
            root._notesOut = "";
        }
    }

    // ── templates (for the block editor's per-action template choice) ────────────
    property var templates: []
    function refreshTemplates() {
        if (!ready || vault.length === 0)
            return;
        tplProc.command = [cmd(), "templates", vault];
        tplProc.running = true;
    }
    property string _tplOut: ""
    Process {
        id: tplProc
        stdout: StdioCollector { onStreamFinished: root._tplOut = text }
        onExited: {
            try {
                var d = JSON.parse((root._tplOut.split("\n").filter(l => l.trim().length > 0).pop()) || "{}");
                root.templates = Array.isArray(d.templates) ? d.templates : [];
            } catch (e) {
                root.templates = [];
            }
            root._tplOut = "";
        }
    }

    // ── graph overview (nodes = notes, edges = [[wikilinks]]) ────────────────────
    property var graphData: ({ nodes: [], links: [] })
    property bool graphLoading: false
    function refreshGraph() {
        if (!ready || vault.length === 0)
            return;
        graphLoading = true;
        graphProc.command = [cmd(), "graph", vault, "48"];
        graphProc.running = true;
    }
    property string _graphOut: ""
    Process {
        id: graphProc
        stdout: StdioCollector { onStreamFinished: root._graphOut = text }
        onExited: {
            try {
                var d = JSON.parse((root._graphOut.split("\n").filter(l => l.trim().length > 0).pop()) || "{}");
                root.graphData = d.nodes ? d : ({ nodes: [], links: [] });
            } catch (e) {
                root.graphData = ({ nodes: [], links: [] });
            }
            root.graphLoading = false;
            root._graphOut = "";
        }
    }

    // ── status feedback ──────────────────────────────────────────────────────────
    // a short-lived line the tile shows after an action, so a silent capture or
    // a screenshot never feels like it did nothing.
    property string status: ""
    function flash(msg) { status = msg; statusTimer.restart(); }
    Timer { id: statusTimer; interval: 2600; onTriggered: root.status = "" }

    // ── actions ──────────────────────────────────────────────────────────────────
    property string _runMsg: ""
    property string _shotWhere: ""
    function openDaily() {
        if (!ready) return;
        _runMsg = qsTr("opened today");
        runProc.command = [cmd(), "daily", vault, vaultName];
        runProc.running = true;
    }
    function openNote(rel) {
        if (!ready || !rel) return;
        _runMsg = qsTr("opened %1").arg(rel.split("/").pop());
        runProc.command = [cmd(), "open", vaultName, rel];
        runProc.running = true;
    }
    // create the note from a template if missing (any block that opens a note),
    // then open it. An existing note just opens; an empty template = a blank note.
    function openNoteFromTemplate(rel, tpl) {
        if (!ready || !rel) return;
        _runMsg = qsTr("opened %1").arg(rel.split("/").pop());
        runProc.command = [cmd(), "note", vault, vaultName, rel, tpl || ""];
        runProc.running = true;
    }
    function appendNote(rel, text, asTask) {
        if (!ready || !text || text.length === 0) return;
        var body = asTask ? ("- [ ] " + text) : text;
        var where = (!rel || rel.length === 0) ? qsTr("today") : rel.replace(/\.md$/, "").split("/").pop();
        _runMsg = asTask ? qsTr("task → %1").arg(where) : qsTr("saved → %1").arg(where);
        runProc.command = [cmd(), "append", vault, vaultName, rel || "", body];
        runProc.running = true;
    }
    function shot(rel) {
        if (!ready || shotProc.running) return;
        _shotWhere = (!rel || rel.length === 0) ? qsTr("today") : rel.replace(/\.md$/, "").split("/").pop();
        flash(qsTr("drag a region…"));
        shotProc.command = [cmd(), "screenshot", vault, vaultName, rel || ""];
        shotProc.running = true;
    }
    property string _runOut: ""
    Process {
        id: runProc
        stdout: StdioCollector { onStreamFinished: root._runOut = text }
        onExited: {
            var e = "";
            try { var d = JSON.parse((root._runOut.split("\n").filter(l => l.trim().length > 0).pop()) || "{}"); e = d.error || ""; } catch (x) {}
            root.flash(e.length > 0 ? e : root._runMsg);
            root._runOut = "";
        }
    }
    property string _shotOut: ""
    Process {
        id: shotProc
        stdout: StdioCollector { onStreamFinished: root._shotOut = text }
        onExited: {
            var msg = qsTr("shot → %1").arg(root._shotWhere);
            try { var d = JSON.parse((root._shotOut.split("\n").filter(l => l.trim().length > 0).pop()) || "{}"); if (d.error) msg = d.error; } catch (x) {}
            root.flash(msg);
            root._shotOut = "";
        }
    }

    // ── audio capture lifecycle ──────────────────────────────────────────────────
    property bool recording: false
    property string recordNote: ""
    property string recordOut: ""
    function stamp() {
        var d = new Date();
        function p(n) { return (n < 10 ? "0" : "") + n; }
        return "" + d.getFullYear() + p(d.getMonth() + 1) + p(d.getDate())
            + p(d.getHours()) + p(d.getMinutes()) + p(d.getSeconds());
    }
    function startRecord(rel) {
        if (!ready || recording) return;
        recordNote = rel || "";
        recordOut = qsTr("Recording %1.ogg").arg(stamp());
        recordProc.command = [cmd(), "record-audio", vault, recordOut];
        recordProc.running = true;
        recording = true;
        flash(qsTr("recording…"));
    }
    function stopRecord() {
        if (recording)
            recordProc.running = false;   // SIGTERM -> wrapper finalises the .ogg
    }
    function toggleRecord(rel) { recording ? stopRecord() : startRecord(rel); }
    property string _recOut: ""
    Process {
        id: recordProc
        stdout: StdioCollector { onStreamFinished: root._recOut = text }
        onExited: {
            root.recording = false;
            var ok = false;
            try {
                var d = JSON.parse((root._recOut.split("\n").filter(l => l.trim().length > 0).pop()) || "{}");
                ok = d.ok === true;
            } catch (e) {}
            if (ok)
                root.appendNote(root.recordNote, "![[" + root.recordOut + "]]", false);
            root._recOut = "";
        }
    }

    // Run a workflow block. Capture-with-text blocks (appendText/appendTask) need
    // a typed value, so the content opens its capture bar for those; everything
    // else fires here.
    function run(b) {
        if (!ready || !b) return;
        switch (b.action) {
        case "daily":      openDaily(); break;
        case "open":
            if (b.note && b.note.length > 0) openNoteFromTemplate(b.note, b.template);
            else openDaily();
            break;
        case "screenshot": shot(b.note); break;
        case "audio":      toggleRecord(b.note); break;
        }
    }

    // chrome tint. A desktop widget must read on any wallpaper, so the default
    // "brand" is the FIXED vermillion (Theme.sun/verm), never the wallust accent
    // that can wash out to grey on a muted wallpaper. wallust/mono are opt-in.
    function accentColor() {
        return accent === "wallust" ? (Wallust.accent !== undefined ? Wallust.accent : Theme.sun)
            : accent === "mono" ? Theme.cream
            : Theme.sun;   // "brand" = the FIXED red-sun vermillion (#e2342a)
    }
}
