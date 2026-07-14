pragma ComponentBehavior: Bound

import QtQuick

/**
 * The `content` entry point: a thin selector that resolves the configured
 * `design` into one of three Stargate faces. The host sets `pluginApi`,
 * `density`, `s`, `widthBudget`, `active`; the service (pluginApi.mainInstance)
 * owns all state - the clock, the address it encodes, and the dial choreography -
 * so the faces only read and render, never drive. Each face reports its own
 * implicitHeight, which this view forwards so the host can size the tile.
 */
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
    implicitHeight: faceLoader.item ? faceLoader.item.implicitHeight : contentW

    Loader {
        id: faceLoader
        width: root.contentW
        sourceComponent: root.faceFor(root.service ? root.service.design : "naquadah")
    }

    // design string -> the matching face component. Unknown values fall back to
    // the cinematic gate so a typo never blanks the tile.
    function faceFor(dsn) {
        switch (dsn) {
            case "hologram": return holoComp;
            case "dossier":  return dossierComp;
            default:         return naquadahComp;
        }
    }

    Component { id: naquadahComp; FaceNaquadah { service: root.service; s: root.s; cw: root.contentW; active: root.active } }
    Component { id: holoComp;     FaceHologram { service: root.service; s: root.s; cw: root.contentW; active: root.active } }
    Component { id: dossierComp;  FaceDossier  { service: root.service; s: root.s; cw: root.contentW; active: root.active } }
}
