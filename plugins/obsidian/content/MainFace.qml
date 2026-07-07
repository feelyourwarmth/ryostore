pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// The configured tile as a specimen sheet: the 黒 seal and vault masthead, a
// WORKFLOWS spine (Today is always first), and a CAPTURE bar. Blocks run on tap;
// append-text/task blocks preset the capture bar. The edit toggle reveals
// reorder/delete on the user's own blocks. Sharp, hairline, editorial.
Item {
    id: root

    property real s: 1
    property real w: 320
    property var service: null
    property color accent: Theme.verm
    property var openPicker: null      // openPicker(cb)
    property var openEditor: null      // openEditor(blockOrNull)

    property bool editMode: false
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
        case "screenshot": return qsTr("shot → %1").arg(targetLabel(b.note));
        case "audio":      return qsTr("voice → %1").arg(targetLabel(b.note));
        }
        return "";
    }
    function activate(b) {
        if (!root.service) return;
        if (b.action === "appendText" || b.action === "appendTask")
            capture.captureTo(b.note || "", b.action === "appendTask");
        else
            root.service.run(b);
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
                anchors.right: editBtn.left
                anchors.rightMargin: 10 * root.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3 * root.s
                Eyebrow {
                    text: root.service && root.service.recording ? qsTr("Recording") : qsTr("Obsidian")
                    mark: true
                    s: root.s
                    tick: root.accent
                }
                Text {
                    width: parent.width; elide: Text.ElideRight
                    text: root.service && root.service.vaultName.length > 0 ? root.service.vaultName : qsTr("Vault")
                    color: Theme.bright
                    font.family: Theme.display
                    font.pixelSize: 22 * root.s
                    font.weight: Font.Medium
                }
            }
            Rectangle {
                id: editBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 30 * root.s; height: 30 * root.s
                radius: 0
                antialiasing: false
                visible: root.workflows.length > 0
                color: root.editMode ? root.accent : (ebMa.containsMouse ? Qt.alpha(root.accent, 0.18) : Qt.rgba(0, 0, 0, 0.26))
                border.width: 1
                border.color: root.editMode ? root.accent : Theme.hair
                Behavior on color { ColorAnimation { duration: Motion.fast } }
                GlyphIcon {
                    anchors.centerIn: parent
                    width: 15 * root.s; height: 15 * root.s
                    name: root.editMode ? "check" : "list"
                    color: root.editMode ? Theme.cardBot : (ebMa.containsMouse ? root.accent : Theme.iconDim)
                    stroke: 1.8
                }
                MouseArea { id: ebMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.editMode = !root.editMode }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.hair }

        // ── workflows ───────────────────────────────────────────────────────────
        Eyebrow { text: qsTr("Workflows"); s: root.s; tick: root.accent }

        Column {
            width: parent.width
            spacing: root.gap

            WorkflowBlock {
                w: parent.width
                s: root.s
                gap: root.gap
                accent: root.accent
                icon: "sun"
                label: qsTr("Today")
                sub: qsTr("today · new or open")
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
                    w: parent.width
                    s: root.s
                    gap: root.gap
                    accent: root.accent
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
                    onActivated: root.activate(wb.modelData)
                    onEditRequested: if (root.openEditor) root.openEditor(wb.modelData)
                    onRemoveRequested: if (root.service) root.service.removeWorkflow(wb.modelData.id)
                    onMoveUp: if (root.service) root.service.moveWorkflow(wb.modelData.id, -1)
                    onMoveDown: if (root.service) root.service.moveWorkflow(wb.modelData.id, 1)
                }
            }
        }

        // ── capture ─────────────────────────────────────────────────────────────
        Eyebrow { text: qsTr("Capture"); s: root.s; tick: root.accent }

        QuickCapture {
            id: capture
            w: parent.width
            s: root.s
            service: root.service
            accent: root.accent
            openPicker: root.openPicker
        }

        // ── new workflow ──────────────────────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: 34 * root.s
            radius: 0
            antialiasing: false
            color: newMa.containsMouse ? Qt.alpha(root.accent, 0.14) : "transparent"
            border.width: 1
            border.color: newMa.containsMouse ? Qt.alpha(root.accent, 0.55) : Theme.lineStrong
            Behavior on color { ColorAnimation { duration: Motion.fast } }
            Row {
                anchors.centerIn: parent
                spacing: 8 * root.s
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "+"
                    color: root.accent
                    font.family: Theme.mono; font.pixelSize: 15 * root.s; font.weight: Font.Bold
                }
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
}
