pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit.Singletons

// Single-line text that ping-pongs when it's wider than its space. Caller sets
// the geometry (anchors/width) and `active` gates the motion - elide by default,
// scroll only when overflowing AND active && visible. Ported from
// ryoku/shell/quickshell/pill/Marquee.qml.
Item {
  id: root

  property string text: ""
  property color color: Theme.cream
  property real pixelSize: 14
  property int weight: Font.Normal
  property bool active: true

  implicitHeight: label.implicitHeight
  clip: true

  readonly property bool overflowing: label.implicitWidth > width

  Text {
    id: label
    anchors.verticalCenter: parent.verticalCenter
    x: 0
    text: root.text
    color: root.color
    font.family: Theme.font
    font.pixelSize: root.pixelSize
    font.weight: root.weight
    elide: root.overflowing ? Text.ElideNone : Text.ElideRight
    width: root.overflowing ? implicitWidth : root.width

    SequentialAnimation {
      id: anim
      loops: Animation.Infinite
      PauseAnimation { duration: 1800 }
      NumberAnimation {
        target: label
        property: "x"
        from: 0
        to: -(label.implicitWidth - root.width)
        duration: Math.max(1, label.implicitWidth - root.width) * 22
        easing.type: Easing.InOutSine
      }
      PauseAnimation { duration: 1800 }
      NumberAnimation {
        target: label
        property: "x"
        from: -(label.implicitWidth - root.width)
        to: 0
        duration: Math.max(1, label.implicitWidth - root.width) * 22
        easing.type: Easing.InOutSine
      }
    }

    onTextChanged: root.sync()
  }

  onActiveChanged: sync()
  onVisibleChanged: sync()
  onOverflowingChanged: sync()
  Component.onCompleted: sync()

  /**
   * Fully imperative start/stop. A `running` binding gets severed by the
   * first imperative stop() and would leave the loop running forever inside
   * a hidden surface. Re-syncing on overflow/visible/active changes also
   * refreshes the captured from/to after a width change.
   */
  function sync() {
    anim.stop();
    label.x = 0;
    if (overflowing && active && visible)
      anim.start();
  }
}
