pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

/**
 * Minimal face: the smallest tile. Name + price stacked on the left; the
 * ChangeBadge and a compact trend-tinted Sparkline stacked on the right. Reads
 * only through `root.service`; draws its own surface + CornerTicks.
 */
Item {
  id: root

  property var service: null
  property real s: 1
  property real cw: 360

  readonly property real pad: 15 * s
  readonly property color tint: root.service ? root.service.trendColor : Theme.brand

  implicitWidth: cw
  implicitHeight: surface.implicitHeight

  Rectangle {
    id: surface
    width: root.cw
    implicitHeight: Math.max(left.implicitHeight, right.implicitHeight) + root.pad * 2
    radius: 16 * root.s
    border.width: 1
    border.color: Theme.border
    gradient: Gradient {
      GradientStop { position: 0.0; color: Theme.cardTop }
      GradientStop { position: 1.0; color: Theme.cardBot }
    }

    CornerTicks { anchors.fill: parent; s: root.s }

    // left: name + price.
    Column {
      id: left
      anchors.left: parent.left
      anchors.leftMargin: root.pad
      anchors.verticalCenter: parent.verticalCenter
      spacing: 4 * root.s

      MicroLabel { label: root.service ? root.service.name : qsTr("Market"); s: root.s }
      PriceText { service: root.service; s: root.s; pixelSize: 24 * root.s }
    }

    // right: change badge + sparkline.
    Column {
      id: right
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
  }
}
