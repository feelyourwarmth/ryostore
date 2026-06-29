pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit.Singletons

// Transport row: `‹` prev, a flat vermilion play seal (`▶` while playing else
// `Ⅱ`, with a small pulse on title change), `›` next. Each chevron and the seal
// dim + disable on the matching `service.can*` capability. Calls
// `service.previous/togglePlaying/next`. Ported from
// ryoku/shell/quickshell/pill/Media.qml ~134-417 (KanjiSkip + seal).
Row {
  id: root

  property var service
  property real s: 1
  property color accent: Theme.brand

  // 0..1 envelope driven by the title-change pulse.
  property real sealPulse: 0

  spacing: 14 * s

  // Pulses the seal each time the title changes, but only while playing -
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

  component KanjiSkip: Text {
    id: skip

    property bool can: false
    signal activated()

    anchors.verticalCenter: parent.verticalCenter
    font.family: Theme.font
    font.pixelSize: 13 * root.s
    color: skipArea.containsMouse ? Theme.cream : Theme.dim
    opacity: skip.can ? 1 : 0.4
    Behavior on color { ColorAnimation { duration: Motion.fast } }
    Behavior on opacity { NumberAnimation { duration: Motion.fast } }

    MouseArea {
      id: skipArea
      anchors.fill: parent
      anchors.margins: -6 * root.s
      hoverEnabled: true
      enabled: skip.can
      cursorShape: Qt.PointingHandCursor
      onClicked: skip.activated()
    }
  }

  // Linear-RGB mix for the desaturated-while-paused seal tint.
  function _mix(a, b, t) {
    return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
  }

  KanjiSkip {
    text: "‹"
    can: (root.service?.canGoPrevious ?? false)
    onActivated: if (root.service) root.service.previous()
  }

  Rectangle {
    id: seal
    anchors.verticalCenter: parent.verticalCenter
    width: 30 * root.s
    height: 30 * root.s
    radius: 4 * root.s
    scale: 1 + 0.06 * root.sealPulse

    /** 1 while playing, eases to 0 when paused; dims the flat fill. */
    property real sat: (root.service?.playing ?? false) ? 1 : 0
    Behavior on sat { NumberAnimation { duration: Motion.fast; easing.type: Motion.easeStandard } }

    opacity: sealArea.enabled ? 1 : 0.4
    Behavior on opacity { NumberAnimation { duration: Motion.fast } }

    color: root._mix(root.accent, Theme.tileBg, 0.55 * (1 - seal.sat))
    border.width: 1
    border.color: Qt.alpha(Theme.vermLit, 0.5)

    Text {
      anchors.centerIn: parent
      text: (root.service?.playing ?? false) ? "▶" : "Ⅱ"
      color: Theme.cream
      font.family: Theme.font
      font.pixelSize: 15 * root.s
      font.weight: Font.DemiBold
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

  KanjiSkip {
    text: "›"
    can: (root.service?.canGoNext ?? false)
    onActivated: if (root.service) root.service.next()
  }
}
