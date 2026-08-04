pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Ryoku.PluginKit.Singletons
import "gate.js" as Gate

/**
 * Naquadah face: the cinematic Milky Way gate. A metallic ring carries the
 * symbol band of constellation glyphs; nine chevrons ring the housing and lock
 * red in sequence as the address dials; the event horizon opens as a shimmering
 * blue puddle. The symbol ring turns during dialing (service.spin) and the ring
 * glyphs that belong to the address light up one per chevron lock.
 *
 * Square by construction: implicitHeight tracks the content width so the host
 * places a round gate on the wallpaper.
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
    readonly property real progress: service ? service.progress : 1
    readonly property string family: service ? service.glyphFamily : ""

    // energy colour: canonical event-horizon cyan, optionally pulled toward the
    // wallpaper accent.
    readonly property color energy: (service && service.wallpaperGlow)
        ? Qt.tint("#3fb8ff", Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5))
        : "#3fb8ff"

    // ── the gate ─────────────────────────────────────────────────────────────
    Item {
        id: gate
        width: root.d; height: root.d
        anchors.centerIn: parent

        readonly property real r: root.d / 2

        // ── metal ring (concentric circles, lit from the top) ────────────────
        Rectangle {                              // outer housing rim
            anchors.centerIn: parent
            width: gate.r * 2; height: width; radius: width / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#5b616d" }
                GradientStop { position: 0.5; color: "#33373f" }
                GradientStop { position: 1.0; color: "#191c22" }
            }
        }
        Rectangle {                              // bright bevel edge
            anchors.centerIn: parent
            width: gate.r * 2 * 0.965; height: width; radius: width / 2
            color: "transparent"
            border.width: Math.max(1, root.d * 0.006)
            border.color: Qt.rgba(1, 1, 1, 0.10)
        }
        Rectangle {                              // symbol track recess
            anchors.centerIn: parent
            width: gate.r * 2 * 0.90; height: width; radius: width / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#23272f" }
                GradientStop { position: 1.0; color: "#0f1218" }
            }
        }
        Rectangle {                              // inner metal lip around the puddle
            anchors.centerIn: parent
            width: gate.r * 2 * 0.635; height: width; radius: width / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#4a4f5a" }
                GradientStop { position: 1.0; color: "#191c22" }
            }
        }
        Rectangle {                              // dark recess: the gate room behind the puddle
            anchors.centerIn: parent
            width: gate.r * 2 * 0.60; height: width; radius: width / 2
            color: "#04060b"
        }
        // event horizon: on top of the recess, inside the metal lip.
        EventHorizon {
            anchors.centerIn: parent
            diameter: gate.r * 2 * 0.60
            energy: root.energy
            open: root.established
            progress: root.progress
            live: root.active
        }

        // ── the symbol band: 36 constellation glyphs, turning while dialing ──
        Item {
            id: symbolRing
            anchors.fill: parent
            rotation: root.service ? root.service.spin : 0
            Behavior on rotation { NumberAnimation { duration: 430; easing.type: Easing.OutCubic } }

            // segment ridges between the gate cells.
            Repeater {
                model: Gate.GLYPHS
                delegate: Item {
                    required property int index
                    anchors.fill: parent
                    rotation: (index + 0.5) * (360 / Gate.GLYPHS)
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: root.d * 0.045
                        width: Math.max(1, root.d * 0.0035)
                        height: root.d * 0.082
                        color: Qt.rgba(1, 1, 1, 0.055)
                    }
                }
            }

            Repeater {
                model: Gate.GLYPHS
                delegate: Item {
                    id: arm
                    required property int index
                    anchors.fill: parent
                    rotation: index * (360 / Gate.GLYPHS)

                    // where this glyph sits in the current address (-1 if absent),
                    // and whether its chevron has locked yet.
                    readonly property int slot: root.address ? root.address.indexOf(arm.index) : -1
                    readonly property bool onAddr: slot >= 0
                    readonly property bool active: onAddr && slot < root.locked

                    GateGlyph {
                        width: root.d * 0.072
                        height: width
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: root.d * 0.055
                        index: arm.index
                        family: root.family
                        glyphColor: arm.active ? "#eaf6ff" : "#7f8ba6"
                        lit: arm.active ? 1 : 0.34
                    }
                }
            }
        }

        // ── nine chevrons on the housing ─────────────────────────────────────
        Repeater {
            model: 9
            delegate: Item {
                id: chev
                required property int index
                anchors.fill: parent
                // chevron 0 at top (12 o'clock), the rest every 40 degrees.
                rotation: chev.index * 40
                readonly property bool lit: chev.index < root.locked
                readonly property bool primary: chev.index === 0

                GateChevron {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: -root.d * 0.030
                    unit: root.d * (chev.primary ? 0.11 : 0.088)
                    lit: chev.lit
                    primary: chev.primary
                    style: "metal"
                }
            }
        }

        // kawoosh: a one-shot bright bloom when the wormhole establishes.
        Shape {
            id: kawoosh
            anchors.centerIn: parent
            width: gate.r * 2 * 0.60; height: width
            opacity: 0
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: kawoosh.width / 2; centerY: kawoosh.height / 2
                    centerRadius: kawoosh.width / 2
                    focalX: kawoosh.width / 2; focalY: kawoosh.height / 2
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.95) }
                    GradientStop { position: 0.5; color: root.energy }
                    GradientStop { position: 1.0; color: Qt.rgba(root.energy.r, root.energy.g, root.energy.b, 0) }
                }
                startX: kawoosh.width; startY: kawoosh.height / 2
                PathAngleArc {
                    centerX: kawoosh.width / 2; centerY: kawoosh.height / 2
                    radiusX: kawoosh.width / 2; radiusY: kawoosh.height / 2
                    startAngle: 0; sweepAngle: 360
                }
            }
            SequentialAnimation {
                id: kawooshAnim
                ParallelAnimation {
                    NumberAnimation { target: kawoosh; property: "opacity"; from: 0.9; to: 0; duration: 620; easing.type: Easing.OutCubic }
                    NumberAnimation { target: kawoosh; property: "scale"; from: 0.35; to: 1.35; duration: 620; easing.type: Easing.OutQuad }
                }
            }
        }

        Connections {
            target: root.service
            function onEstablishedChanged() {
                if (root.service && root.service.established) kawooshAnim.restart();
            }
        }
    }

    // ── instrument readout over the event horizon ────────────────────────────
    Column {
        anchors.centerIn: gate
        spacing: 4 * root.s
        visible: (root.service && (root.service.showTime || root.service.showDesignation))

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.service && root.service.showDesignation
            text: root.service ? root.service.designation : ""
            color: Qt.rgba(0.85, 0.94, 1, 0.85)
            font.family: Theme.mono
            font.pixelSize: root.d * 0.035
            font.weight: Font.DemiBold
            font.letterSpacing: 4 * root.s
            style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.6)
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.service && root.service.showTime
            text: root.service ? root.service.timeText : ""
            color: "#f4faff"
            font.family: Theme.mono
            font.pixelSize: root.d * 0.115
            font.weight: Font.Light
            font.letterSpacing: 3 * root.s
            style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.7)
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.service && root.service.showTime
            width: root.d * 0.19; height: Math.max(1, root.d * 0.0035)
            color: Qt.rgba(0.85, 0.94, 1, 0.5)
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.established ? qsTr("WORMHOLE STABLE")
                                   : qsTr("CHEVRON %1 LOCKED").arg(Math.max(1, root.locked))
            color: root.established ? Qt.rgba(0.82, 0.95, 1, 0.9) : "#ffd0a0"
            font.family: Theme.mono
            font.pixelSize: root.d * 0.028
            font.weight: Font.Medium
            font.letterSpacing: 2.5 * root.s
            style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.6)
        }
    }

}
