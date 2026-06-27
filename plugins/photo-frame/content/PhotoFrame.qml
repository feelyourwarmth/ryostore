pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import Ryoku.PluginKit.Singletons

/**
 * One framed photo. Given a source and a few semantic settings (style, filter,
 * aspect, caption, shadow), it renders a "print": an optional mat, the photo
 * clipped to rounded corners with a colour filter, an optional inner hairline,
 * an optional caption, and a soft drop shadow.
 *
 * Rendering mirrors the shell's proven idioms so it composites correctly in
 * Quickshell: the photo is a ClippingRectangle whose layer.effect MultiEffect
 * applies the colour filter (as in pill/Wallpaper.qml), and the shadow is a
 * sibling MultiEffect that samples the opaque print behind it (as in
 * widgets/PluginDesktopSlot.qml) - so there is no fragile nested-layer stack.
 *
 * `baseW` is the print's outer width; the photo area is derived from it and the
 * aspect ratio, and the root reports its intrinsic size so the host can size the
 * tile around it.
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

    property bool shadowEnabled: true
    property real shadowBlur: 0.55
    property real shadowOffset: 8
    property real shadowOpacity: 0.45

    // A frame style: outer/inner corner radius, mat colour and margins, an
    // optional inner hairline, and the caption ink for that mat. A "transparent"
    // mat is a borderless print (the photo fills the whole tile).
    function _style(name) {
        switch (name) {
        case "square":   return { outer: 2,  inner: 2,  mat: "transparent", mT: 0,  mS: 0,  mB: 0,  line: Qt.rgba(1, 1, 1, 0.14), lineW: 1, ink: "#e8ebfa" };
        case "polaroid": return { outer: 10, inner: 2,  mat: "#f4f1ea",     mT: 15, mS: 15, mB: 52, line: "transparent",          lineW: 0, ink: "#33302b" };
        case "framed":   return { outer: 6,  inner: 2,  mat: "#ece4d8",     mT: 22, mS: 22, mB: 22, line: Qt.rgba(0, 0, 0, 0.20),  lineW: 1, ink: "#33302b" };
        case "film":     return { outer: 4,  inner: 1,  mat: "#141210",     mT: 13, mS: 13, mB: 13, line: Qt.rgba(1, 1, 1, 0.10),  lineW: 1, ink: "#e8ebfa" };
        default:         return { outer: 16, inner: 16, mat: "transparent", mT: 0,  mS: 0,  mB: 0,  line: "transparent",          lineW: 0, ink: "#e8ebfa" }; // rounded
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

    // Aspect "W:H" -> photo height as a fraction of the photo width.
    readonly property real ratio: {
        var parts = String(aspect).split(":");
        var w = parts.length === 2 ? Number(parts[0]) : 4;
        var h = parts.length === 2 ? Number(parts[1]) : 3;
        return (w > 0 && h > 0) ? (h / w) : (3 / 4);
    }

    readonly property real photoW: Math.max(1, baseW - 2 * sp.mS * s)
    readonly property real photoH: Math.max(1, Math.round(photoW * ratio))
    readonly property bool hasCaption: caption.length > 0 && sp.mB >= 28

    implicitWidth: baseW
    implicitHeight: photoH + (sp.mT + sp.mB) * s

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
        radius: frame.sp.outer * frame.s
        color: frame.sp.mat

        // Inner hairline around the photo (square / framed / film).
        Rectangle {
            visible: frame.sp.lineW > 0
            x: frame.sp.mS * frame.s - frame.sp.lineW
            y: frame.sp.mT * frame.s - frame.sp.lineW
            width: frame.photoW + frame.sp.lineW * 2
            height: frame.photoH + frame.sp.lineW * 2
            radius: frame.sp.inner * frame.s + frame.sp.lineW
            color: "transparent"
            border.width: frame.sp.lineW
            border.color: frame.sp.line
        }

        // The photo: rounded clip + colour filter.
        ClippingRectangle {
            id: pic
            x: frame.sp.mS * frame.s
            y: frame.sp.mT * frame.s
            width: frame.photoW
            height: frame.photoH
            radius: frame.sp.inner * frame.s
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

        // Caption band (polaroid, or any mat with a deep bottom margin).
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
