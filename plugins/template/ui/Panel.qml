pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Ryoku.Config
import qs.components
import qs.components.controls

// The `framePanel` entry point: the popout. The shell's frame host sets `pluginApi`,
// `screen` and the live `active` flag, then slides this in when its corner is hovered.
// All state lives in the service, read via pluginApi.mainInstance.
Item {
  id: root

  property var pluginApi
  property ShellScreen screen
  property bool active

  readonly property var service: pluginApi ? pluginApi.mainInstance : null
  readonly property string greeting: (pluginApi && pluginApi.pluginSettings ? pluginApi.pluginSettings.greeting : "") || ""

  implicitWidth: 360
  implicitHeight: 200

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Tokens.padding.large
    spacing: Tokens.spacing.large

    RowLayout {
      Layout.fillWidth: true
      spacing: Tokens.spacing.normal

      StyledRect {
        implicitWidth: implicitHeight
        implicitHeight: titleIcon.implicitHeight + Tokens.padding.smaller * 2
        radius: Tokens.rounding.full
        color: Colours.tPalette.m3surfaceContainerHigh
        border.width: 1
        border.color: Qt.alpha(Colours.palette.m3outline, 0.28)

        MaterialIcon {
          id: titleIcon

          anchors.centerIn: parent
          text: "extension"
          color: Colours.palette.m3primary
          font.pointSize: Tokens.font.size.large
        }
      }

      StyledText {
        Layout.fillWidth: true
        text: qsTr("Template")
        font.pointSize: Tokens.font.size.normal
        elide: Text.ElideRight
      }
    }

    StyledText {
      Layout.fillWidth: true
      text: root.greeting
      color: Colours.palette.m3onSurfaceVariant
      font.pointSize: Tokens.font.size.normal
      wrapMode: Text.WordWrap
    }

    Item {
      Layout.fillHeight: true
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Tokens.spacing.normal

      StyledText {
        Layout.fillWidth: true
        text: qsTr("Clicked %1 times").arg(root.service?.clickCount ?? 0)
        color: Colours.palette.m3onSurface
        font.pointSize: Tokens.font.size.normal
      }

      IconTextButton {
        icon: "add"
        text: qsTr("Count")
        enabled: root.service !== null
        onClicked: root.service.increment()
      }
    }
  }
}
