pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

/**
 * The flagship market face: the reference "Income" card in the shell's dark
 * dossier idiom. A 力 MARKET eyebrow carrying the instrument name and a trend-
 * tinted sparkle seal top-right; a big tabular PriceText with the ChangeBadge
 * beside it; a "compared to <prevClose> <window>" subline; and the Ridgeline
 * hero filling the rest. Reads state only through `root.service`; draws its own
 * cardTop->cardBot surface + CornerTicks so the host slot's bg:"none" is right.
 */
Item {
  id: root

  property var service: null
  property real s: 1
  property real cw: 360

  readonly property real pad: 18 * s

  implicitWidth: cw
  implicitHeight: surface.implicitHeight

  Rectangle {
    id: surface
    width: root.cw
    implicitHeight: col.y + col.implicitHeight + root.pad + ridge.height + root.pad
    radius: 20 * root.s
    border.width: 1
    border.color: Theme.border
    gradient: Gradient {
      GradientStop { position: 0.0; color: Theme.cardTop }
      GradientStop { position: 1.0; color: Theme.cardBot }
    }

    CornerTicks { anchors.fill: parent; s: root.s }

    Column {
      id: col
      x: root.pad
      y: root.pad
      width: parent.width - root.pad * 2
      spacing: 8 * root.s

      // eyebrow row: 力 MARKET name + trend sparkle seal.
      Item {
        width: parent.width
        height: eyebrow.implicitHeight

        MicroLabel {
          id: eyebrow
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          label: root.service ? root.service.name : qsTr("Market")
          s: root.s
        }

        Rectangle {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          width: 26 * root.s
          height: 26 * root.s
          radius: 8 * root.s
          color: Qt.alpha(root.service ? root.service.trendColor : Theme.brand, 0.16)
          GlyphIcon {
            anchors.centerIn: parent
            width: 15 * root.s
            height: 15 * root.s
            name: "sparkle"
            color: root.service ? root.service.trendColor : Theme.brand
          }
        }
      }

      // price + change.
      Row {
        spacing: 10 * root.s
        PriceText {
          id: priceText
          anchors.bottom: parent.bottom
          service: root.service
          s: root.s
          pixelSize: 40 * root.s
        }
        ChangeBadge {
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 6 * root.s
          service: root.service
          s: root.s
        }
      }

      // "compared to" subline / error.
      Text {
        width: parent.width
        elide: Text.ElideRight
        text: {
          if (!root.service) return "";
          if (root.service.error.length > 0 && !root.service.hasData)
            return root.service.error;
          return qsTr("Compared to %1 %2")
            .arg(root.service.fmtPrice(root.service.prevClose))
            .arg(root.service.windowLabel);
        }
        color: Theme.faint
        font.family: Theme.font
        font.pixelSize: 12 * root.s
        font.weight: Font.Medium
      }
    }

    // the 2.5D ridgeline hero.
    Ridgeline {
      id: ridge
      x: root.pad
      y: col.y + col.implicitHeight + root.pad
      width: parent.width - root.pad * 2
      height: 176 * root.s
      visible: root.service ? root.service.hasData : false
      values: root.service ? root.service.spark : []
      min: root.service ? root.service.sparkMin : 0
      max: root.service ? root.service.sparkMax : 1
      crest: root.service ? root.service.trendColor : Theme.brand
    }
  }
}
