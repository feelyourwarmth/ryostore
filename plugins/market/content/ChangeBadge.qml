pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Ryoku.PluginKit.Singletons

// The percent-change chip: a small triangular arrow (up/down) + the percent,
// tinted green when up and vermilion when down. Hovering lifts and brightens it
// and reveals the absolute change beside the percent - the "active" interaction.
Item {
  id: root

  property var service: null
  property real s: 1
  readonly property bool ready: root.service ? root.service.priceReady : false
  readonly property bool up: root.service ? root.service.up : true
  readonly property color tint: ready && root.service ? root.service.trendColor : Theme.faint

  implicitWidth: rowFlow.implicitWidth
  implicitHeight: rowFlow.implicitHeight

  HoverHandler { id: hov }
  scale: hov.hovered ? 1.06 : 1.0
  transformOrigin: Item.Left
  Behavior on scale { NumberAnimation { duration: Motion.fast; easing.type: Easing.OutBack } }

  Row {
    id: rowFlow
    spacing: 5 * root.s

    // up/down arrowhead, filled with the trend tint.
    Shape {
      visible: root.ready
      width: 9 * root.s
      height: 9 * root.s
      anchors.verticalCenter: parent.verticalCenter
      antialiasing: true
      preferredRendererType: Shape.CurveRenderer
      ShapePath {
        strokeColor: "transparent"
        fillColor: root.tint
        PathSvg { path: root.up ? "M4.5 1 L9 8 L0 8 Z" : "M4.5 8 L9 1 L0 1 Z" }
      }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.service && root.ready ? root.service.fmtPct(root.service.changePct) : "\u2013"
      color: root.tint
      font.family: Theme.mono
      font.pixelSize: 15 * root.s
      font.weight: Font.DemiBold
    }

    // absolute change, revealed on hover.
    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: opacity > 0.01
      opacity: hov.hovered && root.ready ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: Motion.fast } }
      text: {
        if (!root.service) return "";
        var v = root.service.changeAbs;
        return (v >= 0 ? "+" : "-") + root.service.fmtPrice(Math.abs(v));
      }
      color: Theme.faint
      font.family: Theme.mono
      font.pixelSize: 11 * root.s
      font.weight: Font.Medium
    }
  }
}
