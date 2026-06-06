import QtQuick
import QtQuick.Layouts
import qs.settingsgui.Commons
import qs.settingsgui.Widgets

// The `settings` entry point. The host loads this with `pluginApi` set and calls
// saveSettings() on Apply.
ColumnLayout {
  id: root

  property var pluginApi
  readonly property int preferredWidth: 480

  spacing: Style.marginM
  Layout.fillWidth: true

  function saveSettings() {
    pluginApi.pluginSettings.greeting = greetingField.text.trim();
    pluginApi.saveSettings();
  }

  NText {
    text: I18n.tr("Greeting")
    pointSize: Style.fontSizeM
    font.weight: Style.fontWeightMedium
    color: Color.mOnSurface
  }

  NTextInput {
    id: greetingField
    Layout.fillWidth: true
    placeholderText: I18n.tr("Shown at the top of the popout")
    inputIconName: "chat"
    text: (root.pluginApi && root.pluginApi.pluginSettings ? root.pluginApi.pluginSettings.greeting : "") || ""
  }
}
