import QtQuick

// The plugin's `main` entry point: persistent, non-visual state. It loads once
// when the plugin is enabled and stays alive while the content mounts and
// unmounts, so its state survives. The content reaches it through
// pluginApi.mainInstance.
Item {
  id: root

  property var pluginApi

  property int clickCount

  function increment() { clickCount += 1; }
}
