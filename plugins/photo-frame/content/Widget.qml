pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

/**
 * Photo Frame, as one adaptive view. The host sets `density`, `s`, `widthBudget`,
 * `active`, and `pluginApi`; the desktop-widget host renders at `compact` with a
 * 360px width budget and wraps the tile in its own draggable card. Every visible
 * density shows the same framed photo (PhotoFrame) sized from the host's width
 * budget; `glyph` collapses to a single mark.
 *
 * All photo settings (source, style, aspect, filter, caption, shadow) are
 * resolved by the service (pluginApi.mainInstance) behind defaults, so the widget
 * renders the bundled sample out of the box and updates live as settings change.
 */
Item {
    id: root

    property var pluginApi
    property var screen
    property bool active
    property string density: "compact"
    property real s: 1
    property real widthBudget: 0

    readonly property var service: pluginApi ? pluginApi.mainInstance : null

    // One resolved print width per density. `compact`/`full` honour the host's
    // width budget (with a sane fallback); `glyph` is a fixed mark.
    readonly property real contentW: density === "glyph" ? 26 * s
        : (widthBudget > 0 ? widthBudget : (density === "full" ? 460 * s : 320 * s))

    implicitWidth: contentW
    implicitHeight: density === "glyph" ? 26 * s : photo.implicitHeight

    GlyphIcon {
        visible: root.density === "glyph"
        anchors.fill: parent
        name: "image"
        color: Theme.iconDim
        stroke: 1.6
    }

    PhotoFrame {
        id: photo
        visible: root.density !== "glyph"
        width: root.contentW
        baseW: root.contentW
        s: root.s
        source: root.service ? root.service.source : ""
        style: root.service ? root.service.style : "rounded"
        filter: root.service ? root.service.filter : "none"
        aspect: root.service ? root.service.aspect : "4:3"
        caption: root.service ? root.service.caption : ""
        shadowEnabled: root.service ? root.service.shadowEnabled : true
        shadowBlur: root.service ? root.service.shadowBlur : 0.55
        shadowOffset: root.service ? root.service.shadowOffset : 8
        shadowOpacity: root.service ? root.service.shadowOpacity : 0.45
    }
}
