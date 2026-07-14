pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons
import "gate.js" as Gate

/**
 * Dossier face: the gate as a declassified SGC dialing log - a printed file, not
 * a glowing terminal. Warm off-white ink on a matte folder, hard form rules, a
 * seven-cell address block (six constellations plus the point of origin) with
 * printed lock marks, a stencilled designation, and a rotated red ink stamp that
 * reads DIALING while it encodes and stamps ESTABLISHED when the wormhole holds.
 * This face leans hardest on the glyph font, so the address block is where a
 * loaded cap_resources font shows off.
 *
 * Not square: the card's height follows its content.
 */
Item {
    id: root

    property var service: null
    property real s: 1
    property real cw: 360
    property bool active: true

    implicitWidth: cw
    implicitHeight: surface.implicitHeight

    readonly property var address: service ? service.address : []
    readonly property int locked: service ? service.locked : 0
    readonly property bool established: service ? service.established : true
    readonly property string family: service ? service.glyphFamily : ""
    readonly property real pad: 17 * s

    readonly property color ink: "#e7dfce"                    // printed ink
    readonly property color inkDim: "#958c76"                 // faded type
    readonly property color stamp: "#cf4433"                  // stamp red
    readonly property color rule: Qt.rgba(0.905, 0.874, 0.807, 0.22)

    Rectangle {
        id: surface
        width: root.cw
        implicitHeight: col.implicitHeight + root.pad * 2
        radius: 6 * root.s
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#17130c" }
            GradientStop { position: 1.0; color: "#0c0a06" }
        }
        border.width: 1
        border.color: Qt.rgba(0.905, 0.874, 0.807, 0.16)

        CornerTicks { anchors.fill: parent; anchors.margins: 8 * root.s; s: root.s; tint: root.rule }

        Column {
            id: col
            x: root.pad; y: root.pad
            width: parent.width - root.pad * 2
            spacing: 11 * root.s

            // ── header ───────────────────────────────────────────────────────
            Item {
                width: parent.width
                height: Math.max(mark.height, hdr.implicitHeight)

                Row {
                    id: hdr
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 9 * root.s

                    Item {
                        id: mark
                        width: 20 * root.s; height: width
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle { anchors.centerIn: parent; width: parent.width; height: width; radius: width / 2; color: "transparent"; border.width: 1.6 * root.s; border.color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.7) }
                        Rectangle { anchors.centerIn: parent; width: parent.width * 0.42; height: width; radius: width / 2; color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.55) }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2 * root.s
                        Text {
                            text: qsTr("STARGATE COMMAND")
                            color: root.ink
                            font.family: Theme.mono; font.pixelSize: 11 * root.s
                            font.weight: Font.DemiBold; font.letterSpacing: 2 * root.s
                        }
                        Text {
                            text: qsTr("GATE DIALING LOG")
                            color: root.inkDim
                            font.family: Theme.mono; font.pixelSize: 8 * root.s
                            font.weight: Font.Medium; font.letterSpacing: 2.6 * root.s
                        }
                    }
                }

                // rotated ink stamp - the document's status.
                Item {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 92 * root.s; height: 30 * root.s
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width; height: parent.height
                        rotation: -7
                        radius: 2 * root.s
                        color: "transparent"
                        border.width: 2 * root.s
                        border.color: Qt.rgba(root.stamp.r, root.stamp.g, root.stamp.b, root.established ? 0.9 : 0.7)
                        opacity: root.established ? 0.95 : 0.8
                        Text {
                            anchors.centerIn: parent
                            text: root.established ? qsTr("ESTABLISHED") : qsTr("DIALING")
                            color: parent.border.color
                            font.family: Theme.mono; font.pixelSize: (root.established ? 9 : 10.5) * root.s
                            font.weight: Font.Bold; font.letterSpacing: 1.5 * root.s
                        }
                        SequentialAnimation on opacity {
                            running: root.active && !root.established
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 520 }
                            NumberAnimation { to: 0.8; duration: 520 }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: root.rule }

            // ── address block: 6 constellations + point of origin ─────────────
            Row {
                id: strip
                width: parent.width
                readonly property real gap: 6 * root.s
                spacing: strip.gap
                readonly property real cellW: (strip.width - 6 * strip.gap) / 7

                Repeater {
                    model: 7
                    delegate: Column {
                        id: cell
                        required property int index
                        width: strip.cellW
                        spacing: 5 * root.s
                        readonly property bool isPoo: cell.index === 6
                        readonly property bool lockedCell: cell.isPoo ? root.established : (cell.index < root.locked)
                        readonly property int glyphIdx: (!cell.isPoo && root.address && cell.index < root.address.length) ? root.address[cell.index] : 0

                        Rectangle {
                            width: parent.width; height: width
                            radius: 3 * root.s
                            color: cell.lockedCell ? Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.05) : "transparent"
                            border.width: 1
                            border.color: cell.lockedCell ? Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.5) : root.rule
                            Behavior on border.color { ColorAnimation { duration: 260 } }

                            GateGlyph {
                                anchors.fill: parent
                                anchors.margins: parent.width * 0.17
                                index: cell.glyphIdx
                                isPoo: cell.isPoo
                                family: root.family
                                glyphColor: cell.lockedCell ? root.ink : root.inkDim
                                lit: cell.lockedCell ? 1 : 0.5
                            }
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 3 * root.s
                            Rectangle {                       // printed lock mark
                                width: 5 * root.s; height: width
                                anchors.verticalCenter: parent.verticalCenter
                                color: cell.lockedCell ? root.stamp : "transparent"
                                border.width: cell.lockedCell ? 0 : 1
                                border.color: root.inkDim
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: cell.isPoo ? qsTr("ORG") : ("C" + (cell.index + 1))
                                color: cell.lockedCell ? root.ink : root.inkDim
                                font.family: Theme.mono; font.pixelSize: 7.5 * root.s
                                font.weight: Font.DemiBold; font.letterSpacing: 0.5 * root.s
                            }
                        }
                    }
                }
            }

            // ── designation + galactic reference ─────────────────────────────
            Item {
                width: parent.width
                height: desigCol.implicitHeight

                Column {
                    id: desigCol
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1 * root.s
                    Text {
                        text: qsTr("DESIGNATION")
                        color: root.inkDim
                        font.family: Theme.mono; font.pixelSize: 7.5 * root.s
                        font.weight: Font.Medium; font.letterSpacing: 3 * root.s
                    }
                    Text {
                        text: root.service ? root.service.designation : "P0X-000"
                        color: root.ink
                        font.family: Theme.mono; font.pixelSize: 22 * root.s
                        font.weight: Font.Bold; font.letterSpacing: 1 * root.s
                    }
                }
                Column {
                    anchors.right: parent.right
                    anchors.bottom: desigCol.bottom
                    spacing: 1 * root.s
                    visible: root.service && root.service.showDesignation
                    Text {
                        anchors.right: parent.right
                        text: qsTr("GALACTIC REF")
                        color: root.inkDim
                        font.family: Theme.mono; font.pixelSize: 7.5 * root.s
                        font.weight: Font.Medium; font.letterSpacing: 2 * root.s
                    }
                    Text {
                        anchors.right: parent.right
                        text: root.coords()
                        color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.85)
                        font.family: Theme.mono; font.pixelSize: 9.5 * root.s
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: root.rule }

            // ── footer: log stamp + progress ─────────────────────────────────
            Item {
                width: parent.width
                height: footerRow.implicitHeight

                Row {
                    id: footerRow
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8 * root.s

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 78 * root.s; height: 3 * root.s
                        color: root.rule
                        Rectangle {
                            width: parent.width * (root.service ? root.service.progress : 1)
                            height: parent.height
                            color: root.stamp
                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.established ? qsTr("7/7 ENCODED") : (root.locked + qsTr("/7"))
                        color: root.inkDim
                        font.family: Theme.mono; font.pixelSize: 8.5 * root.s
                        font.weight: Font.Medium; font.letterSpacing: 1 * root.s
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.service && root.service.showTime
                    text: (root.service ? root.service.timeText : "") + "  " + (root.service ? root.service.dateText : "")
                    color: root.ink
                    font.family: Theme.mono; font.pixelSize: 9.5 * root.s
                    font.weight: Font.Medium; font.letterSpacing: 0.5 * root.s
                }
            }
        }
    }

    // Stable "galactic coordinates" derived from the address, for flavour.
    function coords() {
        var a = root.address || [];
        function h(n) { var v = 0; for (var i = 0; i < a.length; i++) v = (v * 31 + a[i] * (i + n)) % 3600; return v; }
        return "X " + (h(3) / 10).toFixed(1) + "\u00b0  Y " + (h(7) / 10).toFixed(1) + "\u00b0";
    }
}
