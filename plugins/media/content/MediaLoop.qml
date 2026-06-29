pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// Loop face: a looping-GIF backdrop with a bottom-anchored now-playing overlay
// and an opt-in cava bars layer. The GIF is the face surface (no card gradient
// underneath); a bottom-up scrim keeps the title/artist/seek readable over any
// frame. The AnimatedImage is gated on `root.visible && service.playing` so a
// hidden or paused face decodes nothing - on pause it freezes its current
// frame, on hide it drops to first-frame and stops. service.gifSource resolves
// to the bundled assets/sample.gif when gifPath is empty, so the loop is never
// blank.
Item {
  id: root

  property var service
  property real s: 1
  property real cw: 360

  implicitWidth: cw
  implicitHeight: Math.round(cw * 0.62)

  readonly property color accent: root.service ? root.service.accentColor() : Theme.brand

  ClippingRectangle {
    anchors.fill: parent
    radius: (root.service ? root.service.artRadius : 14) * root.s
    color: Theme.tileBg

    AnimatedImage {
      anchors.fill: parent
      source: root.service ? root.service.gifSource : ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: true
      playing: root.visible && (root.service?.playing ?? false)
      paused: !(root.service?.playing ?? false)
      // Cap decode budget at ~1.5x the draw size so a 4K source doesn't blow
      // RAM on a 360x223 tile.
      sourceSize: Qt.size(Math.ceil(width * 1.5), Math.ceil(height * 1.5))
    }

    // Bottom scrim: transparent at the top, opaque cardBot at the bottom, so
    // the overlay text always reads regardless of what frame the GIF is on.
    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: Math.round(parent.height * 0.62)
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.alpha(Theme.cardBot, 0) }
        GradientStop { position: 0.55; color: Qt.alpha(Theme.cardBot, 0.55) }
        GradientStop { position: 1.0; color: Qt.alpha(Theme.cardBot, 0.9) }
      }
    }

    // Opt-in cava overlay, parked just above the eyebrow. SpectrumBars repaints
    // only when `levels` changes, and service.spectrumNeeded already drops the
    // cava process unless this overlay is on, so the cost is zero when off.
    SpectrumBars {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: 16 * root.s
      anchors.rightMargin: 16 * root.s
      anchors.bottom: overlay.top
      anchors.bottomMargin: 8 * root.s
      visible: (root.service?.spectrumOverlay ?? false)
      levels: (root.service && root.service.spectrum) ? root.service.spectrum.levels : []
      accent: root.accent
      s: root.s
      barHeight: 36 * root.s
    }

    Column {
      id: overlay
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.leftMargin: 16 * root.s
      anchors.rightMargin: 16 * root.s
      anchors.bottomMargin: 14 * root.s
      spacing: 4 * root.s

      Row {
        spacing: 7 * root.s
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "力"
          color: Theme.brand
          font.family: Theme.fontJp
          font.weight: Font.Medium
          font.pixelSize: 13 * root.s
        }
        MicroLabel {
          anchors.verticalCenter: parent.verticalCenter
          label: "MEDIA"
          s: root.s
        }
      }

      Marquee {
        anchors.left: parent.left
        anchors.right: parent.right
        text: root.service ? root.service.title : ""
        color: Theme.cream
        pixelSize: 17 * root.s
        weight: Font.DemiBold
        active: root.visible && (root.service?.playing ?? false)
      }

      Marquee {
        anchors.left: parent.left
        anchors.right: parent.right
        text: root.service ? root.service.artist : ""
        color: Theme.dim
        pixelSize: 11.5 * root.s
        active: root.visible && (root.service?.playing ?? false)
        visible: text.length > 0
      }

      // 4px breather between metadata and the seek+transport row.
      Item { width: 1; height: 4 * root.s }

      // Seek row + transport, vertically centered on the taller of the two so
      // the wave stays aligned with the play seal. WaveSeek hides on showSeek
      // = false but the transport always renders, so the row collapses to just
      // the play controls in that case.
      Item {
        anchors.left: parent.left
        anchors.right: parent.right
        height: tr.implicitHeight

        Transport {
          id: tr
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          service: root.service
          s: root.s
          accent: root.accent
        }

        WaveSeek {
          anchors.left: parent.left
          anchors.right: tr.left
          anchors.rightMargin: 12 * root.s
          anchors.verticalCenter: parent.verticalCenter
          visible: (root.service?.showSeek ?? true)
          service: root.service
          s: root.s
          accent: root.accent
        }
      }
    }
  }

  CornerTicks {
    anchors.fill: parent
    anchors.margins: 9 * root.s
    s: root.s
  }
}
