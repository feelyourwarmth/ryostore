pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// Compact one-liner media face. A small rounded album thumb on the left, a
// Marquee title with a thin Ryoku-wave seek line beneath it filling the middle,
// and a single play/pause control sealed to the right. Reads only via
// `root.service`; animation/decode is gated through the parts (Marquee on
// `root.visible`, WaveSeek's poke timer on visible+playing) so a hidden or
// paused face costs nothing.
Item {
  id: root

  property var service
  property real s: 1
  property real cw: 360

  implicitWidth: cw
  implicitHeight: 64 * s

  readonly property color accent: root.service ? root.service.accentColor() : Theme.brand
  readonly property real pad: 10 * s
  readonly property real gap: 12 * s
  readonly property real thumb: 44 * s
  readonly property real ctrl: 22 * s
  readonly property real ctrlHit: ctrl + 12 * s

  // Own surface: the dossier card gradient + rounded corners so the host's
  // `bg:"none"` slot still looks framed.
  Rectangle {
    anchors.fill: parent
    radius: 14 * root.s
    gradient: Gradient {
      GradientStop { position: 0.0; color: Theme.cardTop }
      GradientStop { position: 1.0; color: Theme.cardBot }
    }
  }

  // Faint L-bracket registration ticks - the carbon-dossier signature.
  CornerTicks {
    anchors.fill: parent
    anchors.margins: 9 * root.s
    s: root.s
  }

  // Album thumb. Clipped to a rounded square; sourceSize capped to 2x draw.
  ClippingRectangle {
    id: artClip
    anchors.left: parent.left
    anchors.leftMargin: root.pad
    anchors.verticalCenter: parent.verticalCenter
    width: root.thumb
    height: root.thumb
    radius: 8 * root.s
    color: Theme.tileBg

    readonly property string artUrl: root.service ? root.service.artUrl : ""
    readonly property string fallbackUrl: root.service && root.service.pluginApi
      ? "file://" + root.service.pluginApi.pluginDir + "/assets/cover.jpg" : ""
    readonly property bool hasArt: artUrl !== "" && cover.status === Image.Ready
    readonly property bool hasFallback: !hasArt && coverFallback.status === Image.Ready

    Image {
      id: cover
      anchors.fill: parent
      source: artClip.artUrl
      sourceSize: Qt.size(Math.ceil(width * 2), Math.ceil(height * 2))
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: true
      visible: artClip.hasArt
    }

    Image {
      id: coverFallback
      anchors.fill: parent
      source: artClip.hasArt ? "" : artClip.fallbackUrl
      sourceSize: Qt.size(Math.ceil(width * 2), Math.ceil(height * 2))
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: true
      visible: artClip.hasFallback
    }

    GlyphIcon {
      anchors.centerIn: parent
      width: 22 * root.s
      height: width
      name: "music"
      color: Theme.subtle
      visible: !artClip.hasArt && !artClip.hasFallback
    }
  }

  // Play/pause cap on the right. The hit area is padded out so a 22*s glyph
  // still has a comfortable click target.
  Item {
    id: playCtl
    anchors.right: parent.right
    anchors.rightMargin: root.pad
    anchors.verticalCenter: parent.verticalCenter
    width: root.ctrlHit
    height: root.ctrlHit

    GlyphIcon {
      anchors.centerIn: parent
      width: root.ctrl
      height: root.ctrl
      name: (root.service?.playing ?? false) ? "pause" : "play"
      color: Theme.cream
      opacity: playArea.enabled ? 1 : 0.4
      Behavior on opacity { NumberAnimation { duration: Motion.fast } }
    }

    MouseArea {
      id: playArea
      anchors.fill: parent
      hoverEnabled: true
      enabled: (root.service?.canTogglePlaying ?? false)
      cursorShape: Qt.PointingHandCursor
      onClicked: if (root.service) root.service.togglePlaying()
    }
  }

  // Centre column fills the rest. Title elides/scrolls; seek wave is read-only
  // and visibly gated on the service setting.
  Column {
    anchors.left: artClip.right
    anchors.leftMargin: root.gap
    anchors.right: playCtl.left
    anchors.rightMargin: root.gap
    anchors.verticalCenter: parent.verticalCenter
    spacing: 4 * root.s

    Marquee {
      width: parent.width
      text: root.service ? root.service.title : ""
      color: Theme.cream
      pixelSize: 14 * root.s
      weight: Font.DemiBold
      active: root.visible && (root.service?.playing ?? false)
    }

    WaveSeek {
      width: parent.width
      service: root.service
      s: root.s
      accent: root.accent
      interactive: false
      visible: root.service?.showSeek ?? true
    }
  }
}
