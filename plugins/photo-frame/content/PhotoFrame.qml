pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import Ryoku.PluginKit.Singletons

/**
 * One framed photo. A "print": an optional coloured mat (the frame), the photo
 * clipped to rounded corners with a colour filter, an optional inner hairline, an
 * optional caption, and a soft drop shadow.
 *
 * Geometry is direct: `radius` is the outer corner roundness in px and `frame` is
 * the mat thickness in px - both are live user controls. `style` sets only the
 * mat's colour and character: "transparent" (rounded / square) is a frameless
 * print where the photo fills the tile; film / framed / polaroid give a dark /
 * cream / white frame. The photo widget runs without the host card (bg "none"),
 * so this mat is the only frame and the sliders own it.
 *
 * Rendering mirrors the shell's proven idioms: the photo is a ClippingRectangle
 * whose layer.effect MultiEffect applies the colour filter (pill/Wallpaper.qml),
 * and the shadow is a sibling MultiEffect sampling the opaque print behind it
 * (widgets/PluginDesktopSlot.qml) - no fragile nested-layer stack.
 */
Item {
    id: frame

    property url source
    property string style: "rounded"
    property string filter: "none"
    property string aspect: "4:3"
    property string caption: ""
    property real baseW: 320
    property real s: 1

    // Direct frame geometry (px, pre-scale) - the live "Roundness" / "Frame size".
    property real radius: 18
    property real frame: 14

    property bool shadowEnabled: true
    property real shadowBlur: 0.55
    property real shadowOffset: 8
    property real shadowOpacity: 0.45

    // A style: the mat's colour + character only (geometry comes from radius/frame).
    // "transparent" is a borderless print; `cap` allows a caption band.
    function _style(name) {
        switch (name) {
        case "square":   return { mat: "transparent", line: Qt.rgba(1, 1, 1, 0.14), lineW: 1, ink: "#e8ebfa", cap: false };
        case "polaroid": return { mat: "#f4f1ea",     line: "transparent",          lineW: 0, ink: "#33302b", cap: true };
        case "framed":   return { mat: "#ece4d8",     line: Qt.rgba(0, 0, 0, 0.20),  lineW: 1, ink: "#33302b", cap: true };
        case "film":     return { mat: "#141210",     line: Qt.rgba(1, 1, 1, 0.10),  lineW: 1, ink: "#e8ebfa", cap: false };
        default:         return { mat: "transparent", line: "transparent",          lineW: 0, ink: "#e8ebfa", cap: false }; // rounded
        }
    }

    // A colour filter mapped onto MultiEffect's adjustments.
    function _filter(name) {
        switch (name) {
        case "mono":  return { sat: -1.00, bri:  0.00, con:  0.00, col: 0.00, colC: "#000000" };
        case "noir":  return { sat: -1.00, bri: -0.04, con:  0.28, col: 0.00, colC: "#000000" };
        case "sepia": return { sat: -0.65, bri:  0.04, con:  0.05, col: 0.42, colC: "#6f4e37" };
        case "warm":  return { sat:  0.12, bri:  0.02, con:  0.03, col: 0.16, colC: "#ff7a45" };
        case "cool":  return { sat:  0.05, bri:  0.00, con:  0.03, col: 0.16, colC: "#5a7fff" };
        case "vivid": return { sat:  0.40, bri:  0.02, con:  0.12, col: 0.00, colC: "#000000" };
        case "fade":  return { sat: -0.20, bri:  0.07, con: -0.18, col: 0.00, colC: "#000000" };
        default:      return { sat:  0.00, bri:  0.00, con:  0.00, col: 0.00, colC: "#000000" }; // none
        }
    }

    readonly property var sp: _style(style)
    readonly property var fp: _filter(filter)

    // A frame only shows for a coloured mat; transparent styles ignore thickness.
    readonly property bool hasMat: frame.sp.mat !== "transparent"
    readonly property real matW: frame.hasMat ? Math.max(0, frame.frame) : 0
    readonly property real capBand: 30
    readonly property bool hasCaption: frame.caption.length > 0 && frame.sp.cap && frame.hasMat
    readonly property real rOuter: Math.max(0, frame.radius)
    readonly property real rInner: Math.max(0, frame.radius - frame.matW)

    // Aspect "W:H" -> photo height as a fraction of the photo width.
    readonly property real ratio: {
        var parts = String(aspect).split(":");
        var w = parts.length === 2 ? Number(parts[0]) : 4;
        var h = parts.length === 2 ? Number(parts[1]) : 3;
        return (w > 0 && h > 0) ? (h / w) : (3 / 4);
    }

    readonly property real photoW: Math.max(1, baseW - 2 * matW * s)
    readonly property real photoH: Math.max(1, Math.round(photoW * ratio))

    implicitWidth: baseW
    implicitHeight: photoH + (matW * 2 + (hasCaption ? capBand : 0)) * s

    // Soft drop shadow: a sibling MultiEffect that samples the opaque print and
    // sits behind it, so only the offset blur shows past the print's edge.
    MultiEffect {
        source: printItem
        anchors.fill: printItem
        visible: frame.shadowEnabled
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, frame.shadowOpacity)
        shadowBlur: frame.shadowBlur
        shadowVerticalOffset: frame.shadowOffset * frame.s
        blurMax: 64
        autoPaddingEnabled: true
    }

    // The print: mat + photo + hairline + caption.
    Rectangle {
        id: printItem
        anchors.fill: parent
        radius: frame.rOuter * frame.s
        color: frame.sp.mat

        // Inner hairline around the photo (square / framed / film).
        Rectangle {
            visible: frame.sp.lineW > 0
            x: frame.matW * frame.s - frame.sp.lineW
            y: frame.matW * frame.s - frame.sp.lineW
            width: frame.photoW + frame.sp.lineW * 2
            height: frame.photoH + frame.sp.lineW * 2
            radius: frame.rInner * frame.s + frame.sp.lineW
            color: "transparent"
            border.width: frame.sp.lineW
            border.color: frame.sp.line
        }

        // The photo: rounded clip + colour filter.
        ClippingRectangle {
            id: pic
            x: frame.matW * frame.s
            y: frame.matW * frame.s
            width: frame.photoW
            height: frame.photoH
            radius: frame.rInner * frame.s
            color: Qt.rgba(0, 0, 0, 0.18)

            Image {
                anchors.fill: parent
                source: frame.source
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
                sourceSize.width: Math.ceil(pic.width * 2)
                sourceSize.height: Math.ceil(pic.height * 2)
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                saturation: frame.fp.sat
                brightness: frame.fp.bri
                contrast: frame.fp.con
                colorization: frame.fp.col
                colorizationColor: frame.fp.colC
            }
        }

        // Caption band (polaroid / framed, when a caption is set).
        Text {
            visible: frame.hasCaption
            anchors.top: pic.bottom
            anchors.bottom: parent.bottom
            anchors.left: pic.left
            anchors.right: pic.right
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: frame.caption
            elide: Text.ElideRight
            color: frame.sp.ink
            font.family: Theme.font
            font.pixelSize: 13 * frame.s
            font.weight: Font.Medium
        }
    }
}
