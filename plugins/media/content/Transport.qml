pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// Transport row: prev, a flat vermilion play/pause seal (small pulse on title
// change), next. Buttons are vector GlyphIcons (play/pause/next/prev) so they
// stay crisp at any scale. The seal is ALWAYS the brand vermilion - the accent
// (wallust/brand/mono) retints the wave and spectrum, never this action button,
// so a "mono" accent can't blank the play glyph. Calls service.previous/
// togglePlaying/next; each control dims + disables on the matching service.can*.
Row {
  id: root

  property var service
  property real s: 1

  // 0..1 envelope driven by the title-change pulse.
  property real sealPulse: 0

  spacing: 13 * s

  function _mix(a, b, t) {
    return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
  }

  // Pulse the seal each time the title changes, but only while playing -
  // pause-time metadata refreshes shouldn't fire visual feedback.
  Connections {
    target: root.service ?? null
    function onTitleChanged() {
      if (root.service && root.service.playing)
        pulseAnim.restart();
    }
  }

  SequentialAnimation {
    id: pulseAnim
    NumberAnimation {
      target: root; property: "sealPulse"; to: 1
      duration: Motion.fast; easing.type: Motion.easeStandard
    }
    NumberAnimation {
      target: root; property: "sealPulse"; to: 0
      duration: Motion.standard; easing.type: Motion.easeStandard
    }
  }

  // A skip control: a filled vector glyph in a hit-padded MouseArea, dimmed +
  // disabled when the player can't go that way. Brightens on hover.
  component Skip: Item {
    id: skip
    property string glyph: "next"
    property bool can: false
    signal activated()

    anchors.verticalCenter: parent.verticalCenter
    width: 17 * root.s
    height: 17 * root.s
    opacity: skip.can ? 1 : 0.35
    Behavior on opacity { NumberAnimation { duration: Motion.fast } }

    GlyphIcon {
      anchors.fill: parent
      name: skip.glyph
      color: skipArea.containsMouse ? Theme.cream : Theme.subtle
      Behavior on color { ColorAnimation { duration: Motion.fast } }
    }

    MouseArea {
      id: skipArea
      anchors.fill: parent
      anchors.margins: -7 * root.s
      hoverEnabled: true
      enabled: skip.can
      cursorShape: Qt.PointingHandCursor
      onClicked: skip.activated()
    }
  }

  Skip {
    glyph: "prev"
    can: (root.service?.canGoPrevious ?? false)
    onActivated: if (root.service) root.service.previous()
  }

  Rectangle {
    id: seal
    anchors.verticalCenter: parent.verticalCenter
    width: 30 * root.s
    height: 30 * root.s
    radius: 8 * root.s
    scale: 1 + 0.06 * root.sealPulse

    // 1 while playing -> full vermilion; eases to 0 when paused -> desaturated
    // toward the tile so a paused seal reads as "stopped" without changing hue.
    property real sat: (root.service?.playing ?? false) ? 1 : 0
    Behavior on sat { NumberAnimation { duration: Motion.fast; easing.type: Motion.easeStandard } }

    opacity: sealArea.enabled ? 1 : 0.4
    Behavior on opacity { NumberAnimation { duration: Motion.fast } }

    // ALWAYS brand vermilion (never the accent). Only play state changes it.
    color: root._mix(Theme.verm, Theme.tileBg, 0.5 * (1 - seal.sat))
    border.width: 1
    border.color: Qt.alpha(Theme.vermLit, 0.5)

    GlyphIcon {
      anchors.centerIn: parent
      width: 14 * root.s
      height: 14 * root.s
      name: (root.service?.playing ?? false) ? "pause" : "play"
      color: Theme.cream
    }

    MouseArea {
      id: sealArea
      anchors.fill: parent
      anchors.margins: -4 * root.s
      hoverEnabled: true
      enabled: (root.service?.canTogglePlaying ?? false)
      cursorShape: Qt.PointingHandCursor
      onClicked: if (root.service) root.service.togglePlaying()
    }
  }

  Skip {
    glyph: "next"
    can: (root.service?.canGoNext ?? false)
    onActivated: if (root.service) root.service.next()
  }
}
