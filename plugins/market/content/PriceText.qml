pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit.Singletons

// The big tabular price. On a value change it flashes the trend colour and
// nudges up a hair, then settles back to cream - a passive "it just ticked"
// signal. Uses tabular figures (mono) so digits don't jitter width as they roll.
Item {
  id: root

  property var service: null
  property real s: 1
  property real pixelSize: 40 * s
  readonly property real value: root.service ? root.service.price : 0

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  Text {
    id: label
    text: root.service ? root.service.fmtPrice(root.value) : "--"
    font.family: Theme.mono
    font.pixelSize: root.pixelSize
    font.weight: Font.Bold

    property real nudge: 0
    y: -nudge

    // flash + nudge whenever the price changes.
    property color flashColor: Theme.cream
    color: flashColor

    Behavior on flashColor { ColorAnimation { duration: Motion.standard } }
  }

  // drive the flash/nudge off value changes without a running timer.
  onValueChanged: tick.restart()
  SequentialAnimation {
    id: tick
    ScriptAction { script: {
      label.flashColor = root.service ? root.service.trendColor : Theme.cream;
      label.nudge = 3 * root.s;
    } }
    NumberAnimation { target: label; property: "nudge"; to: 0; duration: Motion.standard; easing.type: Easing.OutCubic }
    ScriptAction { script: label.flashColor = Theme.cream }
  }
}
