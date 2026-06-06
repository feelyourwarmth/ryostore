import QtQuick
import QtQuick.Layouts
import qs.settingsgui.Commons
import qs.settingsgui.Widgets

// Per-plugin settings page. The host (NPluginSettingsPopup) loads this with
// `pluginApi` set and calls saveSettings() on Apply.
ColumnLayout {
  id: root

  property var pluginApi
  readonly property int preferredWidth: 560

  spacing: Style.marginM
  Layout.fillWidth: true

  function saveSettings() {
    pluginApi.pluginSettings.apiKey = apiKeyField.text.trim();
    pluginApi.saveSettings();
  }

  NText {
    text: I18n.tr("panels.wallpaper.apikey-label")
    pointSize: Style.fontSizeM
    font.weight: Style.fontWeightMedium
    color: Color.mOnSurface
  }

  NTextInput {
    id: apiKeyField
    Layout.fillWidth: true
    placeholderText: I18n.tr("panels.wallpaper.apikey-placeholder")
    inputIconName: "key"
    text: (root.pluginApi && root.pluginApi.pluginSettings ? root.pluginApi.pluginSettings.apiKey : "") || ""
  }

  NText {
    Layout.fillWidth: true
    text: I18n.tr("panels.wallpaper.apikey-managed-by-env")
    pointSize: Style.fontSizeS
    color: Color.mOnSurfaceVariant
    wrapMode: Text.WordWrap
  }
}
