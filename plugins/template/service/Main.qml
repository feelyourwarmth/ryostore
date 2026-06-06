import QtQuick

// The plugin's `main` entry point: persistent, non-visual state. It loads once and
// survives while the popout opens and closes. The framePanel reaches it through
// pluginApi.mainInstance.
Item {
  id: root

  property var pluginApi

  property int clickCount

  function increment(): void {
    clickCount += 1;
  }
}
