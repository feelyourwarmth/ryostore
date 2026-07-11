pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// A searchable note chooser — surface-less content (the container supplies the
// panel), so it serves both as the capture overlay and embedded in the block
// builder. A pinned "today's daily note" (returns "") sits above the vault's
// notes, newest first, filtered live. The search field drives `editing`.
Item {
    id: root

    property real s: 1
    property var service: null
    property color accent: Theme.verm
    property string heading: qsTr("Choose a note")
    property bool allowDaily: true

    signal picked(string rel)
    signal dismissed()

    readonly property bool editing: search.input.activeFocus

    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    Component.onCompleted: {
        if (service) service.refreshNotes("");
        Qt.callLater(() => search.input.forceActiveFocus());
    }

    Timer {
        id: debounce
        interval: 180
        onTriggered: if (root.service) root.service.refreshNotes(search.text)
    }

    Column {
        id: col
        width: parent.width
        spacing: 11 * root.s

        Item {
            width: parent.width
            height: 14 * root.s
            Eyebrow { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: root.heading; s: root.s; tick: root.accent }
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 24 * root.s; height: 24 * root.s
                radius: 0
                antialiasing: false
                color: closeMa.containsMouse ? root.accent : "transparent"
                GlyphIcon {
                    anchors.centerIn: parent
                    width: 12 * root.s; height: 12 * root.s
                    name: "close"; color: closeMa.containsMouse ? Theme.cardBot : Theme.iconDim; stroke: 2
                }
                MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.dismissed() }
            }
        }

        Item {
            width: parent.width
            height: 30 * root.s
            SearchField {
                id: search
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                s: root.s
                kanji: "\u63a2"
                placeholder: qsTr("Search notes…")
                onTextChanged: debounce.restart()
                onDismissed: root.dismissed()
                // Enter commits the top result, or the pinned daily row when empty.
                onAccepted: {
                    if (root.service && root.service.notes.length > 0)
                        root.picked(root.service.notes[0]);
                    else if (root.allowDaily)
                        root.picked("");
                }
            }
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 1
                color: root.editing ? root.accent : Theme.lineStrong
                Behavior on color { ColorAnimation { duration: Motion.fast } }
            }
        }

        Rectangle {
            visible: root.allowDaily
            width: parent.width
            height: 32 * root.s
            radius: 0
            antialiasing: false
            color: dayMa.containsMouse ? Qt.alpha(root.accent, 0.12) : Qt.rgba(1, 1, 1, 0.02)
            border.width: 1
            border.color: dayMa.containsMouse ? Qt.alpha(root.accent, 0.5) : Theme.hair
            Row {
                anchors.left: parent.left; anchors.leftMargin: 10 * root.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: 9 * root.s
                GlyphIcon { anchors.verticalCenter: parent.verticalCenter; width: 14 * root.s; height: 14 * root.s; name: "sun"; color: root.accent; stroke: 1.7 }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Today's daily note")
                    color: Theme.cream; font.family: Theme.font; font.pixelSize: 12.5 * root.s; font.weight: Font.Medium
                }
            }
            MouseArea { id: dayMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.picked("") }
        }

        ListView {
            id: list
            width: parent.width
            height: Math.min(contentHeight, 170 * root.s)
            clip: true
            model: root.service ? root.service.notes : []
            reuseItems: true
            boundsBehavior: Flickable.StopAtBounds
            spacing: 2 * root.s

            delegate: Rectangle {
                id: nrow
                required property int index
                required property var modelData
                width: ListView.view.width
                height: 32 * root.s
                radius: 0
                antialiasing: false
                color: nma.containsMouse ? Qt.alpha(root.accent, 0.12) : "transparent"
                Row {
                    anchors.left: parent.left; anchors.leftMargin: 9 * root.s
                    anchors.right: parent.right; anchors.rightMargin: 9 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 9 * root.s
                    GlyphIcon { anchors.verticalCenter: parent.verticalCenter; width: 12 * root.s; height: 12 * root.s; name: "file"; color: nma.containsMouse ? root.accent : Theme.iconDim; stroke: 1.6 }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: nrow.width - 42 * root.s
                        elide: Text.ElideMiddle
                        text: nrow.modelData.replace(/\.md$/, "")
                        color: Theme.subtle; font.family: Theme.mono; font.pixelSize: 11 * root.s
                    }
                }
                MouseArea { id: nma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.picked(nrow.modelData) }
            }

            Text {
                anchors.centerIn: parent
                visible: list.count === 0
                text: root.service && root.service.notesLoading ? qsTr("Searching…")
                    : (root.service && root.service.notesError.length > 0
                        ? qsTr("Couldn't read vault: %1").arg(root.service.notesError)
                        : qsTr("No notes found"))
                color: Theme.faint; font.family: Theme.mono; font.pixelSize: 10.5 * root.s; font.letterSpacing: 1 * root.s
            }
        }
    }
}
