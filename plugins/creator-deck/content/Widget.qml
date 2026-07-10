pragma ComponentBehavior: Bound
import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// Creator Deck: the left-sidebar creator cockpit. Broadcast + edit launchers, an
// aspect target that drives the reformat scripts, one-tap reformat/caption of
// the last recording, mic + FX toggles, disk headroom, and a recents list that
// reveals in the file manager. All state and actions come from the service
// (pluginApi.mainInstance -> ryoku-creator-deck).
Item {
    id: root

    property var pluginApi
    property var screen
    property bool active
    property string density: "full"
    property real s: 1
    property real widthBudget: 0

    readonly property var svc: pluginApi ? pluginApi.mainInstance : null
    readonly property real contentW: widthBudget > 0 ? widthBudget : 300 * s
    readonly property string aspect: svc ? svc.aspect : "9:16"

    implicitWidth: contentW
    implicitHeight: col.implicitHeight

    // poll only while the pane is open and on screen.
    onActiveChanged: if (active && svc) svc.refresh()
    Timer {
        running: root.active
        interval: 5000
        repeat: true
        triggeredOnStart: true
        onTriggered: if (root.svc) root.svc.refresh()
    }

    // a square glyph tile with a caption under it (Broadcast / Edit / Mic / FX).
    component Tile: Rectangle {
        id: tile
        property string glyph: ""
        property string caption: ""
        property color tint: Theme.iconDim
        property bool lit: false
        signal act
        width: (root.contentW - 12 * root.s) / 2
        implicitHeight: 60 * root.s
        radius: Motion.rSmall * root.s
        color: thov.containsMouse ? Theme.frameBg : Theme.tileBg
        border.width: 1
        border.color: tile.lit ? Theme.brand : Theme.border
        Behavior on color { ColorAnimation { duration: Motion.fast } }
        Behavior on border.color { ColorAnimation { duration: Motion.fast } }
        Column {
            anchors.centerIn: parent
            spacing: 6 * root.s
            GlyphIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 20 * root.s
                height: 20 * root.s
                name: tile.glyph
                color: tile.lit ? Theme.brand : (thov.containsMouse ? Theme.cream : tile.tint)
                stroke: 1.8
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tile.caption
                color: tile.lit ? Theme.brand : Theme.subtle
                font.family: Theme.mono
                font.pixelSize: 9.5 * root.s
                font.weight: Font.DemiBold
                font.letterSpacing: 0.6 * root.s
            }
        }
        MouseArea {
            id: thov
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.act()
        }
    }

    // a full-width action row: glyph + label, lights on hover.
    component ActionRow: Rectangle {
        id: ar
        property string glyph: ""
        property string label: ""
        signal act
        width: root.contentW
        implicitHeight: 38 * root.s
        radius: Motion.rSmall * root.s
        color: ahov.containsMouse ? Theme.frameBg : Theme.tileBg
        border.width: 1
        border.color: Theme.border
        Behavior on color { ColorAnimation { duration: Motion.fast } }
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 12 * root.s
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10 * root.s
            GlyphIcon {
                anchors.verticalCenter: parent.verticalCenter
                width: 16 * root.s
                height: 16 * root.s
                name: ar.glyph
                color: ahov.containsMouse ? Theme.brand : Theme.iconDim
                stroke: 1.7
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ar.label
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 12.5 * root.s
            }
        }
        MouseArea {
            id: ahov
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ar.act()
        }
    }

    // an aspect chip: 9:16 / 1:1 / 16:9, lit when it is the current target.
    component Chip: Rectangle {
        id: chip
        property string value: ""
        readonly property bool on: root.aspect === chip.value
        width: (root.contentW - 16 * root.s) / 3
        implicitHeight: 30 * root.s
        radius: Motion.rSmall * root.s
        color: chip.on ? Theme.brand : (chov.containsMouse ? Theme.frameBg : Theme.tileBg)
        border.width: 1
        border.color: chip.on ? Theme.brand : Theme.border
        Behavior on color { ColorAnimation { duration: Motion.fast } }
        Text {
            anchors.centerIn: parent
            text: chip.value
            color: chip.on ? Theme.bright : Theme.subtle
            font.family: Theme.mono
            font.pixelSize: 11 * root.s
            font.weight: Font.DemiBold
        }
        MouseArea {
            id: chov
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (root.svc) root.svc.run(["aspect", chip.value])
        }
    }

    Column {
        id: col
        width: root.contentW
        spacing: 14 * root.s

        // ── broadcast ──────────────────────────────────────────────────────
        MicroLabel { label: qsTr("Broadcast"); s: root.s }
        Row {
            spacing: 12 * root.s
            Tile {
                glyph: "send"; caption: qsTr("GO LIVE"); tint: Theme.brand; lit: true
                onAct: if (root.svc) root.svc.run(["golive"])
            }
            Tile {
                glyph: "film"; caption: qsTr("EDIT")
                onAct: if (root.svc) root.svc.run(["edit"])
            }
        }

        // ── aspect target ──────────────────────────────────────────────────
        MicroLabel { label: qsTr("Aspect target"); s: root.s }
        Row {
            spacing: 8 * root.s
            Chip { value: "9:16" }
            Chip { value: "1:1" }
            Chip { value: "16:9" }
        }
        ActionRow {
            glyph: "remux"; label: qsTr("Reformat last recording")
            onAct: if (root.svc) root.svc.run(["reformat-last"])
        }
        ActionRow {
            glyph: "text"; label: qsTr("Caption last recording")
            onAct: if (root.svc) root.svc.run(["caption-last"])
        }

        // ── audio ──────────────────────────────────────────────────────────
        MicroLabel { label: qsTr("Audio"); s: root.s }
        Row {
            spacing: 12 * root.s
            Tile {
                glyph: (root.svc && root.svc.micMuted) ? "mic-off" : "mic"
                caption: (root.svc && root.svc.micMuted) ? qsTr("MUTED") : qsTr("MIC LIVE")
                tint: (root.svc && root.svc.micMuted) ? Theme.vermLit : Theme.iconDim
                lit: root.svc ? root.svc.micMuted : false
                onAct: if (root.svc) root.svc.run(["mic-toggle"])
            }
            Tile {
                glyph: "sparkle"; caption: qsTr("EFFECTS")
                onAct: if (root.svc) root.svc.run(["fx-toggle"])
            }
        }

        // ── disk headroom ──────────────────────────────────────────────────
        Row {
            spacing: 8 * root.s
            GlyphIcon {
                anchors.verticalCenter: parent.verticalCenter
                width: 14 * root.s; height: 14 * root.s
                name: "archive"; color: Theme.iconDim; stroke: 1.7
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Free for recordings: %1").arg(root.svc ? root.svc.disk : "")
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 11 * root.s
            }
        }

        // ── recent ─────────────────────────────────────────────────────────
        MicroLabel { label: qsTr("Recent"); s: root.s }
        Text {
            visible: !root.svc || !root.svc.recent || root.svc.recent.length === 0
            width: root.contentW
            text: qsTr("Nothing recorded yet.")
            color: Theme.faint
            font.family: Theme.font
            font.pixelSize: 11 * root.s
        }
        Column {
            width: root.contentW
            spacing: 4 * root.s
            Repeater {
                model: root.svc ? root.svc.recent : []
                delegate: Rectangle {
                    id: rec
                    required property var modelData
                    width: root.contentW
                    implicitHeight: 30 * root.s
                    radius: Motion.rSmall * root.s
                    color: rhov.containsMouse ? Theme.frameBg : "transparent"
                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 8 * root.s
                        anchors.right: parent.right
                        anchors.rightMargin: 8 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 9 * root.s
                        GlyphIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14 * root.s; height: 14 * root.s
                            name: "film"; color: Theme.iconDim; stroke: 1.6
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 24 * root.s
                            text: rec.modelData.label
                            color: Theme.subtle
                            font.family: Theme.font
                            font.pixelSize: 11 * root.s
                            elide: Text.ElideRight
                        }
                    }
                    MouseArea {
                        id: rhov
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.svc) root.svc.run(["reveal", rec.modelData.path])
                    }
                }
            }
        }

        ActionRow {
            glyph: "folder"; label: qsTr("Open project folder")
            onAct: if (root.svc) root.svc.run(["open-project"])
        }
    }
}
