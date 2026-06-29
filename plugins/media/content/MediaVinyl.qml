pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// Vinyl face: a spinning album disc with a tonearm and an optional radial
// spectrum overlay. The disc rotates only while the service is playing
// (angle holds on pause), the tonearm lifts off the disc when paused, and
// the SpectrumRing only renders when the user's `spectrumOverlay` is on.
// Reads only via `root.service`; never touches the host `active` prop.
Item {
  id: root

  property var service
  property real s: 1
  property real cw: 360

  // ── derived state (every face read goes through `service`) ──────────────
  readonly property real discDiameter: Math.round(cw * 0.6)
  readonly property bool playing: root.service?.playing ?? false
  readonly property color accent: root.service ? root.service.accentColor() : Theme.brand
  readonly property string artUrl: root.service?.artUrl ?? ""
  readonly property string pluginDir: root.service?.pluginApi?.pluginDir ?? ""
  readonly property url fallbackArt: pluginDir ? ("file://" + pluginDir + "/assets/cover.jpg") : ""

  implicitWidth: cw
  implicitHeight: discDiameter + 78 * s

  // ── own surface ─────────────────────────────────────────────────────────
  // Slot bg is `"none"`, so every face paints its own card with the
  // wallust-aware top→bottom gradient and faint reg ticks framing it.
  Rectangle {
    anchors.fill: parent
    radius: 16 * root.s
    gradient: Gradient {
      GradientStop { position: 0.0; color: Theme.cardTop }
      GradientStop { position: 1.0; color: Theme.cardBot }
    }
  }

  CornerTicks {
    anchors.fill: parent
    anchors.margins: 9 * root.s
    s: root.s
  }

  // ── the disc ────────────────────────────────────────────────────────────
  // Album art clipped into a circle, with a darker concentric centre-label
  // ring and a tiny spindle hole on top. The whole Item spins as one, so
  // the label and spindle stay locked to the record (as they would on a
  // real pressing). Diameter is fixed at `Math.round(cw * 0.6)` so it
  // tracks the host width without drifting half-pixels.
  Item {
    id: disc

    width: root.discDiameter
    height: root.discDiameter
    x: Math.round((root.width - width) / 2)
    y: 12 * root.s

    // RAM-gated rotation. `running` is bound to visibility AND service.playing
    // (NEVER `active` — host hard-wires it true). On pause the binding stops
    // and `angle` holds at whatever value it had: no snap back to zero.
    transform: Rotation {
      id: spin
      origin.x: disc.width / 2
      origin.y: disc.height / 2
      angle: 0

      NumberAnimation on angle {
        from: 0
        to: 360
        duration: 7000
        loops: Animation.Infinite
        running: root.visible && root.playing
      }
    }

    // The vinyl + art body, clipped to a perfect circle.
    ClippingRectangle {
      id: discFace
      anchors.fill: parent
      radius: width / 2
      color: Theme.tileBg

      // Bottom layer: the music glyph fallback. Only visible when neither
      // the bundled cover nor the live art has decoded.
      GlyphIcon {
        anchors.centerIn: parent
        width: parent.width * 0.28
        height: width
        name: "music"
        color: Theme.subtle
        visible: !(remoteArt.status === Image.Ready) && !(localArt.status === Image.Ready)
      }

      // Middle layer: bundled `assets/cover.jpg` fallback. Covered by the
      // live art when it loads; shown when there's no `artUrl` (or it failed).
      Image {
        id: localArt
        anchors.fill: parent
        source: root.fallbackArt
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        sourceSize.width: Math.ceil(parent.width * 2)
        sourceSize.height: Math.ceil(parent.height * 2)
        visible: status === Image.Ready && !(remoteArt.status === Image.Ready)
      }

      // Top layer: the active track's cover art. Decode capped at 2× the
      // drawn size so a 4K cover URL doesn't waste a dozen megabytes of
      // pixmap RAM on a 200-px disc.
      Image {
        id: remoteArt
        anchors.fill: parent
        source: root.artUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        sourceSize.width: Math.ceil(parent.width * 2)
        sourceSize.height: Math.ceil(parent.height * 2)
        visible: status === Image.Ready
      }

      // Concentric centre label: the printed paper sticker, a darker disc
      // over the art. A hairline border gives it a soft die-cut edge.
      Rectangle {
        anchors.centerIn: parent
        width: Math.round(parent.width * 0.34)
        height: width
        radius: width / 2
        color: Qt.rgba(Theme.cardBot.r, Theme.cardBot.g, Theme.cardBot.b, 0.88)
        border.width: 1
        border.color: Qt.alpha(Theme.hair, 0.7)
      }

      // Spindle hole at the dead centre.
      Rectangle {
        anchors.centerIn: parent
        width: Math.max(3, Math.round(parent.width * 0.035))
        height: width
        radius: width / 2
        color: Theme.cardTop
      }
    }

    // Hairline circumscribing the disc, so it reads against the card even
    // on dark covers.
    Rectangle {
      anchors.fill: parent
      radius: width / 2
      color: "transparent"
      border.width: 1
      border.color: Qt.alpha(Theme.hair, 0.5)
    }
  }

  // ── radial spectrum overlay (opt-in) ────────────────────────────────────
  // Just larger than the disc; the part's carrier hairline sits ~rOuter*0.82
  // (see SpectrumRing.qml), so diameter * 1.25 puts the inner ring just
  // outside the disc edge and the bars extend further outward. The ring is
  // a Canvas that only repaints on `levels` change — no idle timer.
  SpectrumRing {
    anchors.centerIn: disc
    diameter: root.discDiameter * 1.25
    levels: root.service?.spectrum?.levels ?? []
    accent: root.accent
    s: root.s
    visible: root.service?.spectrumOverlay ?? false
  }

  // ── tonearm ─────────────────────────────────────────────────────────────
  // Mounted at the top-right corner of the card. The Item is drawn as a
  // thin arm with a cartridge head at its FAR (left) end and a pivot cap at
  // its NEAR (right) end. `transformOrigin: Item.Right` puts the rotation
  // pivot on the mount — so the arm swings from there exactly like the real
  // thing. The cap is a circle, so it looks identical despite co-rotating.
  //
  // Sign convention: with the pivot on the right end, positive rotation is
  // visually clockwise around it — that lifts the LEFT-pointing head UP and
  // away. So `rotation < 0` swings the head DOWN onto the disc (playing),
  // and `rotation > 0` lifts it off (paused).
  Item {
    id: tonearm

    readonly property real armLength: root.discDiameter * 0.62
    readonly property real armThickness: 4 * root.s
    readonly property real mountX: root.width - 22 * root.s
    readonly property real mountY: 22 * root.s

    width: armLength
    height: armThickness
    x: mountX - width
    y: mountY - height / 2

    transformOrigin: Item.Right
    rotation: root.playing ? -28 : 8
    Behavior on rotation {
      NumberAnimation { duration: Motion.standard; easing.type: Motion.easeStandard }
    }

    // The arm proper.
    Rectangle {
      anchors.fill: parent
      color: Theme.subtle
      radius: parent.height / 2
      antialiasing: true
    }

    // Cartridge head at the far (left) end. Painted in the active accent so
    // it pops against the disc when it swings down onto the art.
    Rectangle {
      x: -3 * root.s
      y: parent.height / 2 - height / 2 + 2 * root.s
      width: 10 * root.s
      height: 7 * root.s
      radius: 2 * root.s
      color: root.accent
      antialiasing: true
    }

    // Pivot mount cap at the near (right) end.
    Rectangle {
      x: parent.width - width + 5 * root.s
      y: parent.height / 2 - height / 2
      width: 12 * root.s
      height: 12 * root.s
      radius: width / 2
      color: Theme.tileBg
      border.width: 1
      border.color: Qt.alpha(Theme.hair, 0.8)
    }
  }

  // ── title / artist / transport ──────────────────────────────────────────
  // Stacked below the disc, centred. Marquees scroll only when overflowing
  // AND active && visible (see Marquee.qml), so they don't burn cycles
  // while the widget is offscreen.
  Column {
    id: meta

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: 18 * root.s
    anchors.rightMargin: 18 * root.s
    anchors.top: disc.bottom
    anchors.topMargin: 8 * root.s
    spacing: 2 * root.s

    Marquee {
      width: parent.width
      text: root.service?.title ?? ""
      color: Theme.cream
      pixelSize: 14 * root.s
      weight: Font.DemiBold
      active: root.visible && (root.service?.playing ?? false)
    }

    Marquee {
      width: parent.width
      text: root.service?.artist ?? ""
      color: Theme.dim
      pixelSize: 12 * root.s
      active: root.visible && (root.service?.playing ?? false)
    }

    Item {
      width: parent.width
      height: 4 * root.s
    }

    Transport {
      anchors.horizontalCenter: parent.horizontalCenter
      service: root.service
      s: root.s
      accent: root.accent
    }
  }
}
