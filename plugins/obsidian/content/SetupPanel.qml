pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// The opt-in gate as a specimen sheet: the 黒 seal, a 力 OBSIDIAN eyebrow, a
// Fraunces masthead, then the detection state — a quiet SCANNING line, a nudge
// to install, or the vaults Obsidian already knows as sharp ledger rows.
// Choosing one persists it and the tile becomes the main face.
Item {
    id: root

    property real s: 1
    property real w: 320
    property var service: null
    property color accent: Theme.verm

    readonly property string phase: service ? service.phase : "loading"

    implicitWidth: panel.implicitWidth
    implicitHeight: panel.implicitHeight

    Process { id: dlProc }

    Panel {
        id: panel
        w: root.w
        s: root.s
        surface: Theme.cardTop

        // ── masthead ──────────────────────────────────────────────────────────────
        Item {
            width: parent.width
            height: 42 * root.s

            ObsidianMark {
                id: seal
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 40 * root.s; height: 40 * root.s
                color: root.accent
                glow: root.phase === "loading"
            }
            Column {
                anchors.left: seal.right
                anchors.leftMargin: 13 * root.s
                anchors.right: reg.left
                anchors.rightMargin: 10 * root.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4 * root.s
                Eyebrow { text: qsTr("Obsidian"); mark: true; s: root.s; tick: root.accent }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.phase === "loading" ? qsTr("Scanning")
                        : root.phase === "notInstalled" ? qsTr("Not found")
                        : qsTr("Pick a vault")
                    color: Theme.bright
                    font.family: Theme.display
                    font.pixelSize: 23 * root.s
                    font.weight: Font.Medium
                }
            }
            // registration crosshair — poster chrome.
            Item {
                id: reg
                anchors.right: parent.right
                anchors.top: parent.top
                width: 13 * root.s; height: 13 * root.s
                Rectangle { anchors.centerIn: parent; width: parent.width; height: parent.height; radius: width / 2; color: "transparent"; border.width: 1; border.color: Theme.faint }
                Rectangle { anchors.centerIn: parent; width: 1; height: parent.height + 5 * root.s; color: Theme.faint }
                Rectangle { anchors.centerIn: parent; width: parent.width + 5 * root.s; height: 1; color: Theme.faint }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.hair }

        // ── not installed ───────────────────────────────────────────────────────
        Text {
            visible: root.phase === "notInstalled"
            width: parent.width
            wrapMode: Text.WordWrap
            text: qsTr("This widget writes into your own Obsidian vault, on disk. Install Obsidian, open a vault once, then re-check.")
            color: Theme.subtle
            font.family: Theme.font
            font.pixelSize: 12 * root.s
            lineHeight: 1.3
        }

        // ── vault chooser ───────────────────────────────────────────────────────
        Eyebrow {
            visible: root.phase === "noVault" && root.service && root.service.vaults.length > 0
            text: qsTr("Your vaults"); s: root.s; tick: root.accent
        }
        Column {
            width: parent.width
            spacing: 7 * root.s
            visible: root.phase === "noVault"

            Repeater {
                model: (root.phase === "noVault" && root.service) ? root.service.vaults : []
                delegate: Rectangle {
                    id: vrow
                    required property int index
                    required property var modelData
                    width: parent.width
                    height: 46 * root.s
                    radius: 0
                    antialiasing: false
                    color: vma.containsMouse ? Qt.alpha(root.accent, 0.1) : Qt.rgba(1, 1, 1, 0.02)
                    border.width: 1
                    border.color: vma.containsMouse ? Qt.alpha(root.accent, 0.55) : Theme.hair

                    Rectangle {
                        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                        width: 3 * root.s
                        color: root.accent
                        visible: vma.containsMouse
                    }
                    Text {
                        id: vnum
                        anchors.left: parent.left; anchors.leftMargin: 13 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        text: (vrow.index + 1).toString().padStart(2, "0")
                        color: root.accent
                        font.family: Theme.mono; font.pixelSize: 12 * root.s; font.weight: Font.Bold
                    }
                    Column {
                        anchors.left: vnum.right; anchors.leftMargin: 13 * root.s
                        anchors.right: parent.right; anchors.rightMargin: 12 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2 * root.s
                        Text {
                            width: parent.width; elide: Text.ElideRight
                            text: vrow.modelData.name
                            color: Theme.cream; font.family: Theme.font; font.pixelSize: 14 * root.s; font.weight: Font.Medium
                        }
                        Text {
                            width: parent.width; elide: Text.ElideMiddle
                            text: vrow.modelData.path
                            color: Theme.faint; font.family: Theme.mono; font.pixelSize: 9.5 * root.s
                        }
                    }
                    MouseArea {
                        id: vma
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.service) root.service.setVault(vrow.modelData.path)
                    }
                }
            }

            Text {
                visible: root.service && root.service.vaults.length === 0
                width: parent.width
                wrapMode: Text.WordWrap
                text: qsTr("No vaults registered yet. Open a vault in Obsidian once, then re-check.")
                color: Theme.subtle
                font.family: Theme.font
                font.pixelSize: 12 * root.s
                lineHeight: 1.3
            }
        }

        // ── actions ────────────────────────────────────────────────────────────────
        Row {
            width: parent.width
            spacing: 8 * root.s
            visible: root.phase !== "loading"

            component FlatBtn: Rectangle {
                id: fb
                property string label: ""
                property string glyph: ""
                property bool filled: false
                signal tapped()
                height: 34 * root.s
                radius: 0
                antialiasing: false
                color: fb.filled ? (fbMa.containsMouse ? Qt.lighter(root.accent, 1.12) : root.accent)
                    : (fbMa.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent")
                border.width: 1
                border.color: fb.filled ? root.accent : Theme.lineStrong
                Behavior on color { ColorAnimation { duration: Motion.fast } }
                Row {
                    anchors.centerIn: parent
                    spacing: 7 * root.s
                    GlyphIcon {
                        visible: fb.glyph.length > 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: 13 * root.s; height: 13 * root.s
                        name: fb.glyph
                        color: fb.filled ? Theme.cardBot : Theme.subtle
                        stroke: 1.8
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: fb.label
                        color: fb.filled ? Theme.cardBot : Theme.subtle
                        font.family: Theme.mono; font.pixelSize: 11 * root.s
                        font.weight: Font.DemiBold; font.letterSpacing: 1.5 * root.s
                        font.capitalization: Font.AllUppercase
                    }
                }
                MouseArea { id: fbMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: fb.tapped() }
            }

            FlatBtn {
                visible: root.phase === "notInstalled" || root.phase === "noVault"
                width: (parent.width - 8 * root.s) / 2
                label: root.phase === "notInstalled" ? qsTr("Get it") : qsTr("Browse folder")
                glyph: root.phase === "notInstalled" ? "" : "folder"
                filled: true
                onTapped: {
                    if (root.phase === "notInstalled") {
                        dlProc.command = ["xdg-open", "https://obsidian.md/download"];
                        dlProc.running = true;
                    } else if (root.service) {
                        root.service.browseVault();
                    }
                }
            }
            FlatBtn {
                width: (root.phase === "notInstalled" || root.phase === "noVault") ? (parent.width - 8 * root.s) / 2 : parent.width
                label: qsTr("Re-check"); glyph: "reboot"
                onTapped: if (root.service) root.service.redetect()
            }
        }
    }
}
