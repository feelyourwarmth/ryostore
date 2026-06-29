pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// The `content` entry point: the plugin's one adaptive view. The host sets
// `density`, `s`, `widthBudget`, `active` and `pluginApi`, mounts this in the
// chosen host (a desktop tile here), and lays out at the size you report back.
// State lives in the service (pluginApi.mainInstance); settings come from the
// manifest's metadata.settings schema through pluginApi.pluginSettings.
Item {
  id: root

  property var pluginApi
  property var screen
  property bool active
  property string density: "compact"
  property real s: 1
  property real widthBudget: 0

  readonly property var service: pluginApi ? pluginApi.mainInstance : null
  readonly property string greeting: (pluginApi?.pluginSettings?.greeting ?? "") || qsTr("Hello from a Ryoku plugin")

  readonly property real contentW: widthBudget > 0 ? widthBudget : 320 * s

  implicitWidth: contentW
  implicitHeight: body.implicitHeight

  Column {
    id: body
    width: root.contentW
    spacing: 12 * root.s

    MicroLabel { label: qsTr("Template"); s: root.s }

    Text {
      width: root.contentW
      text: root.greeting
      color: Theme.subtle
      font.family: Theme.font
      font.pixelSize: 13 * root.s
      wrapMode: Text.WordWrap
    }

    Rectangle {
      width: root.contentW
      implicitHeight: 40 * root.s
      radius: Motion.rSmall * root.s
      color: Theme.tileBg
      border.width: 1
      border.color: Theme.border

      Text {
        anchors.left: parent.left
        anchors.leftMargin: 12 * root.s
        anchors.verticalCenter: parent.verticalCenter
        text: qsTr("Clicked %1 times").arg(root.service?.clickCount ?? 0)
        color: Theme.cream
        font.family: Theme.font
        font.pixelSize: 13 * root.s
      }

      Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 5 * root.s
        anchors.verticalCenter: parent.verticalCenter
        width: 30 * root.s
        height: 30 * root.s
        radius: Motion.rSmall * root.s
        color: tap.containsMouse ? Theme.brand : "transparent"
        border.width: 1
        border.color: Theme.border
        Behavior on color { ColorAnimation { duration: Motion.fast } }

        Text {
          anchors.centerIn: parent
          text: "+"
          color: tap.containsMouse ? Theme.cream : Theme.iconDim
          font.family: Theme.font
          font.pixelSize: 16 * root.s
        }

        MouseArea {
          id: tap
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.service?.increment()
        }
      }
    }
  }
}
