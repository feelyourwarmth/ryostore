pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// The step-by-step workflow builder, as a specimen form: pick an ACTION, its
// TARGET note, a TEMPLATE (for note-opening actions), and a LABEL. Sharp chips,
// hairline borders, one accent. Target picking reuses NotePicker inline, so the
// tile just grows; no nested overlays.
Panel {
    id: root

    property var service: null
    property color accent: Theme.verm
    property var existing: null

    signal saved(var block)
    signal dismissed()

    property string draftAction: existing ? (existing.action || "daily") : "daily"
    property string draftNote: existing ? (existing.note || "") : ""
    property string draftTemplate: existing ? (existing.template || "") : ""
    property bool choosing: false

    readonly property bool needsTarget: draftAction !== "daily"
    readonly property bool needsTemplate: draftAction === "open"
    readonly property bool editing: labelField.input.activeFocus
        || (pickLoader.item ? pickLoader.item.editing : false)

    function targetLabel() {
        return draftNote.length === 0 ? qsTr("today's note")
            : draftNote.replace(/\.md$/, "").split("/").pop();
    }
    function iconFor(a) {
        return a === "daily" ? "sun" : a === "open" ? "file" : a === "appendText" ? "text"
            : a === "appendTask" ? "check" : a === "pasteImage" ? "clipboard" : "mic";
    }
    function autoLabel() {
        switch (draftAction) {
        case "daily":      return qsTr("Today's note");
        case "open":       return draftNote.length ? targetLabel() : qsTr("Open note");
        case "appendText": return qsTr("Note → %1").arg(targetLabel());
        case "appendTask": return qsTr("Task → %1").arg(targetLabel());
        case "pasteImage": return qsTr("Paste image → %1").arg(targetLabel());
        case "audio":      return qsTr("Voice memo → %1").arg(targetLabel());
        }
        return qsTr("Workflow");
    }
    function save() {
        var lbl = labelField.text.trim();
        root.saved({
            id: root.existing ? root.existing.id : "",
            action: root.draftAction,
            note: root.needsTarget ? root.draftNote : "",
            template: root.needsTemplate ? root.draftTemplate : "",
            icon: root.iconFor(root.draftAction),
            label: lbl.length > 0 ? lbl : root.autoLabel()
        });
    }

    // ── header ────────────────────────────────────────────────────────────────
    Item {
        width: parent.width
        height: 14 * root.s
        Eyebrow { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: root.existing ? qsTr("Edit workflow") : qsTr("New workflow"); mark: true; s: root.s; tick: root.accent }
        Rectangle {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            width: 24 * root.s; height: 24 * root.s
            radius: 0; antialiasing: false
            color: closeMa.containsMouse ? root.accent : "transparent"
            GlyphIcon { anchors.centerIn: parent; width: 12 * root.s; height: 12 * root.s; name: "close"; color: closeMa.containsMouse ? Theme.cardBot : Theme.iconDim; stroke: 2 }
            MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.dismissed() }
        }
    }

    // ── action ──────────────────────────────────────────────────────────────────
    Column {
        width: parent.width
        spacing: 8 * root.s
        Eyebrow { text: qsTr("Action"); s: root.s; tick: root.accent }
        Grid {
            width: parent.width
            columns: 2
            columnSpacing: 7 * root.s
            rowSpacing: 7 * root.s
            Repeater {
                model: [
                    { a: "daily", icon: "sun", t: qsTr("Today's note") },
                    { a: "open", icon: "file", t: qsTr("Open a note") },
                    { a: "appendText", icon: "text", t: qsTr("Add a note") },
                    { a: "appendTask", icon: "check", t: qsTr("Add a task") },
                    { a: "pasteImage", icon: "clipboard", t: qsTr("Paste image") },
                    { a: "audio", icon: "mic", t: qsTr("Voice memo") }
                ]
                delegate: Rectangle {
                    id: act
                    required property var modelData
                    readonly property bool on: root.draftAction === act.modelData.a
                    width: (parent.width - 7 * root.s) / 2
                    height: 38 * root.s
                    radius: 0
                    antialiasing: false
                    color: act.on ? root.accent : (actMa.containsMouse ? Qt.alpha(root.accent, 0.14) : Qt.rgba(1, 1, 1, 0.02))
                    border.width: 1
                    border.color: act.on ? root.accent : Theme.hair
                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                    Row {
                        anchors.left: parent.left; anchors.leftMargin: 10 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 9 * root.s
                        GlyphIcon { anchors.verticalCenter: parent.verticalCenter; width: 15 * root.s; height: 15 * root.s; name: act.modelData.icon; color: act.on ? Theme.cardBot : root.accent; stroke: 1.7 }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: act.modelData.t
                            color: act.on ? Theme.cardBot : Theme.cream
                            font.family: Theme.font; font.pixelSize: 12 * root.s; font.weight: Font.Medium
                        }
                    }
                    MouseArea { id: actMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.draftAction = act.modelData.a; root.choosing = false; } }
                }
            }
        }
    }

    // ── target ──────────────────────────────────────────────────────────────────
    Column {
        width: parent.width
        spacing: 8 * root.s
        visible: root.needsTarget
        Eyebrow { text: qsTr("Target"); s: root.s; tick: root.accent }
        Row {
            visible: !root.choosing
            width: parent.width
            spacing: 7 * root.s
            component TgtChip: Rectangle {
                id: tc
                property string glyph: ""
                property string txt: ""
                property bool on: false
                signal tapped()
                height: 30 * root.s
                radius: 0
                antialiasing: false
                width: tcRow.implicitWidth + 22 * root.s
                color: tc.on ? root.accent : (tcMa.containsMouse ? Qt.alpha(root.accent, 0.14) : Qt.rgba(1, 1, 1, 0.02))
                border.width: 1
                border.color: tc.on ? root.accent : Theme.hair
                Behavior on color { ColorAnimation { duration: Motion.fast } }
                Row {
                    id: tcRow
                    anchors.centerIn: parent
                    spacing: 7 * root.s
                    GlyphIcon { anchors.verticalCenter: parent.verticalCenter; width: 13 * root.s; height: 13 * root.s; name: tc.glyph; color: tc.on ? Theme.cardBot : root.accent; stroke: 1.7 }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: tc.txt; color: tc.on ? Theme.cardBot : Theme.cream; font.family: Theme.font; font.pixelSize: 12 * root.s; font.weight: Font.Medium }
                }
                MouseArea { id: tcMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tc.tapped() }
            }
            TgtChip { glyph: "sun"; txt: qsTr("Today"); on: root.draftNote.length === 0; onTapped: root.draftNote = "" }
            TgtChip { visible: root.draftNote.length > 0; glyph: "file"; txt: root.targetLabel(); on: true }
            TgtChip { glyph: "folder"; txt: qsTr("Choose"); onTapped: { root.choosing = true; if (root.service) root.service.refreshNotes(""); } }
        }
        Loader {
            id: pickLoader
            width: parent.width
            active: root.needsTarget && root.choosing
            visible: active
            sourceComponent: NotePicker {
                s: root.s
                service: root.service
                accent: root.accent
                heading: qsTr("Target note")
                onPicked: (rel) => { root.draftNote = rel; root.choosing = false; }
                onDismissed: root.choosing = false
            }
        }
    }

    // ── template ──────────────────────────────────────────────────────────────────
    Column {
        width: parent.width
        spacing: 8 * root.s
        visible: root.needsTemplate && root.service && root.service.templates.length > 0
        Eyebrow { text: qsTr("Template"); s: root.s; tick: root.accent }
        Flow {
            width: parent.width
            spacing: 7 * root.s
            component TplChip: Rectangle {
                id: pc
                property string val: ""
                property string txt: ""
                readonly property bool on: root.draftTemplate === pc.val
                height: 27 * root.s
                radius: 0
                antialiasing: false
                width: pcT.implicitWidth + 18 * root.s
                color: pc.on ? root.accent : (pcMa.containsMouse ? Qt.alpha(root.accent, 0.14) : Qt.rgba(1, 1, 1, 0.02))
                border.width: 1
                border.color: pc.on ? root.accent : Theme.hair
                Behavior on color { ColorAnimation { duration: Motion.fast } }
                Text { id: pcT; anchors.centerIn: parent; text: pc.txt; color: pc.on ? Theme.cardBot : Theme.subtle; font.family: Theme.mono; font.pixelSize: 10.5 * root.s; font.weight: Font.Medium }
                MouseArea { id: pcMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.draftTemplate = pc.val }
            }
            TplChip { val: ""; txt: qsTr("None") }
            Repeater {
                model: root.service ? root.service.templates : []
                delegate: TplChip {
                    required property var modelData
                    val: modelData
                    txt: modelData.split("/").pop()
                }
            }
        }
    }

    // daily uses the vault's own settings.
    Text {
        visible: root.draftAction === "daily"
        width: parent.width
        wrapMode: Text.WordWrap
        text: root.service && root.service.vaultInfo
            ? qsTr("Uses your daily-notes settings: %1").arg(
                (root.service.vaultInfo.daily.folder ? root.service.vaultInfo.daily.folder + "/" : "")
                + root.service.vaultInfo.daily.format
                + (root.service.vaultInfo.daily.template ? qsTr(" · %1").arg(root.service.vaultInfo.daily.template.split("/").pop()) : ""))
            : qsTr("Uses your Obsidian daily-notes settings.")
        color: Theme.faint; font.family: Theme.mono; font.pixelSize: 10 * root.s; lineHeight: 1.3
    }

    // ── label ────────────────────────────────────────────────────────────────────
    Column {
        width: parent.width
        spacing: 8 * root.s
        Eyebrow { text: qsTr("Label"); s: root.s; tick: root.accent }
        Item {
            width: parent.width
            height: 30 * root.s
            SearchField {
                id: labelField
                anchors.left: parent.left; anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                s: root.s
                kanji: "\u540d"
                placeholder: root.autoLabel()
                onDismissed: labelField.input.focus = false
                onAccepted: root.save()
            }
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 1
                color: labelField.input.activeFocus ? root.accent : Theme.lineStrong
                Behavior on color { ColorAnimation { duration: Motion.fast } }
            }
        }
    }

    // ── footer ────────────────────────────────────────────────────────────────────
    Row {
        width: parent.width
        spacing: 8 * root.s
        Rectangle {
            width: (parent.width - 8 * root.s) / 2
            height: 34 * root.s
            radius: 0; antialiasing: false
            color: cancelMa.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent"
            border.width: 1; border.color: Theme.lineStrong
            Text { anchors.centerIn: parent; text: qsTr("Cancel"); color: Theme.subtle; font.family: Theme.mono; font.pixelSize: 11 * root.s; font.weight: Font.DemiBold; font.letterSpacing: 1.5 * root.s; font.capitalization: Font.AllUppercase }
            MouseArea { id: cancelMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.dismissed() }
        }
        Rectangle {
            width: (parent.width - 8 * root.s) / 2
            height: 34 * root.s
            radius: 0; antialiasing: false
            color: saveMa.containsMouse ? Qt.lighter(root.accent, 1.12) : root.accent
            Behavior on color { ColorAnimation { duration: Motion.fast } }
            Text { anchors.centerIn: parent; text: root.existing ? qsTr("Save") : qsTr("Add"); color: Theme.cardBot; font.family: Theme.mono; font.pixelSize: 11 * root.s; font.weight: Font.Bold; font.letterSpacing: 1.5 * root.s; font.capitalization: Font.AllUppercase }
            MouseArea { id: saveMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.save() }
        }
    }
}
