pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit.Singletons

// Chart hover readout: a vertical hairline + ring at the nearest sample and a
// small carbon chip with its price and time. Fill the plot Item with it. The
// MouseArea accepts no buttons - it only listens to hover - so clicks and
// drags still fall through to the slot's grip and the tile stays draggable
// over the chart.
Item {
  id: root

  property var service: null
  property real s: 1
  property var values: []
  property var times: []
  property real lo: 0
  property real hi: 1

  readonly property real span: (hi - lo) > 0 ? (hi - lo) : 1
  // length-based, not Array.isArray: see Sparkline (QVariantList sequences).
  readonly property int n: values && values.length !== undefined ? values.length : 0
  property int idx: -1
  readonly property bool live: idx >= 0 && idx < n && n > 1

  function ptX(i) { return i / Math.max(1, n - 1) * width; }
  function ptY(v) { return (1 - (v - lo) / span) * height; }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
    onPositionChanged: mouse => {
      root.idx = root.n > 1
        ? Math.max(0, Math.min(root.n - 1, Math.round(mouse.x / root.width * (root.n - 1))))
        : -1;
    }
    onContainsMouseChanged: if (!containsMouse) root.idx = -1;
  }

  Rectangle {
    visible: root.live
    x: root.live ? root.ptX(root.idx) : 0
    width: 1
    height: parent.height
    color: Theme.lineStrong
    opacity: 0.5
  }

  Rectangle {
    visible: root.live
    width: 7 * root.s
    height: 7 * root.s
    radius: width / 2
    color: Theme.cardBot
    border.width: 1.6 * root.s
    border.color: root.service ? root.service.trendColor : Theme.cream
    x: (root.live ? root.ptX(root.idx) : 0) - width / 2
    y: (root.live ? root.ptY(root.values[root.idx]) : 0) - height / 2
  }

  Rectangle {
    id: chip
    visible: root.live
    x: Math.max(0, Math.min(parent.width - width, (root.live ? root.ptX(root.idx) : 0) - width / 2))
    y: {
      if (!root.live) return 0;
      var above = root.ptY(root.values[root.idx]) - height - 9 * root.s;
      return above >= 0 ? above : root.ptY(root.values[root.idx]) + 9 * root.s;
    }
    width: chipRow.implicitWidth + 14 * root.s
    height: chipRow.implicitHeight + 8 * root.s
    radius: 6 * root.s
    color: Qt.rgba(0, 0, 0, 0.78)
    border.width: 1
    border.color: Theme.hair

    Row {
      id: chipRow
      anchors.centerIn: parent
      spacing: 7 * root.s
      Text {
        text: root.live && root.service ? root.service.fmtPrice(root.values[root.idx]) : ""
        color: Theme.cream
        font.family: Theme.mono
        font.pixelSize: 9.5 * root.s
        font.weight: Font.DemiBold
      }
      Text {
        text: root.live && root.service && root.idx < root.times.length
          ? root.service.fmtTime(root.times[root.idx]) : ""
        color: Theme.faint
        font.family: Theme.mono
        font.pixelSize: 8.5 * root.s
        font.weight: Font.Medium
      }
    }
  }
}
