pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit.Singletons

// The timeframe switcher: 1D / 1W / 1M / 1Y as flat mono chips, the active one
// carrying the chrome accent and a thin underline tick. Tapping persists the
// window through the service, so the menu, the hub, and this strip stay one
// setting. Sits right-aligned in a face's eyebrow row - the most-toggled
// control lives on the tile, not three levels down a menu.
Row {
  id: root

  property var service: null
  property real s: 1

  readonly property color accent: root.service ? root.service.accentColor() : Theme.brand

  spacing: 4 * s

  Repeater {
    model: root.service ? root.service.windowKeys : []

    Item {
      id: chip
      required property string modelData
      readonly property bool current: root.service && root.service.winKey === modelData

      width: label.implicitWidth + 8 * root.s
      height: label.implicitHeight + 7 * root.s

      Text {
        id: label
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1 * root.s
        text: chip.modelData
        color: chip.current ? root.accent : (ma.containsMouse ? Theme.subtle : Theme.faint)
        font.family: Theme.mono
        font.pixelSize: 9 * root.s
        font.weight: chip.current ? Font.Bold : Font.Medium
        font.letterSpacing: 0.5
        Behavior on color { ColorAnimation { duration: Motion.fast } }
      }

      Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: label.implicitWidth
        height: 2 * root.s
        color: root.accent
        opacity: chip.current ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Motion.fast } }
      }

      MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.service) root.service.setWindow(chip.modelData)
      }
    }
  }
}
