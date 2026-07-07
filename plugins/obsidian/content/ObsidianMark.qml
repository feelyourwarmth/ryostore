import QtQuick
import Ryoku.PluginKit.Singletons

// The widget's seal: a hanko-style square stamp carrying 黒 (kuro — black, for
// obsidian's volcanic glass), the accent carved into near-black. Sharp corners,
// a hairline inner rule, no gradient — a printed mark, not an app icon. `glow`
// breathes it while the service is still looking for Obsidian.
Item {
    id: root

    property color color: Theme.verm
    property bool glow: false

    readonly property real u: Math.min(width, height)

    Rectangle {
        id: stamp
        anchors.centerIn: parent
        width: root.u
        height: root.u
        color: Qt.rgba(root.color.r, root.color.g, root.color.b, 0.1)
        radius: 0
        border.width: Math.max(1, root.u * 0.06)
        border.color: root.color
        antialiasing: false

        // carved inner rule.
        Rectangle {
            anchors.fill: parent
            anchors.margins: Math.max(2, root.u * 0.13)
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(root.color, 0.35)
            radius: 0
            antialiasing: false
        }

        Text {
            anchors.centerIn: parent
            text: "\u9ed2"
            color: root.color
            font.family: Theme.fontJp
            font.pixelSize: root.u * 0.5
            font.weight: Font.Bold
        }

        SequentialAnimation on opacity {
            running: root.glow
            loops: Animation.Infinite
            NumberAnimation { from: 1; to: 0.45; duration: 780; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.45; to: 1; duration: 780; easing.type: Easing.InOutSine }
        }
    }
}
