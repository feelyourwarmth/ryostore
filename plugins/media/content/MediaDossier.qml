pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

/**
 * The default media face: a carbon-dossier now-playing tile. Square album art
 * sits on the left, washed into the surface on its right edge; the right column
 * carries the 力 MEDIA eyebrow, the title, the artist, a mono source/time line,
 * the Ryoku wave seek and a flat vermilion transport seal. Reads state only
 * through `root.service` (the media plugin's MPRIS resolver); draws its own
 * surface gradient + corner ticks so the host slot's `bg:"none"` looks right.
 *
 * Ported from ryoku/shell/quickshell/pill/Media.qml. The pill-only bits (live
 * cover-fade pair, soul-bead seam handoff, MultiEffect bleed background) are
 * intentionally dropped: this is a tile, not a morphing pill.
 */
Item {
  id: root

  property var service
  property real s: 1
  property real cw: 360

  implicitWidth: cw
  implicitHeight: 150 * s

  // Geometry constants, copied verbatim from the pill so the eye-line matches
  // it across the two surfaces.
  readonly property real artW: 118 * s
  readonly property real textX: 134 * s
  readonly property real edgePad: 18 * s

  // The mid-surface tone the art fades into on its right edge. Linear-RGB mix
  // of the two surface stops, so the wash reads as "the card", not as a tint.
  readonly property color washMid: Qt.rgba(
    (Theme.cardTop.r + Theme.cardBot.r) * 0.5,
    (Theme.cardTop.g + Theme.cardBot.g) * 0.5,
    (Theme.cardTop.b + Theme.cardBot.b) * 0.5,
    1)

  // Per-face accent: same call faces use everywhere, kept as a property so the
  // children bind by reference and a wallust palette swap repaints in place.
  readonly property color accent: root.service ? root.service.accentColor() : Theme.brand

  readonly property bool hasArtUrl: (root.service?.artUrl ?? "") !== ""
  readonly property string coverFallbackUrl: {
    var dir = root.service?.pluginApi?.pluginDir ?? "";
    return dir.length > 0 ? ("file://" + dir + "/assets/cover.jpg") : "";
  }

  function _fmt(sec) {
    if (!(sec > 0))
      return "0:00";
    var t = Math.floor(sec);
    var m = Math.floor(t / 60);
    var ss = t % 60;
    return m + ":" + (ss < 10 ? "0" + ss : ss);
  }

  // Own surface: rounded card with the wallust-aware top->bottom gradient. Clip
  // so the album art's square corners get cut into the radius along with us.
  ClippingRectangle {
    anchors.fill: parent
    radius: 16 * root.s
    color: "transparent"

    Rectangle {
      anchors.fill: parent
      gradient: Gradient {
        GradientStop { position: 0.0; color: Theme.cardTop }
        GradientStop { position: 1.0; color: Theme.cardBot }
      }
    }

    // Album art column: fills the left strip, rounded on its own (artRadius is
    // a service-side setting; 0.6 brings it from "pill radius" to "tile radius"
    // so it nests cleanly inside the outer 16*s corner).
    ClippingRectangle {
      id: artClip
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: root.artW
      radius: (root.service?.artRadius ?? 14) * 0.6 * root.s
      color: Theme.tileBg

      Image {
        id: coverArt
        anchors.fill: parent
        // Bind through hasArtUrl so an art-less player clears the source
        // instead of leaving the last URL holding the decoded pixmap.
        source: root.hasArtUrl ? root.service.artUrl : ""
        sourceSize: Qt.size(Math.ceil(width * 2), Math.ceil(height * 2))
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        visible: root.hasArtUrl && status === Image.Ready
      }

      Image {
        id: coverFallback
        anchors.fill: parent
        source: !root.hasArtUrl ? root.coverFallbackUrl : ""
        sourceSize: Qt.size(Math.ceil(width * 2), Math.ceil(height * 2))
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        visible: !root.hasArtUrl && status === Image.Ready
      }

      GlyphIcon {
        anchors.centerIn: parent
        width: 40 * root.s
        height: width
        name: "music"
        color: Theme.subtle
        visible: !coverArt.visible && !coverFallback.visible
      }
    }

    // Horizontal wash that fades the art into the card on its right edge, so
    // there's no hard seam between cover and surface even when the cover is
    // edge-to-edge dark.
    Rectangle {
      anchors.left: parent.left
      anchors.leftMargin: 62 * root.s
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: 56 * root.s
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: Qt.alpha(root.washMid, 0) }
        GradientStop { position: 0.7; color: Qt.alpha(root.washMid, 0.8) }
        GradientStop { position: 1.0; color: root.washMid }
      }
    }

    // Right column: 力 MEDIA eyebrow, marquee title, marquee artist. Anchors to
    // both edges so the marquees know their true width and can decide whether
    // to elide or scroll.
    Column {
      anchors.left: parent.left
      anchors.leftMargin: root.textX
      anchors.right: parent.right
      anchors.rightMargin: root.edgePad
      anchors.top: parent.top
      anchors.topMargin: 14 * root.s
      spacing: 3 * root.s

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
        text: root.service?.title ?? ""
        color: Theme.cream
        pixelSize: 17 * root.s
        weight: Font.DemiBold
        // Scroll only while playing AND on-screen, so a paused tile is fully
        // still (the idle-RAM intent); a long paused title elides instead.
        active: root.visible && (root.service?.playing ?? false)
      }

      Marquee {
        anchors.left: parent.left
        anchors.right: parent.right
        text: root.service?.artist ?? ""
        color: Theme.dim
        pixelSize: 11.5 * root.s
        active: root.visible && (root.service?.playing ?? false)
        visible: text.length > 0
      }
    }

    // Mono source · position · length line. Tabular figures so the clock
    // digits don't dance; uppercase + letter-spacing to read as metadata, not
    // body copy. Self-gates on the showSource setting.
    Text {
      anchors.left: parent.left
      anchors.leftMargin: root.textX
      anchors.right: transport.left
      anchors.rightMargin: 10 * root.s
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 44 * root.s
      elide: Text.ElideRight
      text: {
        if (!root.service)
          return "";
        const head = root.service.playerService.length > 0
          ? root.service.playerService + " · " : "";
        const cur = root._fmt(root.service.positionSec);
        return head + cur + " · " + root._fmt(root.service.lengthSec);
      }
      color: Theme.dim
      font.family: Theme.mono
      font.pixelSize: 9 * root.s
      font.features: { "tnum": 1 }
      font.capitalization: Font.AllUppercase
      font.letterSpacing: 1 * root.s
      visible: (root.service?.showSource ?? true)
    }

    Transport {
      id: transport
      anchors.right: parent.right
      anchors.rightMargin: root.edgePad
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 38 * root.s
      service: root.service
      s: root.s
    }

    WaveSeek {
      anchors.left: parent.left
      anchors.leftMargin: root.textX
      anchors.right: parent.right
      anchors.rightMargin: root.edgePad
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 10 * root.s
      service: root.service
      s: root.s
      accent: root.accent
      visible: (root.service?.showSeek ?? true)
    }

    CornerTicks {
      anchors.fill: parent
      anchors.margins: 9 * root.s
      s: root.s
    }
  }
}
