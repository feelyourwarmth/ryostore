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
        radius: root.service ? root.service.radius : 18
        frame: root.service ? root.service.frame : 14

        // A real click (not a drag, not a right-click) asks the host to show
        // this photo large + centered. gesturePolicy DragThreshold keeps the
        // tile draggable: a press that becomes a drag never counts as a tap, so
        // the grip MouseArea under the content still moves the tile, and
        // RightButton is left to the grip's menu. No-op on hosts that do not
        // provide the viewer (expandImage absent).
        TapHandler {
            acceptedButtons: Qt.LeftButton
            gesturePolicy: TapHandler.DragThreshold
            onTapped: {
                if (root.service && root.pluginApi && typeof root.pluginApi.expandImage === "function")
                    root.pluginApi.expandImage(root.service.source);
            }
        }
    }
}
