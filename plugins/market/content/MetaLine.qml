pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit.Singletons

// The data-provenance footer: session state (dot + OPEN/CLOSED/PRE-MKT), the
// "as of HH:mm" stamp, a gold STALE flag when the last refresh failed while
// old numbers are still showing, and a pulsing accent dot during a background
// refresh. One quiet mono line that answers "can I trust this number".
Row {
  id: root

  property var service: null
  property real s: 1

  readonly property string mkt: root.service ? root.service.market : ""
  readonly property bool stale: root.service ? root.service.stale : false
  readonly property bool refreshing: root.service ? (root.service.loading && root.service.hasData) : false

  spacing: 7 * s
  height: Math.max(9 * s, implicitHeight)

  // session dot + label (absent for crypto - no session to speak of).
  Row {
    spacing: 4 * root.s
    anchors.verticalCenter: parent.verticalCenter
    visible: root.service && root.service.marketLabel(root.mkt).length > 0
    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: 5 * root.s
      height: 5 * root.s
      radius: width / 2
      color: root.service ? root.service.marketColor(root.mkt) : Theme.faint
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.service ? root.service.marketLabel(root.mkt) : ""
      color: Theme.faint
      font.family: Theme.mono
      font.pixelSize: 8.5 * root.s
      font.weight: Font.Medium
      font.letterSpacing: 1
    }
  }

  Text {
    anchors.verticalCenter: parent.verticalCenter
    visible: root.service && root.service.lastUpdated > 0
    text: root.service ? qsTr("AS OF %1").arg(root.service.fmtClock(root.service.lastUpdated)) : ""
    color: Theme.faint
    font.family: Theme.mono
    font.pixelSize: 8.5 * root.s
    font.weight: Font.Medium
    font.letterSpacing: 1
  }

  // the refresh failed; these numbers are the last good ones.
  Row {
    spacing: 4 * root.s
    anchors.verticalCenter: parent.verticalCenter
    visible: root.stale
    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: 5 * root.s
      height: 5 * root.s
      color: Theme.gold
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: qsTr("STALE")
      color: Theme.gold
      font.family: Theme.mono
      font.pixelSize: 8.5 * root.s
      font.weight: Font.DemiBold
      font.letterSpacing: 1
    }
  }

  // background refresh in flight: one breathing accent dot, no words.
  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    width: 5 * root.s
    height: 5 * root.s
    radius: width / 2
    color: root.service ? root.service.accentColor() : Theme.brand
    visible: root.refreshing
    SequentialAnimation on opacity {
      running: root.refreshing
      loops: Animation.Infinite
      NumberAnimation { from: 1; to: 0.25; duration: Motion.glide }
      NumberAnimation { from: 0.25; to: 1; duration: Motion.glide }
    }
  }
}
