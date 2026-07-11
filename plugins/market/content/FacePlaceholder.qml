pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit.Singletons

// The plot-area placeholder for the two states that have no chart to draw:
// first fetch in flight (a breathing FETCHING line) and failed-with-no-data
// (the error, plus the reassurance that the poll keeps trying). Faces show it
// where the chart would be, so the tile never sits as an unexplained blank -
// and never fakes a $0.00 quote.
Item {
  id: root

  property var service: null
  property real s: 1

  readonly property bool failed: root.service ? root.service.error.length > 0 : false

  implicitHeight: col.implicitHeight

  Column {
    id: col
    anchors.centerIn: parent
    width: root.width
    spacing: 5 * root.s

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      visible: !root.failed
      text: root.service ? qsTr("FETCHING %1").arg(root.service.activeSymbol) : ""
      color: Theme.faint
      font.family: Theme.mono
      font.pixelSize: 10 * root.s
      font.weight: Font.Medium
      font.letterSpacing: 2
      SequentialAnimation on opacity {
        running: !root.failed && root.visible
        loops: Animation.Infinite
        NumberAnimation { from: 1; to: 0.35; duration: Motion.glide }
        NumberAnimation { from: 0.35; to: 1; duration: Motion.glide }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      width: Math.min(implicitWidth, root.width)
      visible: root.failed
      elide: Text.ElideRight
      text: root.service ? root.service.error : ""
      color: Theme.subtle
      font.family: Theme.font
      font.pixelSize: 11 * root.s
      font.weight: Font.Medium
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      visible: root.failed
      text: root.service
        ? qsTr("Check the symbol - retries every %1s").arg(root.service.refreshSec)
        : ""
      color: Theme.faint
      font.family: Theme.font
      font.pixelSize: 9.5 * root.s
    }
  }
}
