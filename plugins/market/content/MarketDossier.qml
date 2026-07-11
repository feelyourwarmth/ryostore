pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

/**
 * The flagship market face: the reference "Income" card in the shell's dark
 * dossier idiom. An eyebrow row carrying the instrument name and the timeframe
 * chips; a big tabular PriceText with the ChangeBadge beside it; a
 * "compared to <baseline> <window>" subline; the Ridgeline hero (or the
 * fetching/error placeholder while there is nothing to draw); the provenance
 * MetaLine; and, when more than one symbol is tracked, the watchlist rows.
 * Reads state only through `root.service`; draws its own cardTop->cardBot
 * surface + CornerTicks so the host slot's bg:"none" is right.
 */
Item {
  id: root

  property var service: null
  property real s: 1
  property real cw: 360

  readonly property real pad: 18 * s
  readonly property bool showRows: root.service ? root.service.quotes.length > 1 : false

  implicitWidth: cw
  implicitHeight: surface.implicitHeight

  Rectangle {
    id: surface
    width: root.cw
    implicitHeight: col.implicitHeight + root.pad * 2
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

      // eyebrow: instrument name left, timeframe chips right.
      Item {
        width: parent.width
        height: Math.max(eyebrow.implicitHeight, chips.implicitHeight)

        MicroLabel {
          id: eyebrow
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          label: root.service && root.service.name.length > 0 ? root.service.name : qsTr("Market")
          s: root.s
        }
        WindowChips {
          id: chips
          anchors.right: parent.right
          anchors.rightMargin: 30 * root.s
          anchors.verticalCenter: parent.verticalCenter
          service: root.service
          s: root.s
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

      // "compared to" subline, window-aware (prev close for 1D, the window's
      // first sample otherwise - the same baseline the change badge uses).
      Text {
        width: parent.width
        visible: root.service ? root.service.hasData : false
        elide: Text.ElideRight
        text: root.service
          ? qsTr("Compared to %1 %2")
            .arg(root.service.fmtPrice(root.service.winBase))
            .arg(root.service.windowLabel)
          : ""
        color: Theme.faint
        font.family: Theme.font
        font.pixelSize: 12 * root.s
        font.weight: Font.Medium
      }

      Item { width: 1; height: 6 * root.s }

      // the 3D ridgeline hero with numbered price/time axes, or the
      // fetching/error placeholder while no history exists.
      Ridgeline {
        width: parent.width
        height: 200 * root.s
        visible: root.service ? root.service.hasData : false
        service: root.service
        crest: root.service ? root.service.trendColor : Theme.brand
      }
      FacePlaceholder {
        width: parent.width
        height: 90 * root.s
        visible: root.service ? !root.service.hasData : true
        service: root.service
        s: root.s
      }

      Item { width: 1; height: 2 * root.s }

      MetaLine {
        service: root.service
        s: root.s
      }

      // the rest of the watchlist, when there is one.
      Rectangle {
        visible: root.showRows
        width: parent.width
        height: 1
        color: Theme.hair
      }
      WatchRows {
        visible: root.showRows
        width: parent.width
        service: root.service
        s: root.s
      }
    }
  }
}
