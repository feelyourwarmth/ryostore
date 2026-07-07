pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// The Ryoku brutalist surface: a SHARP-cornered flat face with a hairline border
// and a hard offset shadow (a solid black rectangle pushed down-right, no blur).
// Depth from the offset, never a gradient or glow. Reg ticks frame it like a
// specimen sheet. Children stack in the padded body Column; the panel sizes to
// them and reserves room for the shadow so a parent never clips it.
Item {
    id: panel

    property real s: 1
    property real w: 320
    property real step: Math.round(7 * s)
    property real pad: 15 * s
    property real spacing: 13 * s
    property color surface: Theme.cardTop
    property bool ticks: true
    default property alias content: body.data

    implicitWidth: panel.w + panel.step
    implicitHeight: face.height + panel.step

    Rectangle {
        x: panel.step
        y: panel.step
        width: panel.w
        height: face.height
        color: Theme.shadow
        antialiasing: false
    }

    Rectangle {
        id: face
        width: panel.w
        height: body.implicitHeight + panel.pad * 2
        color: panel.surface
        radius: 0
        border.width: 1
        border.color: Theme.lineStrong
        antialiasing: false

        CornerTicks {
            visible: panel.ticks
            anchors.fill: parent
            anchors.margins: 6 * panel.s
            s: panel.s
            tint: Theme.hair
        }

        Column {
            id: body
            x: panel.pad
            y: panel.pad
            width: face.width - panel.pad * 2
            spacing: panel.spacing
        }
    }
}
