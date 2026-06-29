pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// Spectrum face: a slim metadata strip (album thumb + 力 MEDIA eyebrow + title
// marquee + transport seal) stacked on top of the live cava bars hero. The
// service already runs cava whenever design==='spectrum' && playing, so the
// bars animate for free here — no extra gating needed beyond binding `levels`.
// Bars rest flat (faint baseline only) when paused, when cava is missing, or
// while the face is hidden.
Item {
  id: root

  property var service
  property real s: 1
  property real cw: 360

  readonly property color accent: root.service ? root.service.accentColor() : Theme.brand
  readonly property real sidePad: 14 * s
  readonly property real topPad: 8 * s
  readonly property real bottomPad: 8 * s
  readonly property real stripH: 56 * s
  readonly property real barsH: 96 * s
  readonly property real contentW: cw - 2 * sidePad
  readonly property bool showTime: root.service?.showSource ?? false
  readonly property real timeLineH: showTime ? 14 * s : 0

  implicitWidth: cw
  implicitHeight: topPad + stripH + barsH + timeLineH + bottomPad

  function _fmt(sec) {
    if (!(sec > 0))
      return "0:00";
    const t = Math.floor(sec);
    const m = Math.floor(t / 60);
    const ss = t % 60;
    return m + ":" + (ss < 10 ? "0" + ss : ss);
  }

  // Surface: card gradient + framing ticks.
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

  // Top strip: thumb (left), eyebrow + title column (centre), transport (right).
  Item {
    id: strip
    x: root.sidePad
    y: root.topPad
    width: root.contentW
    height: root.stripH

    ClippingRectangle {
      id: thumb
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      width: 40 * root.s
      height: 40 * root.s
      radius: 8 * root.s
      color: Theme.tileBg

      // Prefer the player's art; fall back to the plugin's bundled cover, then
      // a music glyph if neither resolves.
      readonly property string artUrl: root.service?.artUrl ?? ""
      readonly property string fallbackUrl: root.service?.pluginApi?.pluginDir
        ? ("file://" + root.service.pluginApi.pluginDir + "/assets/cover.jpg")
        : ""
      readonly property string source: artUrl !== "" ? artUrl : fallbackUrl

      Image {
        id: art
        anchors.fill: parent
        source: thumb.source
        sourceSize: Qt.size(Math.ceil(width * 2), Math.ceil(height * 2))
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        visible: status === Image.Ready
      }

      GlyphIcon {
        anchors.centerIn: parent
        width: 22 * root.s
        height: 22 * root.s
        name: "music"
        color: Theme.subtle
        visible: art.status !== Image.Ready
      }
    }

    Transport {
      id: transport
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      service: root.service
      s: root.s
      accent: root.accent
    }

    Column {
      anchors.left: thumb.right
      anchors.leftMargin: 12 * root.s
      anchors.right: transport.left
      anchors.rightMargin: 10 * root.s
      anchors.verticalCenter: parent.verticalCenter
      spacing: 4 * root.s

      Row {
        spacing: 7 * root.s

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "力"
          color: Theme.brand
          font.family: Theme.fontJp
          font.pixelSize: 11 * root.s
          font.weight: Font.DemiBold
        }

        MicroLabel {
          anchors.verticalCenter: parent.verticalCenter
          label: "MEDIA"
          s: root.s
        }
      }

      Marquee {
        width: parent.width
        text: root.service?.title ?? ""
        color: Theme.cream
        pixelSize: 14 * root.s
        weight: Font.DemiBold
        active: root.visible && (root.service?.playing ?? false)
      }
    }
  }

  // Hero: the live cava bars. Repaints only on levels change (see SpectrumBars);
  // the service stops emitting when paused, so this naturally rests flat.
  SpectrumBars {
    id: hero
    x: root.sidePad
    anchors.top: strip.bottom
    width: root.contentW
    barHeight: root.barsH
    accent: root.accent
    s: root.s
    levels: root.service?.spectrum?.levels ?? []
  }

  // Optional thin mono pos/len + source line under the bars. Tabular figures
  // so the seconds don't jitter horizontally between ticks. Pos/len sit at
  // the left, source identity at the right.
  Item {
    id: timeLine
    visible: root.showTime
    x: root.sidePad
    anchors.top: hero.bottom
    anchors.topMargin: 3 * root.s
    width: root.contentW
    height: 11 * root.s

    Row {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      spacing: 6 * root.s

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root._fmt(root.service?.positionSec ?? 0)
        color: Theme.dim
        font.family: Theme.mono
        font.pixelSize: 9 * root.s
        font.features: { "tnum": 1 }
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1 * root.s
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "·"
        color: Theme.faint
        font.family: Theme.mono
        font.pixelSize: 9 * root.s
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root._fmt(root.service?.lengthSec ?? 0)
        color: Theme.faint
        font.family: Theme.mono
        font.pixelSize: 9 * root.s
        font.features: { "tnum": 1 }
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1 * root.s
      }
    }

    Text {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: (root.service?.playerService ?? "").toUpperCase()
      color: Theme.faint
      font.family: Theme.mono
      font.pixelSize: 9 * root.s
      font.capitalization: Font.AllUppercase
      font.letterSpacing: 1 * root.s
      elide: Text.ElideRight
      visible: text.length > 0
    }
  }
}
