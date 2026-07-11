pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit.Singletons

// The watchlist: one quiet row per tracked instrument - symbol, a mini
// trend-tinted sparkline, price, and the window change. The active instrument
// (the one owning the chart above) carries an accent edge tick; tapping any
// row promotes it. A failed symbol keeps its row with a gold flag instead of
// vanishing. Only rendered by faces when the watchlist has more than one entry.
Column {
  id: root

  property var service: null
  property real s: 1

  readonly property color accent: root.service ? root.service.accentColor() : Theme.brand

  spacing: 0

  Repeater {
    model: root.service ? root.service.quotes : []

    Item {
      id: row
      required property var modelData
      required property int index

      readonly property bool active: root.service && root.service.activeSymbol === modelData.sym
      readonly property bool failed: (modelData.error || "").length > 0
      readonly property color tint: root.service ? root.service.trendFor(modelData.up === true) : Theme.cream
      readonly property real lo: {
        var v = modelData.spark || [];
        if (v.length < 1) return 0;
        var m = v[0];
        for (var i = 1; i < v.length; i++) if (v[i] < m) m = v[i];
        return m;
      }
      readonly property real hi: {
        var v = modelData.spark || [];
        if (v.length < 1) return 1;
        var m = v[0];
        for (var i = 1; i < v.length; i++) if (v[i] > m) m = v[i];
        return m;
      }

      width: root.width
      height: 27 * root.s

      // hairline between rows, not around them.
      Rectangle {
        visible: row.index > 0
        width: parent.width
        height: 1
        color: Theme.hair
      }

      Rectangle {
        anchors.fill: parent
        color: Theme.cream
        opacity: rowMa.containsMouse && !row.active ? 0.05 : 0
        Behavior on opacity { NumberAnimation { duration: Motion.fast } }
      }

      // active edge tick, the same accent the window chips carry.
      Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 2 * root.s
        height: 13 * root.s
        color: root.accent
        opacity: row.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Motion.fast } }
      }

      Text {
        id: symText
        anchors.left: parent.left
        anchors.leftMargin: 9 * root.s
        anchors.verticalCenter: parent.verticalCenter
        text: row.modelData.sym || ""
        color: row.active ? Theme.cream : Theme.subtle
        font.family: Theme.mono
        font.pixelSize: 10.5 * root.s
        font.weight: row.active ? Font.DemiBold : Font.Medium
      }

      // failed refresh for this one symbol.
      Text {
        anchors.left: symText.right
        anchors.leftMargin: 6 * root.s
        anchors.verticalCenter: parent.verticalCenter
        visible: row.failed
        text: "!"
        color: Theme.gold
        font.family: Theme.mono
        font.pixelSize: 10 * root.s
        font.weight: Font.Bold
      }

      Sparkline {
        anchors.right: priceText.left
        anchors.rightMargin: 12 * root.s
        anchors.verticalCenter: parent.verticalCenter
        width: 52 * root.s
        height: 14 * root.s
        visible: (row.modelData.spark || []).length > 1
        values: row.modelData.spark || []
        min: row.lo
        max: row.hi
        color: row.tint
        lineWidth: 1.6 * root.s
      }

      Text {
        id: priceText
        anchors.right: pctText.left
        anchors.rightMargin: 10 * root.s
        anchors.verticalCenter: parent.verticalCenter
        text: row.modelData.price > 0 && root.service
          ? root.service.fmtPrice(row.modelData.price, row.modelData) : "\u2014"
        color: row.modelData.price > 0 ? Theme.cream : Theme.faint
        font.family: Theme.mono
        font.pixelSize: 10.5 * root.s
        font.weight: Font.DemiBold
      }

      Text {
        id: pctText
        anchors.right: parent.right
        anchors.rightMargin: 2 * root.s
        anchors.verticalCenter: parent.verticalCenter
        width: 52 * root.s
        horizontalAlignment: Text.AlignRight
        text: {
          if (!root.service || row.modelData.price <= 0) return "";
          var v = row.modelData.changePct || 0;
          return (v >= 0 ? "+" : "-") + root.service.fmtPct(v);
        }
        color: row.tint
        font.family: Theme.mono
        font.pixelSize: 10 * root.s
        font.weight: Font.Medium
      }

      MouseArea {
        id: rowMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: row.active ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: if (root.service) root.service.setActive(row.modelData.sym)
      }
    }
  }
}
