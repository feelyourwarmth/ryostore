pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// The `content` entry point for the `market` plugin: a thin selector that
// resolves the configured `design` into one of four face components, plus an
// in-widget watchlist editor. The host sets `pluginApi`, `density`, `s`,
// `widthBudget`, `active`; the service (pluginApi.mainInstance) holds all
// state. Faces never touch the host; they only read root.service. Each face
// reports its own implicitHeight, which this view forwards so the host can
// size the tile.
//
// Watchlist editing: the right-click menu can't type (wallpaper layer is
// mouse-only - the shell routes text fields to the hub), so free-text symbol
// entry lives here. A hover-reveal button opens a typed field; Enter hands the
// comma-separated list to the service, which persists it into plugins.json
// (the runtime watches that file, so the poll re-fetches live). While the
// field holds focus, `editing` is true and the host raises its keyboard grab -
// the same mechanism the search fields use.
Item {
  id: root

  property var pluginApi
  property var screen
  property bool active
  property string density: "compact"
  property real s: 1
  property real widthBudget: 0

  readonly property var service: pluginApi ? pluginApi.mainInstance : null
  readonly property real contentW: widthBudget > 0 ? widthBudget : 360 * s

  property bool editorOpen: false
  readonly property bool editing: editorOpen

  implicitWidth: contentW
  implicitHeight: faceLoader.item ? faceLoader.item.implicitHeight : 0

  function applyWatchlist(raw) {
    if (root.service && String(raw).trim().length > 0)
      root.service.setSymbols(raw);
    root.closeEditor();
  }
  function openEditor() {
    editField.text = root.service ? root.service.watchlist.join(", ") : "";
    root.editorOpen = true;
    Qt.callLater(() => editField.input.forceActiveFocus());
  }
  function closeEditor() {
    root.editorOpen = false;
    editField.input.focus = false;
  }

  Loader {
    id: faceLoader
    width: root.contentW
    sourceComponent: root.faceFor(root.service ? root.service.design : "dossier")
  }

  // Switch design string -> inline Component wrapping the matching face. Each
  // component binds the shared face contract (service, s, cw). Unknown values
  // fall back to dossier so a typo or stale setting never blanks the tile.
  function faceFor(d) {
    switch (d) {
      case "dossier": return dossierComp;
      case "line":    return lineComp;
      case "area":    return areaComp;
      case "minimal": return minimalComp;
      default:        return dossierComp;
    }
  }

  Component { id: dossierComp; MarketDossier { service: root.service; s: root.s; cw: root.contentW } }
  Component { id: lineComp;    MarketLine    { service: root.service; s: root.s; cw: root.contentW } }
  Component { id: areaComp;    MarketArea    { service: root.service; s: root.s; cw: root.contentW } }
  Component { id: minimalComp; MarketMinimal { service: root.service; s: root.s; cw: root.contentW } }

  // hover-reveal "edit watchlist" button, top-right corner. The faces keep
  // that corner clear (their chips/meta rows stop short of it).
  HoverHandler { id: tileHover }
  Rectangle {
    id: editBtn
    z: 5
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: 10 * root.s
    width: 22 * root.s
    height: 22 * root.s
    radius: 7 * root.s
    color: editMa.containsMouse ? Qt.alpha(Theme.brand, 0.92) : Qt.rgba(0, 0, 0, 0.42)
    border.width: 1
    border.color: Theme.hair
    opacity: (tileHover.hovered && !root.editorOpen) ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: Motion.fast } }
    Text {
      anchors.centerIn: parent
      text: "$"
      color: editMa.containsMouse ? Theme.cardBot : Theme.cream
      font.family: Theme.mono
      font.pixelSize: 13 * root.s
      font.weight: Font.Bold
    }
    MouseArea {
      id: editMa
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.openEditor()
    }
  }

  // editor overlay: scrim + a small card carrying the typed watchlist field.
  Item {
    id: overlay
    z: 10
    anchors.fill: parent
    visible: root.editorOpen

    Rectangle {
      anchors.fill: parent
      radius: 20 * root.s
      color: Qt.rgba(0, 0, 0, 0.55)
      MouseArea { anchors.fill: parent; onClicked: root.closeEditor() }
    }

    Rectangle {
      anchors.centerIn: parent
      width: Math.min(root.contentW - 40 * root.s, 300 * root.s)
      implicitHeight: card.implicitHeight + 26 * root.s
      radius: 14 * root.s
      color: Theme.cardTop
      border.width: 1
      border.color: Theme.border

      // swallow clicks on the card so they don't fall through to the scrim.
      MouseArea { anchors.fill: parent }

      Column {
        id: card
        anchors.centerIn: parent
        width: parent.width - 28 * root.s
        spacing: 10 * root.s

        MicroLabel { label: qsTr("Set watchlist"); s: root.s }

        SearchField {
          id: editField
          width: parent.width
          s: root.s
          kanji: "$"
          placeholder: qsTr("e.g. BTC-USD, AAPL, ^GSPC")
          onAccepted: root.applyWatchlist(editField.text)
          onDismissed: root.closeEditor()
        }

        Text {
          width: parent.width
          text: qsTr("Comma-separated Yahoo symbols, up to six. The first (or the row you tap) owns the chart. Enter to set, Esc to cancel.")
          color: Theme.faint
          font.family: Theme.font
          font.pixelSize: 10 * root.s
          wrapMode: Text.WordWrap
        }
      }
    }
  }
}
