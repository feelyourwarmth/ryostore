import QtQuick
import Ryoku.PluginKit.Singletons

// The website's editorial kicker: a short vermillion tick, an optional 力 seal,
// then a mono uppercase label with wide tracking. One accent, quiet, sits above
// a heading. `mark` leads with the 力 brand seal; drop it for sub-sections.
Row {
    id: eye

    property string text: ""
    property bool mark: false
    property real s: 1
    property color tick: Theme.verm

    spacing: 9 * s

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 20 * eye.s
        height: Math.max(1, 1.5 * eye.s)
        color: eye.tick
    }

    Text {
        visible: eye.mark
        anchors.verticalCenter: parent.verticalCenter
        text: "\u529b"
        color: eye.tick
        font.family: Theme.fontJp
        font.pixelSize: 12 * eye.s
        font.weight: Font.Bold
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: eye.text
        color: Theme.faint
        font.family: Theme.mono
        font.pixelSize: 10 * eye.s
        font.weight: Font.DemiBold
        font.letterSpacing: 3 * eye.s
        font.capitalization: Font.AllUppercase
    }
}
