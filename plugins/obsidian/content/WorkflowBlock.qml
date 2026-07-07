pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// One workflow as a node on the canvas spine, drawn as a sharp ledger row: an
// accent square chip carrying the action glyph sits on a vermillion rule, with
// the label and a mono subtitle beside it. The whole row runs the workflow; the
// hover/edit controls take their own clicks. A recording block blinks the chip
// and reads "REC · TAP TO STOP". Sharp corners, hairline borders, no gradient.
Item {
    id: root

    property real s: 1
    property real w: 320
    property real gap: 9
    property string icon: "file"
    property string label: ""
    property string sub: ""
    property color accent: Theme.verm
    property bool connectUp: false
    property bool connectDown: false
    property bool editMode: false
    property bool removable: true
    property bool running: false
    property bool canUp: false
    property bool canDown: false

    signal activated()
    signal editRequested()
    signal removeRequested()
    signal moveUp()
    signal moveDown()

    readonly property real nodeX: 20 * s
    implicitWidth: w
    implicitHeight: 50 * s

    // spine — a continuous vermillion rule through the node chips, capped at the ends.
    Rectangle {
        x: root.nodeX - 0.5
        width: 1
        y: root.connectUp ? -root.gap : root.height / 2
        height: (root.connectDown ? root.height : root.height / 2) - y
        color: Qt.alpha(root.accent, 0.55)
        antialiasing: false
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 0
        antialiasing: false
        color: hover.hovered ? Qt.alpha(root.accent, 0.1) : Qt.rgba(1, 1, 1, 0.02)
        border.width: 1
        border.color: hover.hovered ? Qt.alpha(root.accent, 0.55) : Theme.hair
        Behavior on color { ColorAnimation { duration: Motion.fast } }

        // node chip on the spine — sharp accent square.
        Rectangle {
            id: chip
            x: root.nodeX - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: 28 * root.s
            height: 28 * root.s
            radius: 0
            antialiasing: false
            color: root.running ? root.accent : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, hover.hovered ? 0.22 : 0.13)
            border.width: 1
            border.color: root.accent
            Behavior on color { ColorAnimation { duration: Motion.fast } }

            GlyphIcon {
                anchors.centerIn: parent
                width: 16 * root.s
                height: 16 * root.s
                name: root.running ? "record" : root.icon
                color: root.running ? Theme.cardBot : root.accent
                stroke: 1.7
            }
            SequentialAnimation on opacity {
                running: root.running
                loops: Animation.Infinite
                NumberAnimation { from: 1; to: 0.4; duration: 620; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.4; to: 1; duration: 620; easing.type: Easing.InOutSine }
            }
        }

        Column {
            id: texts
            anchors.left: chip.right
            anchors.leftMargin: 13 * root.s
            anchors.right: controls.left
            anchors.rightMargin: 8 * root.s
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3 * root.s

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: root.label
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 13.5 * root.s
                font.weight: Font.Medium
            }
            Text {
                width: parent.width
                elide: Text.ElideRight
                visible: text.length > 0
                text: root.running ? qsTr("REC · tap to stop") : root.sub
                color: root.running ? root.accent : Theme.faint
                font.family: Theme.mono
                font.pixelSize: 9.5 * root.s
                font.letterSpacing: 0.5 * root.s
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activated()
        }

        Row {
            id: controls
            anchors.right: parent.right
            anchors.rightMargin: 8 * root.s
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3 * root.s
            opacity: (hover.hovered || root.editMode) && root.removable && !root.running ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: Motion.fast } }

            component Ctl: Rectangle {
                id: ctl
                property string glyph: ""
                property bool on: true
                signal tapped()
                width: 23 * root.s
                height: 23 * root.s
                radius: 0
                antialiasing: false
                color: cma.containsMouse ? root.accent : Qt.rgba(0, 0, 0, 0.3)
                opacity: ctl.on ? 1 : 0.3
                border.width: 1
                border.color: cma.containsMouse ? root.accent : Theme.hair
                Behavior on color { ColorAnimation { duration: Motion.fast } }
                GlyphIcon {
                    anchors.centerIn: parent
                    width: 13 * root.s
                    height: 13 * root.s
                    name: ctl.glyph
                    color: cma.containsMouse ? Theme.cardBot : Theme.iconDim
                    stroke: 1.8
                }
                MouseArea {
                    id: cma
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: ctl.on
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ctl.tapped()
                }
            }

            Ctl { glyph: "chevron-up"; visible: root.editMode; on: root.canUp; onTapped: root.moveUp() }
            Ctl { glyph: "chevron-down"; visible: root.editMode; on: root.canDown; onTapped: root.moveDown() }
            Ctl { glyph: "list"; visible: !root.editMode; onTapped: root.editRequested() }
            Ctl { glyph: "trash"; visible: root.editMode; onTapped: root.removeRequested() }
        }
    }

    HoverHandler { id: hover }
}
