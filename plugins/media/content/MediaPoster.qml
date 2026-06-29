pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

/**
 * Full-bleed album art on a ClippingRectangle tile, with a bottom scrim that
 * carries the 力 MEDIA eyebrow, a marquee title, a dim artist, and the Ryoku
 * WaveSeek. The art runs through a MultiEffect colour filter so `posterFilter`
 * retunes the print live without touching the surface; `artRadius` rounds the
 * tile to taste. An opt-in cava strip floats just above the text and is only
 * rendered (and only fed by the service) when `spectrumOverlay` is on, so a
 * quiet face stays cold. CornerTicks frame the whole thing.
 */
Item {
  id: root

  property var service
  property real s: 1
  property real cw: 360

  implicitWidth: cw
  implicitHeight: Math.round(cw * 0.78)

  readonly property color accent: root.service ? root.service.accentColor() : Theme.brand
  readonly property var fp: _filter(root.service ? root.service.posterFilter : "none")

  /**
   * Colour filter mapped onto MultiEffect's adjustments, copied verbatim from
   * `plugins/photo-frame/content/PhotoFrame.qml` so a framed print and a
   * now-playing poster share one identity.
   */
  function _filter(name) {
    switch (name) {
    case "mono":  return { sat: -1.00, bri:  0.00, con:  0.00, col: 0.00, colC: "#000000" };
    case "noir":  return { sat: -1.00, bri: -0.04, con:  0.28, col: 0.00, colC: "#000000" };
    case "sepia": return { sat: -0.65, bri:  0.04, con:  0.05, col: 0.42, colC: "#6f4e37" };
    case "warm":  return { sat:  0.12, bri:  0.02, con:  0.03, col: 0.16, colC: "#ff7a45" };
    case "cool":  return { sat:  0.05, bri:  0.00, con:  0.03, col: 0.16, colC: "#5a7fff" };
    case "vivid": return { sat:  0.40, bri:  0.02, con:  0.12, col: 0.00, colC: "#000000" };
    case "fade":  return { sat: -0.20, bri:  0.07, con: -0.18, col: 0.00, colC: "#000000" };
    default:      return { sat:  0.00, bri:  0.00, con:  0.00, col: 0.00, colC: "#000000" };
    }
  }

  // The art tile IS the surface here, so the slot's `bg:"none"` reads cleanly
  // without a separate cardTop->cardBot wash behind it; `artRadius` owns the
  // corner roundness instead of the conventional 16*s tile radius.
  ClippingRectangle {
    id: poster
    anchors.fill: parent
    radius: (root.service ? root.service.artRadius : 14) * root.s
    color: Theme.tileBg

    Image {
      id: art
      anchors.fill: parent
      source: root.service && root.service.artUrl
        ? root.service.artUrl
        : (root.service && root.service.pluginApi && root.service.pluginApi.pluginDir
          ? "file://" + root.service.pluginApi.pluginDir + "/assets/cover.jpg"
          : "")
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: true
      smooth: true
      sourceSize.width: Math.ceil(width * 2)
      sourceSize.height: Math.ceil(height * 2)

      // Live colour filter keyed by `posterFilter`. The `fp` binding returns a
      // fresh object literal on every change, so the sub-bindings here
      // re-evaluate the moment the user flips filter modes.
      layer.enabled: true
      layer.effect: MultiEffect {
        saturation: root.fp.sat
        brightness: root.fp.bri
        contrast: root.fp.con
        colorization: root.fp.col
        colorizationColor: root.fp.colC
      }
    }

    // Last-resort placeholder when neither the track art nor the bundled
    // cover.jpg fallback loaded - keeps the tile from going visually blank.
    GlyphIcon {
      anchors.centerIn: parent
      width: 56 * root.s
      height: width
      name: "music"
      color: Theme.subtle
      visible: art.status !== Image.Ready
    }

    // Bottom scrim: transparent -> Theme.cardBot. Bleeds high enough that an
    // opt-in spectrum strip stays legible against busy artwork too.
    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: Math.round(parent.height * 0.55)
      gradient: Gradient {
        GradientStop { position: 0.0;  color: Qt.alpha(Theme.cardBot, 0) }
        GradientStop { position: 0.55; color: Qt.alpha(Theme.cardBot, 0.7) }
        GradientStop { position: 1.0;  color: Qt.alpha(Theme.cardBot, 0.95) }
      }
    }

    // Opt-in cava strip just above the text. Repaints only on a `levels`
    // change (no idle timer); the service stops feeding it the moment
    // `spectrumOverlay` flips off, so the cava process tears down with it.
    SpectrumBars {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: 16 * root.s
      anchors.rightMargin: 16 * root.s
      anchors.bottom: info.top
      anchors.bottomMargin: 8 * root.s
      visible: root.service ? root.service.spectrumOverlay : false
      levels: root.service && root.service.spectrum ? root.service.spectrum.levels : []
      accent: root.accent
      s: root.s
      barHeight: 40 * root.s
    }

    Column {
      id: info
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.leftMargin: 16 * root.s
      anchors.rightMargin: 16 * root.s
      anchors.bottomMargin: 14 * root.s
      spacing: 4 * root.s

      // 力 MEDIA eyebrow - the dossier idiom: vermilion kanji + mono reg dot
      // + uppercase mono label.
      Row {
        spacing: 7 * root.s
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "力"
          color: Theme.brand
          font.family: Theme.fontJp
          font.pixelSize: 12 * root.s
          font.weight: Font.Bold
        }
        MicroLabel {
          anchors.verticalCenter: parent.verticalCenter
          label: "MEDIA"
          s: root.s
        }
      }

      Marquee {
        width: parent.width
        text: root.service ? root.service.title : ""
        color: Theme.cream
        pixelSize: 16 * root.s
        weight: Font.DemiBold
        active: root.visible && (root.service?.playing ?? false)
      }

      Marquee {
        width: parent.width
        text: root.service ? root.service.artist : ""
        color: Theme.dim
        pixelSize: 12 * root.s
        active: root.visible && (root.service?.playing ?? false)
      }

      WaveSeek {
        width: parent.width
        service: root.service
        s: root.s
        accent: root.accent
        visible: root.service ? root.service.showSeek : true
      }
    }
  }

  // Faint L-bracket reg ticks framing the print like an editorial specimen
  // sheet - same convention as every other face.
  CornerTicks {
    anchors.fill: parent
    anchors.margins: 9 * root.s
    s: root.s
  }
}
