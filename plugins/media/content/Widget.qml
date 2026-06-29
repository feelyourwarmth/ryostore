pragma ComponentBehavior: Bound

import QtQuick

// The `content` entry point for the `media` plugin: a thin selector that
// resolves the configured `design` into one of seven face components and lets
// it own the surface. The host sets `pluginApi`, `density`, `s`, `widthBudget`,
// `active`; the service (pluginApi.mainInstance) holds all state. Faces never
// touch the host; they only read root.service. The host's `active` is hard-
// wired true and is ignored here - per-face RAM gating uses `service.playing`.
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
      case "dossier":  return dossierComp;
      case "minimal":  return minimalComp;
      case "poster":   return posterComp;
      case "vinyl":    return vinylComp;
      case "cassette": return cassetteComp;
      case "loop":     return loopComp;
      case "spectrum": return spectrumComp;
      default:         return dossierComp;
    }
  }

  Component { id: dossierComp;  MediaDossier  { service: root.service; s: root.s; cw: root.contentW } }
  Component { id: minimalComp;  MediaMinimal  { service: root.service; s: root.s; cw: root.contentW } }
  Component { id: posterComp;   MediaPoster   { service: root.service; s: root.s; cw: root.contentW } }
  Component { id: vinylComp;    MediaVinyl    { service: root.service; s: root.s; cw: root.contentW } }
  Component { id: cassetteComp; MediaCassette { service: root.service; s: root.s; cw: root.contentW } }
  Component { id: loopComp;     MediaLoop     { service: root.service; s: root.s; cw: root.contentW } }
  Component { id: spectrumComp; MediaSpectrum { service: root.service; s: root.s; cw: root.contentW } }
}
