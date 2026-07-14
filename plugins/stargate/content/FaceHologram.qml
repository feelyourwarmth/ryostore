pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets
import Ryoku.PluginKit.Singletons
import "gate.js" as Gate

/**
 * Hologram face: the gate as an Ancient holographic projection. Everything is
 * thin luminous line-work on transparent - concentric rings, radial ticks,
 * outline glyphs and chevrons - over a faint scanlined disc, with a subtle
 * flicker. Locked chevrons and their address glyphs bloom bright; the symbol
 * ring turns while dialing. A HUD data line reads the dialing computer out loud.
 *
 * Square by construction, like a projected ring.
 */
Item {
    id: root

    property var service: null
    property real s: 1
    property real cw: 360
    property bool active: true

    implicitWidth: cw
    implicitHeight: cw

    readonly property real d: Math.min(width, height)
    readonly property real cx: width / 2
    readonly property real cy: height / 2

    readonly property var address: service ? service.address : []
    readonly property int locked: service ? service.locked : 0
    readonly property bool established: service ? service.established : true
    readonly property string family: service ? service.glyphFamily : ""

    readonly property color tint: (service && service.wallustGlow)
        ? Qt.tint("#3fe0ff", Qt.rgba(Wallust.accent.r, Wallust.accent.g, Wallust.accent.b, 0.55))
        : "#3fe0ff"
    readonly property color energized: "#ffb648"

    Item {
        id: gate
        width: root.d; height: root.d
        anchors.centerIn: parent

        readonly property real r: root.d / 2

        // faint holographic flicker on the whole projection.
        opacity: 0.94
        SequentialAnimation on opacity {
            running: root.active
            loops: Animation.Infinite
            NumberAnimation { to: 1.0; duration: 1700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.9; duration: 1300; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.97; duration: 90 }
            NumberAnimation { to: 0.9; duration: 70 }
        }

        // scanlined projection disc.
        ClippingRectangle {
            anchors.centerIn: parent
            width: gate.r * 2 * 0.62; height: width; radius: width / 2
            color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, root.established ? 0.10 : 0.05)
            Behavior on color { ColorAnimation { duration: 400 } }

            Column {
                id: scan
                width: parent.width
                spacing: Math.max(2, root.d * 0.014)
                property real drift: 0
                y: -drift
                Repeater {
                    model: Math.ceil(gate.r * 2 / Math.max(3, root.d * 0.022)) + 8
                    delegate: Rectangle {
                        width: scan.width; height: 1
                        color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.16)
                    }
                }
                NumberAnimation on drift {
                    from: 0; to: root.d * 0.028 + 2; duration: 2600
                    loops: Animation.Infinite; running: root.active
                }
            }
            Rectangle {
                id: sweepBeam
                width: parent.width
                height: Math.max(2, gate.r * 0.05)
                y: 0
                opacity: root.established ? 0.55 : 0.3
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.6) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                NumberAnimation on y {
                    from: -sweepBeam.height; to: gate.r * 2 * 0.62
                    duration: 3400; loops: Animation.Infinite; running: root.active
                }
            }
        }

        // concentric rings.
        HoloRing { dia: gate.r * 2 * 0.98; coreW: Math.max(1, root.d * 0.006); coreA: 0.85 }
        HoloRing { dia: gate.r * 2 * 0.86; coreW: Math.max(1, root.d * 0.004); coreA: 0.55 }
        HoloRing { dia: gate.r * 2 * 0.62; coreW: Math.max(1, root.d * 0.005); coreA: 0.7 }

        // radial ticks at every glyph slot.
        Repeater {
            model: Gate.GLYPHS
            delegate: Item {
                required property int index
                anchors.fill: parent
                rotation: index * (360 / Gate.GLYPHS)
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: gate.r * (1 - 0.92)
                    width: Math.max(1, root.d * 0.004)
                    height: root.d * 0.028
                    color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.5)
                }
            }
        }

        // symbol ring, turning while dialing.
        Item {
            anchors.fill: parent
            rotation: root.service ? root.service.spin : 0
            Behavior on rotation { NumberAnimation { duration: 430; easing.type: Easing.OutCubic } }

            Repeater {
                model: Gate.GLYPHS
                delegate: Item {
                    id: arm
                    required property int index
                    anchors.fill: parent
                    rotation: index * (360 / Gate.GLYPHS)
                    readonly property int slot: root.address ? root.address.indexOf(arm.index) : -1
                    readonly property bool active: arm.slot >= 0 && arm.slot < root.locked

                    GateGlyph {
                        width: root.d * 0.066
                        height: width
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: root.d * 0.075
                        index: arm.index
                        family: root.family
                        glyphColor: arm.active ? root.energized : root.tint
                        lit: arm.active ? 1 : 0.28
                    }
                }
            }
        }

        // nine chevron outlines.
        Repeater {
            model: 9
            delegate: Item {
                id: chev
                required property int index
                anchors.fill: parent
                rotation: chev.index * 40
                GateChevron {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: -root.d * 0.008
                    unit: root.d * (chev.index === 0 ? 0.094 : 0.074)
                    lit: chev.index < root.locked
                    primary: chev.index === 0
                    style: "holo"
                    tint: root.tint
                    litColor: root.energized
                }
            }
        }
    }

    // HUD data line.
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2 * root.s
        visible: root.service && (root.service.showTime || root.service.showDesignation)

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.service && root.service.showTime
            text: root.service ? root.service.timeText : ""
            color: root.tint
            font.family: Theme.mono
            font.pixelSize: root.d * 0.10
            font.weight: Font.Light
            font.letterSpacing: 2 * root.s
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.service && root.service.showDesignation
            text: root.established
                  ? (root.service ? root.service.designation : "") + " \u00b7 LINK OPEN"
                  : "CHEVRON " + Math.max(1, root.locked) + " \u00b7 ENCODED"
            color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.85)
            font.family: Theme.mono
            font.pixelSize: root.d * 0.033
            font.weight: Font.Medium
            font.letterSpacing: 1.5 * root.s
        }
    }

    // ── inline helpers ───────────────────────────────────────────────────────
    component HoloRing: Item {
        id: hr
        property real dia: 100
        property real coreW: 1
        property real coreA: 0.7
        anchors.fill: parent
        Rectangle {
            anchors.centerIn: parent
            width: hr.dia; height: width; radius: width / 2
            color: "transparent"
            border.width: hr.coreW * 3.5
            border.color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.10)
        }
        Rectangle {
            anchors.centerIn: parent
            width: hr.dia; height: width; radius: width / 2
            color: "transparent"
            border.width: hr.coreW
            border.color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, hr.coreA)
        }
    }
}
