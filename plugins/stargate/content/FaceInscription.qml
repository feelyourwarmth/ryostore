pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons
import "gate.js" as Gate

/**
 * Inscription face: a widget that holds whatever you type. The `text` setting is
 * transliterated letter by letter into gate glyphs and carved across a warm
 * stone tablet - word by word, wrapping to the tile width - with the plain
 * sentence beneath it. Uses the same glyph renderer as the gate, so it honours a
 * loaded cap_resources font and falls back to the built-in runes otherwise.
 *
 * It ignores the clock and the dial machine; it is a message, not a gate.
 * Not square: the tablet's height follows the sentence.
 */
Item {
    id: root

    property var service: null
    property real s: 1
    property real cw: 360
    property bool active: true

    implicitWidth: cw
    implicitHeight: surface.implicitHeight

    readonly property string text: service ? service.text : ""
    readonly property string family: service ? service.glyphFamily : ""
    readonly property bool showText: service ? service.showTranslation : true
    readonly property var wordList: Gate.words(root.text)
    readonly property real pad: 18 * s
    readonly property real cell: Math.max(15 * s, Math.min(26 * s, (cw - pad * 2) / 13))

    // warm "Ancient" amber, optionally pulled toward the wallpaper accent.
    readonly property color glow: (service && service.wallustGlow)
        ? Qt.tint("#e8b46a", Qt.rgba(Wallust.accent.r, Wallust.accent.g, Wallust.accent.b, 0.5))
        : "#e8b46a"

    readonly property int glyphCount: {
        var n = 0; for (var i = 0; i < wordList.length; i++) n += wordList[i].length; return n;
    }

    Rectangle {
        id: surface
        width: root.cw
        implicitHeight: col.implicitHeight + root.pad * 2
        radius: 8 * root.s
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1c170f" }
            GradientStop { position: 1.0; color: "#100c07" }
        }
        border.width: 1
        border.color: Qt.rgba(root.glow.r, root.glow.g, root.glow.b, 0.22)
        clip: true

        CornerTicks { anchors.fill: parent; anchors.margins: 8 * root.s; s: root.s; tint: Qt.rgba(root.glow.r, root.glow.g, root.glow.b, 0.3) }

        // slow backlight sweep, so the inscription reads as powered.
        Rectangle {
            width: parent.width * 0.5; height: parent.height
            opacity: 0.06
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: root.glow }
                GradientStop { position: 1.0; color: "transparent" }
            }
            x: -width
            NumberAnimation on x {
                from: -parent.width * 0.5; to: parent.width
                duration: 5200; loops: Animation.Infinite; running: root.active
            }
        }

        Column {
            id: col
            x: root.pad; y: root.pad
            width: parent.width - root.pad * 2
            spacing: 12 * root.s

            // eyebrow
            Item {
                width: parent.width
                height: eyebrow.implicitHeight
                Row {
                    id: eyebrow
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 7 * root.s
                    Rectangle {
                        width: 5 * root.s; height: width; rotation: 45
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.glow
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("INSCRIPTION")
                        color: root.glow
                        font.family: Theme.mono; font.pixelSize: 9.5 * root.s
                        font.weight: Font.DemiBold; font.letterSpacing: 3 * root.s
                    }
                }
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.glyphCount + qsTr(" GLYPHS")
                    color: Qt.rgba(root.glow.r, root.glow.g, root.glow.b, 0.55)
                    font.family: Theme.mono; font.pixelSize: 8 * root.s
                    font.weight: Font.Medium; font.letterSpacing: 1.5 * root.s
                }
            }

            // the carved inscription: words of glyphs, wrapping.
            Flow {
                id: inscription
                width: parent.width
                spacing: 11 * root.s
                visible: root.glyphCount > 0

                Repeater {
                    model: root.wordList
                    delegate: Row {
                        id: word
                        required property var modelData
                        spacing: 3 * root.s
                        Repeater {
                            model: word.modelData
                            delegate: GateGlyph {
                                required property var modelData
                                width: root.cell; height: root.cell
                                index: modelData
                                family: root.family
                                glyphColor: root.glow
                                lit: 1
                            }
                        }
                    }
                }
            }

            // empty-state hint.
            Text {
                width: parent.width
                visible: root.glyphCount === 0
                text: qsTr("Type a sentence in the widget settings to carve it here.")
                color: Qt.rgba(root.glow.r, root.glow.g, root.glow.b, 0.6)
                font.family: Theme.mono; font.pixelSize: 11 * root.s
                wrapMode: Text.WordWrap
            }

            Rectangle {
                width: parent.width; height: 1
                visible: root.showText && root.glyphCount > 0
                color: Qt.rgba(root.glow.r, root.glow.g, root.glow.b, 0.16)
            }

            // the plain sentence.
            Text {
                width: parent.width
                visible: root.showText && root.text.length > 0
                text: root.text
                color: "#d3c8b0"
                font.family: Theme.font
                font.pixelSize: 13 * root.s
                font.italic: true
                wrapMode: Text.WordWrap
                lineHeight: 1.25
            }
        }
    }
}
