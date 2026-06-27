import QtQuick
import Quickshell

/**
 * Photo Frame configuration resolver. The desktop-widget host keeps one instance
 * alive and hands it to the content as pluginApi.mainInstance. Plugin settings
 * are NOT auto-seeded from the manifest at runtime (discover.sh merges only the
 * user's plugins.json), so every value is read here behind a default: the widget
 * renders the bundled sample with a rounded frame and a soft shadow out of the
 * box, and each field the user sets (in plugins.json or the settings page)
 * overrides its default.
 *
 * Host-agnostic and headless: it owns no UI, only the resolved photo source and
 * the resolved style/shadow/filter values the content reads.
 */
Item {
    id: root

    property var pluginApi
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null

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

    // Raw configured path: empty, a bare absolute path, ~/relative, or a url.
    readonly property string imagePath: _str("imagePath", "")

    // Effective image url. An empty path falls back to the bundled sample so the
    // widget is never blank; a url is used verbatim; ~/ is expanded; a bare path
    // becomes a file url.
    readonly property url source: {
        var p = imagePath.trim();
        if (p.length === 0)
            return (pluginApi && pluginApi.pluginDir) ? ("file://" + pluginApi.pluginDir + "/assets/example.jpg") : "";
        if (p.indexOf("://") >= 0)
            return p;
        if (p.indexOf("~/") === 0)
            p = (Quickshell.env("HOME") || "") + p.substring(1);
        return "file://" + p;
    }

    readonly property string style: _str("style", "rounded")
    readonly property string aspect: _str("aspect", "4:3")
    readonly property string filter: _str("filter", "none")
    readonly property string caption: _str("caption", "")

    readonly property bool shadowEnabled: _bool("shadowEnabled", true)
    readonly property real shadowBlur: _num("shadowBlur", 0.55)
    readonly property real shadowOffset: _num("shadowOffset", 8)
    readonly property real shadowOpacity: _num("shadowOpacity", 0.45)
    readonly property real radius: _num("radius", 18)
    readonly property real frame: _num("frame", 14)
}
