pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

/**
 * Minimal face: the smallest tile. With one tracked symbol it is a single
 * quote row - name + price stacked left, ChangeBadge + compact sparkline
 * right. With a watchlist it becomes the ticker board: a WATCHLIST eyebrow
 * with the provenance MetaLine, then one WatchRows line per instrument. Reads
 * only through `root.service`; draws its own surface + CornerTicks.
 */
Item {
  id: root

  property var service: null
  property real s: 1
  property real cw: 360

  readonly property real pad: 15 * s
  readonly property bool multi: root.service ? root.service.quotes.length > 1 : false
  readonly property color tint: root.service ? root.service.trendColor : Theme.brand

  implicitWidth: cw
  implicitHeight: surface.implicitHeight

  Rectangle {
    id: surface
    width: root.cw
    implicitHeight: root.multi
      ? board.implicitHeight + root.pad * 2
      : Math.max(left.implicitHeight, right.implicitHeight) + root.pad * 2
    radius: 16 * root.s
    border.width: 1
    border.color: Theme.border
    gradient: Gradient {
      GradientStop { position: 0.0; color: Theme.cardTop }
      GradientStop { position: 1.0; color: Theme.cardBot }
    }

    CornerTicks { anchors.fill: parent; s: root.s }

    // ── single instrument: one quote row ────────────────────────────────────
    Column {
      id: left
      visible: !root.multi
      anchors.left: parent.left
      anchors.leftMargin: root.pad
      anchors.verticalCenter: parent.verticalCenter
      spacing: 4 * root.s

      MicroLabel {
        label: root.service && root.service.name.length > 0 ? root.service.name : qsTr("Market")
        s: root.s
      }
      PriceText { service: root.service; s: root.s; pixelSize: 24 * root.s }

      // failed before any data existed: say so instead of a bare dash.
      Text {
        visible: root.service ? (!root.service.hasData && root.service.error.length > 0) : false
        width: root.cw - root.pad * 2 - 120 * root.s
        elide: Text.ElideRight
        text: root.service ? root.service.error : ""
        color: Theme.faint
        font.family: Theme.font
        font.pixelSize: 9.5 * root.s
      }
    }

    Column {
      id: right
      visible: !root.multi
      anchors.right: parent.right
      anchors.rightMargin: root.pad
      anchors.verticalCenter: parent.verticalCenter
      spacing: 7 * root.s

      ChangeBadge {
        anchors.right: parent.right
        service: root.service
        s: root.s
      }

      Sparkline {
        width: 108 * root.s
        height: 30 * root.s
        visible: root.service ? root.service.hasData : false
        values: root.service ? root.service.spark : []
        min: root.service ? root.service.sparkMin : 0
        max: root.service ? root.service.sparkMax : 1
        color: root.tint
        lineWidth: 2 * root.s
      }
    }

    // ── watchlist: the ticker board ─────────────────────────────────────────
    Column {
      id: board
      visible: root.multi
      x: root.pad
      y: root.pad
      width: parent.width - root.pad * 2
      spacing: 6 * root.s

      Item {
        width: parent.width
        height: Math.max(boardEyebrow.implicitHeight, boardMeta.implicitHeight)
        MicroLabel {
          id: boardEyebrow
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          label: qsTr("Watchlist")
          s: root.s
        }
        MetaLine {
          id: boardMeta
          anchors.right: parent.right
          anchors.rightMargin: 30 * root.s
          anchors.verticalCenter: parent.verticalCenter
          service: root.service
          s: root.s
        }
      }

      WatchRows {
        width: parent.width
        service: root.service
        s: root.s
      }
    }
  }
}
