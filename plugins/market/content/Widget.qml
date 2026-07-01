pragma ComponentBehavior: Bound

import QtQuick

// The `content` entry point for the `market` plugin: a thin selector that
// resolves the configured `design` into one of four face components and lets it
// own the surface. The host sets `pluginApi`, `density`, `s`, `widthBudget`,
// `active`; the service (pluginApi.mainInstance) holds all state. Faces never
// touch the host; they only read root.service. Each face reports its own
// implicitHeight, which this view forwards so the host can size the tile.
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

  implicitWidth: contentW
  implicitHeight: faceLoader.item ? faceLoader.item.implicitHeight : 0

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
}
