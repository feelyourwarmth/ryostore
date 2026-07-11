pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// The quick-capture bar. Row 1: type a line (書 write / 了 task) and send it.
// Row 2: the NOTE/TASK toggle and the target chip that governs where everything
// lands (the inbox, or today's daily note). Row 3: two clearly-labelled media
// captures — PASTE IMAGE (from the clipboard) and VOICE MEMO — so their purpose
// a guess. Every action reports back through the service's status line.
Item {
    id: root

    property real s: 1
    property real w: 320
    property var service: null
    property color accent: Theme.verm
    property var openPicker: null

    property bool taskMode: false
    property bool fieldFocused: false
    readonly property bool editing: fieldFocused
    readonly property bool recording: service ? service.recording : false
    property string target: ""
    readonly property string defaultTarget: service ? service.inbox : ""
    // a one-off retarget (from a workflow block or the picker) differs from the
    // configured default; show a reset affordance and snap back after each send.
    readonly property bool retargeted: target !== defaultTarget

    implicitWidth: w
    implicitHeight: col.implicitHeight

    function focusField() {
        root.fieldFocused = true;
        Qt.callLater(() => field.input.forceActiveFocus());
    }
    function commit() {
        var t = field.text.trim();
        if (t.length === 0 || !root.service)
            return;
        root.service.appendNote(root.target, t, root.taskMode);
        field.text = "";
        // the retarget was for this send only; snap back to the default inbox.
        root.target = root.defaultTarget;
    }
    // a short attention flash on the capture bar, so presetting it from a
    // workflow block reads as "type here" instead of a silent focus jump.
    property real pulseT: 0
    SequentialAnimation {
        id: pulseAnim
        NumberAnimation { target: root; property: "pulseT"; from: 0; to: 1; duration: Motion.fast; easing.type: Motion.easeStandard }
        NumberAnimation { target: root; property: "pulseT"; from: 1; to: 0; duration: Motion.fast; easing.type: Motion.easeStandard }
        NumberAnimation { target: root; property: "pulseT"; from: 0; to: 1; duration: Motion.fast; easing.type: Motion.easeStandard }
        NumberAnimation { target: root; property: "pulseT"; from: 1; to: 0; duration: Motion.fast; easing.type: Motion.easeStandard }
    }
    function pulse() { pulseAnim.restart(); }
    function captureTo(note, asTask) {
        root.target = note;
        root.taskMode = asTask;
        root.focusField();
        root.pulse();
    }
    Component.onCompleted: if (root.service) root.target = root.service.inbox;

    Column {
        id: col
        width: root.w
        spacing: 8 * root.s

        // ── row 1: text field ─────────────────────────────────────────────────────
        Item {
            width: parent.width
            height: 32 * root.s
            MouseArea { anchors.fill: parent; onClicked: root.focusField() }
            SearchField {
                id: field
                anchors.left: parent.left
                anchors.right: sendBtn.left
                anchors.rightMargin: 8 * root.s
                anchors.verticalCenter: parent.verticalCenter
                s: root.s
                kanji: root.taskMode ? "\u4e86" : "\u66f8"
                placeholder: {
                    var where = root.target.length === 0 ? qsTr("today") : root.target.replace(/\.md$/, "").split("/").pop();
                    return root.taskMode ? qsTr("New task → %1").arg(where) : qsTr("Quick note → %1").arg(where);
                }
                onAccepted: root.commit()
                onDismissed: field.input.focus = false
                Connections {
                    target: field.input
                    function onActiveFocusChanged() { root.fieldFocused = field.input.activeFocus; }
                }
            }
            Rectangle {
                id: sendBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 30 * root.s
                height: 30 * root.s
                radius: 0
                antialiasing: false
                color: sendMa.containsMouse ? root.accent : "transparent"
                border.width: 1
                border.color: field.text.length > 0 ? root.accent : Theme.hair
                Behavior on color { ColorAnimation { duration: Motion.fast } }
                GlyphIcon {
                    anchors.centerIn: parent
                    width: 15 * root.s; height: 15 * root.s
                    name: "send"
                    color: sendMa.containsMouse ? Theme.cardBot : (field.text.length > 0 ? root.accent : Theme.iconDim)
                    stroke: 1.8
                }
                MouseArea { id: sendMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.commit() }
            }
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 1
                color: root.fieldFocused ? root.accent : Theme.lineStrong
                Behavior on color { ColorAnimation { duration: Motion.fast } }
            }
            // pulse: a brief accent flash of the field's tick, driven by pulse().
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 2 * root.s
                color: root.accent
                opacity: root.pulseT
            }
        }

        // ── row 2: note/task toggle + target ──────────────────────────────────────
        Row {
            width: parent.width
            spacing: 7 * root.s
            Rectangle {
                id: toggle
                width: 106 * root.s
                height: 26 * root.s
                radius: 0
                antialiasing: false
                color: "transparent"
                border.width: 1
                border.color: Theme.lineStrong
                Rectangle {
                    width: toggle.width / 2
                    height: toggle.height
                    x: root.taskMode ? toggle.width / 2 : 0
                    radius: 0
                    antialiasing: false
                    color: root.accent
                    Behavior on x { NumberAnimation { duration: Motion.fast; easing.type: Motion.easeStandard } }
                }
                Row {
                    anchors.fill: parent
                    Repeater {
                        model: [{ t: qsTr("Note"), task: false }, { t: qsTr("Task"), task: true }]
                        delegate: Item {
                            id: seg
                            required property var modelData
                            width: toggle.width / 2
                            height: toggle.height
                            Text {
                                anchors.centerIn: parent
                                text: seg.modelData.t
                                color: (root.taskMode === seg.modelData.task) ? Theme.cardBot : Theme.subtle
                                font.family: Theme.mono
                                font.pixelSize: 10 * root.s
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.4 * root.s
                                font.capitalization: Font.AllUppercase
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.taskMode = seg.modelData.task }
                        }
                    }
                }
            }
            Rectangle {
                id: targetChip
                width: root.w - 106 * root.s - 7 * root.s
                height: 26 * root.s
                radius: 0
                antialiasing: false
                color: tgtMa.containsMouse ? Qt.alpha(root.accent, 0.12) : "transparent"
                border.width: 1
                border.color: tgtMa.containsMouse ? Qt.alpha(root.accent, 0.55) : Theme.hair
                Behavior on color { ColorAnimation { duration: Motion.fast } }
                // full-chip picker; declared first so the reset-x sits on top of it.
                MouseArea {
                    id: tgtMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.openPicker) root.openPicker(rel => { root.target = rel; });
                }
                Row {
                    anchors.left: parent.left; anchors.leftMargin: 8 * root.s
                    anchors.right: parent.right; anchors.rightMargin: 8 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6 * root.s
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "→"; color: root.accent; font.family: Theme.mono; font.pixelSize: 12 * root.s; font.weight: Font.Bold }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: targetChip.width - 34 * root.s - (root.retargeted ? 20 * root.s : 0)
                        elide: Text.ElideMiddle
                        text: root.target.length === 0 ? qsTr("today's note") : root.target.replace(/\.md$/, "").split("/").pop()
                        color: Theme.subtle; font.family: Theme.mono; font.pixelSize: 10.5 * root.s
                    }
                }
                // reset a one-off retarget back to the default inbox, without sending.
                Rectangle {
                    id: resetX
                    anchors.right: parent.right; anchors.rightMargin: 4 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18 * root.s; height: 18 * root.s
                    radius: 0; antialiasing: false
                    visible: root.retargeted
                    color: rxMa.containsMouse ? Qt.alpha(root.accent, 0.28) : "transparent"
                    GlyphIcon { anchors.centerIn: parent; width: 9 * root.s; height: 9 * root.s; name: "close"; color: rxMa.containsMouse ? root.accent : Theme.iconDim; stroke: 2 }
                    MouseArea { id: rxMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.target = root.defaultTarget }
                }
            }
        }

        // ── row 3: labelled media captures ────────────────────────────────────────
        Row {
            width: parent.width
            spacing: 7 * root.s
            component MediaBtn: Rectangle {
                id: mb
                property string glyph: ""
                property string label: ""
                property bool lit: false
                property bool missing: false
                property string need: ""
                property real blink: 1
                signal tapped()
                width: (root.w - 7 * root.s) / 2
                // grow both keys uniformly when either tool is missing, so the row
                // stays aligned and the missing one has room for its reason.
                height: (root.service && (!root.service.hasWlPaste || !root.service.hasFfmpeg) ? 40 : 30) * root.s
                radius: 0
                antialiasing: false
                opacity: mb.missing ? 0.5 : (mb.lit ? mb.blink : 1)
                color: mb.lit ? root.accent : (mbMa.containsMouse && !mb.missing ? Qt.alpha(root.accent, 0.14) : Qt.rgba(1, 1, 1, 0.02))
                border.width: 1
                border.color: mb.lit ? root.accent : Theme.hair
                Behavior on color { ColorAnimation { duration: Motion.fast } }
                Column {
                    anchors.centerIn: parent
                    spacing: 2 * root.s
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8 * root.s
                        GlyphIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 15 * root.s; height: 15 * root.s
                            name: mb.glyph
                            color: mb.lit ? Theme.cardBot : root.accent
                            stroke: 1.7
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: mb.label
                            color: mb.lit ? Theme.cardBot : Theme.cream
                            font.family: Theme.mono; font.pixelSize: 10 * root.s
                            font.weight: Font.DemiBold; font.letterSpacing: 1.2 * root.s
                            font.capitalization: Font.AllUppercase
                        }
                    }
                    Text {
                        visible: mb.missing
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: mb.need
                        color: Theme.faint
                        font.family: Theme.mono; font.pixelSize: 8 * root.s; font.letterSpacing: 0.5 * root.s
                        font.capitalization: Font.AllUppercase
                    }
                }
                // blink the "lit" (recording) key via a bound property, so the dim /
                // hover opacity binding above is never clobbered by the animation.
                SequentialAnimation {
                    running: mb.lit
                    loops: Animation.Infinite
                    NumberAnimation { target: mb; property: "blink"; from: 1; to: 0.5; duration: 620; easing.type: Easing.InOutSine }
                    NumberAnimation { target: mb; property: "blink"; from: 0.5; to: 1; duration: 620; easing.type: Easing.InOutSine }
                }
                MouseArea { id: mbMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: mb.tapped() }
            }
            MediaBtn {
                glyph: "clipboard"; label: qsTr("Paste image")
                missing: !!(root.service && !root.service.hasWlPaste)
                need: qsTr("needs wl-clipboard")
                onTapped: {
                    if (!root.service) return;
                    if (root.service.hasWlPaste) root.service.pasteImage(root.target);
                    else root.service.flash(qsTr("Paste image needs wl-clipboard"));
                }
            }
            MediaBtn {
                glyph: root.recording ? "stop" : "mic"
                label: root.recording ? qsTr("Stop") : qsTr("Voice memo")
                lit: root.recording
                missing: !!(root.service && !root.service.hasFfmpeg && !root.recording)
                need: qsTr("needs ffmpeg")
                onTapped: {
                    if (!root.service) return;
                    if (root.service.hasFfmpeg) root.service.toggleRecord(root.target);
                    else root.service.flash(qsTr("Voice memo needs ffmpeg"));
                }
            }
        }
    }
}
