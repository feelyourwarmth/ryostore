pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// The quick-capture bar: type a line and append it as a note or a task, drop a
// voice memo, or grab a screenshot — all into the chosen target (the inbox, or
// today's daily note when empty). An editorial underline input led by 書
// (write), a sharp NOTE/TASK toggle, and square capture keys. Typing raises the
// wallpaper layer's keyboard grab via `editing`. Links and wikilinks append
// verbatim.
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
    }
    function captureTo(note, asTask) {
        root.target = note;
        root.taskMode = asTask;
        root.focusField();
    }
    Component.onCompleted: if (root.service) root.target = root.service.inbox;

    Column {
        id: col
        width: root.w
        spacing: 10 * root.s

        // ── underline field ───────────────────────────────────────────────────────
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
                placeholder: root.taskMode ? qsTr("New task…") : qsTr("Quick note, link, thought…")
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
                height: 26 * root.s
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
                MouseArea {
                    id: sendMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.commit()
                }
            }

            // the editorial underline.
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: root.fieldFocused ? root.accent : Theme.lineStrong
                Behavior on color { ColorAnimation { duration: Motion.fast } }
            }
        }

        // ── toggle · target · mic · camera ────────────────────────────────────────
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
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.taskMode = seg.modelData.task
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: targetChip
                width: root.w - 106 * root.s - 26 * root.s * 2 - 7 * root.s * 3
                height: 26 * root.s
                radius: 0
                antialiasing: false
                color: tgtMa.containsMouse ? Qt.alpha(root.accent, 0.12) : "transparent"
                border.width: 1
                border.color: tgtMa.containsMouse ? Qt.alpha(root.accent, 0.55) : Theme.hair
                Behavior on color { ColorAnimation { duration: Motion.fast } }
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 8 * root.s
                    anchors.right: parent.right
                    anchors.rightMargin: 8 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5 * root.s
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "→"
                        color: root.accent
                        font.family: Theme.mono; font.pixelSize: 12 * root.s; font.weight: Font.Bold
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: targetChip.width - 32 * root.s
                        elide: Text.ElideMiddle
                        text: root.target.length === 0 ? qsTr("today") : root.target.replace(/\.md$/, "").split("/").pop()
                        color: Theme.subtle
                        font.family: Theme.mono; font.pixelSize: 10.5 * root.s
                    }
                }
                MouseArea {
                    id: tgtMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.openPicker) root.openPicker(rel => { root.target = rel; if (root.service) root.service.setInbox(rel); });
                }
            }

            component IconBtn: Rectangle {
                id: ib
                property string glyph: ""
                property bool lit: false
                signal tapped()
                width: 26 * root.s
                height: 26 * root.s
                radius: 0
                antialiasing: false
                color: ib.lit ? root.accent : (ibMa.containsMouse ? Qt.alpha(root.accent, 0.2) : "transparent")
                border.width: 1
                border.color: ib.lit ? root.accent : Theme.hair
                Behavior on color { ColorAnimation { duration: Motion.fast } }
                GlyphIcon {
                    anchors.centerIn: parent
                    width: 15 * root.s; height: 15 * root.s
                    name: ib.glyph
                    color: ib.lit ? Theme.cardBot : (ibMa.containsMouse ? root.accent : Theme.iconDim)
                    stroke: 1.7
                }
                SequentialAnimation on opacity {
                    running: ib.lit
                    loops: Animation.Infinite
                    NumberAnimation { from: 1; to: 0.45; duration: 620; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.45; to: 1; duration: 620; easing.type: Easing.InOutSine }
                }
                MouseArea {
                    id: ibMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ib.tapped()
                }
            }

            IconBtn {
                glyph: root.recording ? "stop" : "mic"
                lit: root.recording
                onTapped: if (root.service) root.service.toggleRecord(root.target)
            }
            IconBtn {
                glyph: "image"
                onTapped: if (root.service) root.service.shot(root.target)
            }
        }
    }
}
