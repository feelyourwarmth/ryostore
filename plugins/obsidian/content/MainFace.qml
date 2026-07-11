pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// The configured tile. A BOARD | GRAPH switch under the masthead: BOARD is the
// workflow spine + capture bar, GRAPH is the vault's link constellation. A live
// status line reports every action, so nothing silent ever feels broken. Blocks
// run on tap; append-text/task blocks preset the capture bar.
Item {
    id: root

    property real s: 1
    property real w: 320
    property var service: null
    property color accent: Theme.verm
    property var openPicker: null
    property var openEditor: null

    property bool editMode: false
    property string view: "board"
    readonly property bool editing: capture.editing
    readonly property var workflows: service ? service.workflowList : []
    readonly property real gap: 9 * s

    implicitWidth: panel.implicitWidth
    implicitHeight: panel.implicitHeight

    function targetLabel(note) {
        return (!note || note.length === 0) ? qsTr("today") : note.replace(/\.md$/, "").split("/").pop();
    }
    function subFor(b) {
        switch (b.action) {
        case "daily":      return qsTr("today · new or open");
        case "open":       return b.note && b.note.length ? b.note.replace(/\.md$/, "") : qsTr("open a note");
        case "appendText": return qsTr("note → %1").arg(targetLabel(b.note));
        case "appendTask": return qsTr("task → %1").arg(targetLabel(b.note));
        case "pasteImage": return qsTr("paste → %1").arg(targetLabel(b.note));
        case "audio":      return qsTr("voice → %1").arg(targetLabel(b.note));
        }
        return "";
    }
    function activate(b) {
        if (!root.service) return;
        // fail proactively, not at tap time, when the backing tool is absent.
        if (b.action === "pasteImage" && !root.service.hasWlPaste) {
            root.service.flash(qsTr("Paste image needs wl-clipboard"));
            return;
        }
        if (b.action === "audio" && !root.service.hasFfmpeg && !root.service.recording) {
            root.service.flash(qsTr("Voice memo needs ffmpeg"));
            return;
        }
        if (b.action === "appendText" || b.action === "appendTask")
            capture.captureTo(b.note || "", b.action === "appendTask");
        else
            root.service.run(b);
    }
    function setView(v) {
        root.view = v;
        if (v === "graph" && root.service) root.service.refreshGraph();
    }
    function fmtSecs(n) {
        var m = Math.floor(n / 60), sec = n % 60;
        return m + ":" + (sec < 10 ? "0" : "") + sec;
    }

    Panel {
        id: panel
        w: root.w
        s: root.s
        surface: Theme.cardTop

        // ── masthead ────────────────────────────────────────────────────────────
        Item {
            width: parent.width
            height: 40 * root.s

            ObsidianMark {
                id: seal
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 38 * root.s; height: 38 * root.s
                color: root.accent
            }
            Column {
                anchors.left: seal.right
                anchors.leftMargin: 13 * root.s
                anchors.right: switcher.left
                anchors.rightMargin: 10 * root.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3 * root.s
                Eyebrow {
                    text: root.service && root.service.recording
                        ? qsTr("Recording %1").arg(root.fmtSecs(root.service.recordSecs))
                        : qsTr("Obsidian")
                    mark: true; s: root.s; tick: root.accent
                }
                Text {
                    width: parent.width; elide: Text.ElideRight
                    text: root.service && root.service.vaultName.length > 0 ? root.service.vaultName : qsTr("Vault")
                    color: Theme.bright
                    font.family: Theme.display; font.pixelSize: 21 * root.s; font.weight: Font.Medium
                }
            }
            // BOARD | GRAPH switch.
            Rectangle {
                id: switcher
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 128 * root.s
                height: 27 * root.s
                radius: 0
                antialiasing: false
                color: "transparent"
                border.width: 1
                border.color: Theme.lineStrong
                Rectangle {
                    width: switcher.width / 2
                    height: switcher.height
                    x: root.view === "graph" ? switcher.width / 2 : 0
                    radius: 0; antialiasing: false
                    color: root.accent
                    Behavior on x { NumberAnimation { duration: Motion.fast; easing.type: Motion.easeStandard } }
                }
                Row {
                    anchors.fill: parent
                    Repeater {
                        model: [{ v: "board", t: qsTr("Board") }, { v: "graph", t: qsTr("Graph") }]
                        delegate: Item {
                            id: sw
                            required property var modelData
                            width: switcher.width / 2
                            height: switcher.height
                            Text {
                                anchors.centerIn: parent
                                text: sw.modelData.t
                                color: (root.view === sw.modelData.v) ? Theme.cardBot : Theme.subtle
                                font.family: Theme.mono; font.pixelSize: 10 * root.s
                                font.weight: Font.DemiBold; font.letterSpacing: 1.4 * root.s
                                font.capitalization: Font.AllUppercase
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.setView(sw.modelData.v) }
                        }
                    }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.hair }

        // ── board ─────────────────────────────────────────────────────────────────
        Column {
            width: parent.width
            spacing: 12 * root.s
            visible: root.view === "board"

            Item {
                width: parent.width
                height: 14 * root.s
                Eyebrow { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Workflows"); s: root.s; tick: root.accent }
                Rectangle {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    width: 26 * root.s; height: 20 * root.s
                    radius: 0; antialiasing: false
                    visible: root.workflows.length > 0
                    color: root.editMode ? root.accent : (ebMa.containsMouse ? Qt.alpha(root.accent, 0.18) : "transparent")
                    border.width: 1
                    border.color: root.editMode ? root.accent : Theme.hair
                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                    GlyphIcon {
                        anchors.centerIn: parent
                        width: 13 * root.s; height: 13 * root.s
                        name: root.editMode ? "check" : "list"
                        color: root.editMode ? Theme.cardBot : (ebMa.containsMouse ? root.accent : Theme.iconDim)
                        stroke: 1.8
                    }
                    MouseArea { id: ebMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.editMode = !root.editMode }
                }
            }

            Column {
                width: parent.width
                spacing: root.gap

                WorkflowBlock {
                    w: parent.width; s: root.s; gap: root.gap; accent: root.accent
                    icon: "sun"; label: qsTr("Today"); sub: qsTr("today · new or open")
                    removable: false
                    connectUp: false
                    connectDown: root.workflows.length > 0
                    onActivated: if (root.service) root.service.openDaily()
                }
                Repeater {
                    model: root.workflows
                    delegate: WorkflowBlock {
                        id: wb
                        required property int index
                        required property var modelData
                        w: parent.width; s: root.s; gap: root.gap; accent: root.accent
                        icon: modelData.icon || "file"
                        label: modelData.label || qsTr("Workflow")
                        sub: root.subFor(modelData)
                        editMode: root.editMode
                        canUp: index > 0
                        canDown: index < root.workflows.length - 1
                        running: root.service && root.service.recording
                            && modelData.action === "audio"
                            && (modelData.note || "") === (root.service.recordNote || "")
                        connectUp: true
                        connectDown: index < root.workflows.length - 1
                        disabled: !!(root.service
                            && ((modelData.action === "pasteImage" && !root.service.hasWlPaste)
                                || (modelData.action === "audio" && !root.service.hasFfmpeg)))
                        disabledSub: modelData.action === "pasteImage" ? qsTr("needs wl-clipboard") : qsTr("needs ffmpeg")
                        onActivated: root.activate(wb.modelData)
                        onEditRequested: if (root.openEditor) root.openEditor(wb.modelData)
                        onRemoveRequested: if (root.service) root.service.removeWorkflow(wb.modelData.id)
                        onMoveUp: if (root.service) root.service.moveWorkflow(wb.modelData.id, -1)
                        onMoveDown: if (root.service) root.service.moveWorkflow(wb.modelData.id, 1)
                        recSecs: root.service ? root.service.recordSecs : 0
                        onDiscardRequested: if (root.service) root.service.discardRecord()
                    }
                }
            }

            Eyebrow { text: qsTr("Capture"); s: root.s; tick: root.accent }

            QuickCapture {
                id: capture
                w: parent.width; s: root.s
                service: root.service
                accent: root.accent
                openPicker: root.openPicker
            }

            Rectangle {
                width: parent.width
                height: 34 * root.s
                radius: 0; antialiasing: false
                color: newMa.containsMouse ? Qt.alpha(root.accent, 0.14) : "transparent"
                border.width: 1
                border.color: newMa.containsMouse ? Qt.alpha(root.accent, 0.55) : Theme.lineStrong
                Behavior on color { ColorAnimation { duration: Motion.fast } }
                Row {
                    anchors.centerIn: parent
                    spacing: 8 * root.s
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "+"; color: root.accent; font.family: Theme.mono; font.pixelSize: 15 * root.s; font.weight: Font.Bold }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("New workflow")
                        color: newMa.containsMouse ? Theme.cream : Theme.subtle
                        font.family: Theme.mono; font.pixelSize: 11 * root.s
                        font.weight: Font.DemiBold; font.letterSpacing: 1.5 * root.s
                        font.capitalization: Font.AllUppercase
                    }
                }
                MouseArea { id: newMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (root.openEditor) root.openEditor(null) }
            }
        }

        // ── graph ─────────────────────────────────────────────────────────────────
        Loader {
            width: parent.width
            active: root.view === "graph"
            visible: active
            sourceComponent: GraphPanel {
                w: root.w - 30 * root.s
                s: root.s
                service: root.service
                accent: root.accent
            }
        }

        // ── status line ─────────────────────────────────────────────────────────────
        Item {
            id: statusBar
            width: parent.width
            height: 14 * root.s
            visible: statusRow.opacity > 0.01
            // slide + fade the confirmation in, led by a glyph, so a capture reads
            // as a distinct "landed" event rather than static text at the bottom.
            Row {
                id: statusRow
                spacing: 8 * root.s
                readonly property bool shown: !!(root.service && root.service.status.length > 0)
                opacity: shown ? 1 : 0
                x: shown ? 0 : -6 * root.s
                Behavior on opacity { NumberAnimation { duration: Motion.fast; easing.type: Motion.easeStandard } }
                Behavior on x { NumberAnimation { duration: Motion.fast; easing.type: Motion.easeStandard } }
                GlyphIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12 * root.s; height: 12 * root.s
                    name: "check"; color: root.accent; stroke: 2
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: statusBar.width - 20 * root.s
                    elide: Text.ElideRight
                    text: root.service ? root.service.status : ""
                    color: root.accent
                    font.family: Theme.mono; font.pixelSize: 10 * root.s; font.letterSpacing: 1 * root.s
                }
            }
        }
    }
}
