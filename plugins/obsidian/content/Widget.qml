pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// The `content` entry point: a phase dispatcher. Until Obsidian and a vault are
// resolved it shows SetupPanel; once configured it shows MainFace. The note
// picker and the block builder are morph-in overlays — the tile grows into them
// and back — so there are no scrims or nested layers on the wallpaper. Any
// focused text field raises `editing`, which the desktop host reads to grab the
// keyboard (the same path the market ticker editor uses).
Item {
    id: root

    property var pluginApi
    property var screen
    property bool active
    property string density: "compact"
    property real s: 1
    property real widthBudget: 0

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property color accent: service ? service.accentColor() : Theme.sun
    readonly property real contentW: widthBudget > 0 ? widthBudget : 340
    readonly property string phase: service ? service.phase : "loading"

    // overlay state — one at a time; each morphs the whole tile.
    property bool pickerActive: false
    property var pickerCb: null
    property bool editorActive: false
    property var editorExisting: null

    function openPicker(cb) { editorActive = false; pickerCb = cb; pickerActive = true; }
    function openEditor(b) { pickerActive = false; editorExisting = b || null; editorActive = true; }
    function closeOverlays() { pickerActive = false; editorActive = false; pickerCb = null; }

    // the host grabs the keyboard while any of our text fields holds focus.
    readonly property bool editing:
        (baseLoader.item && baseLoader.item.editing === true)
        || (pickerActive && pickerLoader.item && pickerLoader.item.editing === true)
        || (editorActive && editorLoader.item && editorLoader.item.editing === true)

    implicitWidth: {
        if (editorActive && editorLoader.item)
            return editorLoader.item.implicitWidth;
        if (pickerActive && pickerLoader.item)
            return pickerLoader.item.implicitWidth;
        return baseLoader.item ? baseLoader.item.implicitWidth : contentW;
    }
    implicitHeight: {
        if (editorActive && editorLoader.item)
            return editorLoader.item.implicitHeight;
        if (pickerActive && pickerLoader.item)
            return pickerLoader.item.implicitHeight;
        return baseLoader.item ? baseLoader.item.implicitHeight : 140 * s;
    }

    // base — setup gate or the configured main face.
    Loader {
        id: baseLoader
        visible: !root.pickerActive && !root.editorActive
        sourceComponent: root.phase === "ready" ? mainComp : setupComp
    }
    Component {
        id: setupComp
        SetupPanel { w: root.contentW; s: root.s; service: root.service; accent: root.accent }
    }
    Component {
        id: mainComp
        MainFace {
            w: root.contentW; s: root.s; service: root.service; accent: root.accent
            openPicker: root.openPicker
            openEditor: root.openEditor
        }
    }

    // note picker — invoked by the capture bar to choose where capture lands.
    Loader {
        id: pickerLoader
        active: root.pickerActive
        visible: active
        sourceComponent: Panel {
            id: pk
            property bool editing: np.editing
            w: root.contentW
            s: root.s
            NotePicker {
                id: np
                width: parent.width
                s: root.s; service: root.service; accent: root.accent
                heading: qsTr("Send to")
                onPicked: (rel) => { if (root.pickerCb) root.pickerCb(rel); root.closeOverlays(); }
                onDismissed: root.closeOverlays()
            }
        }
    }

    // block builder — new or edit a workflow.
    Loader {
        id: editorLoader
        active: root.editorActive
        visible: active
        sourceComponent: BlockEditor {
            w: root.contentW
            s: root.s; service: root.service; accent: root.accent
            existing: root.editorExisting
            onSaved: (b) => {
                if (root.service) {
                    if (b.id && b.id.length > 0) root.service.updateWorkflow(b.id, b);
                    else root.service.addWorkflow(b);
                }
                root.closeOverlays();
            }
            onDismissed: root.closeOverlays()
        }
    }
}
