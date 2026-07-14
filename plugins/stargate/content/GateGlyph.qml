pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import "gate.js" as Gate

/**
 * One gate glyph, sized to fill its parent cell. Renders one of three ways:
 *
 *  - font mode (`family` set, `isPoo` false): the glyph character in the loaded
 *    cap_resources Stargate font.
 *  - procedural mode (`family` empty): a crisp, mirror-symmetric rune drawn as
 *    vector strokes from Gate.glyphShape() - a small designed alphabet, so the
 *    widget reads as engraved gate script with no font installed.
 *  - point of origin (`isPoo` true): always the drawn pyramid-under-sun, whatever
 *    the font, because the origin symbol is special and font-independent.
 *
 * `lit` (0..1) is the emphasis: a locked chevron's glyph, or an active address
 * cell, rides up to 1; pending glyphs sit dim. It animates by default.
 */
Item {
    id: g

    property int index: 0
    property bool isPoo: false
    property string family: ""
    property color glyphColor: "#dfe9ff"
    property real lit: 1
    property int weight: Font.Normal

    readonly property bool procedural: g.isPoo || g.family.length === 0
    readonly property var shape: g.isPoo ? ({ lines: [], nodes: [] }) : Gate.glyphShape(g.index)
    readonly property real strokeW: Math.max(1, Math.min(width, height) * 0.05)
    readonly property real emphasis: 0.32 + 0.68 * g.lit

    Behavior on lit { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    function buildStroke() {
        var w = width, h = height, out = "";
        var ls = g.shape.lines;
        for (var i = 0; i < ls.length; i++) {
            var pl = ls[i];
            for (var j = 0; j < pl.length; j++)
                out += (j === 0 ? "M " : "L ") + (pl[j][0] * w).toFixed(2) + " " + (pl[j][1] * h).toFixed(2) + " ";
        }
        return out;
    }

    // ── font glyph ───────────────────────────────────────────────────────────
    Text {
        anchors.fill: parent
        visible: !g.procedural
        text: Gate.charForIndex(g.index)
        color: g.glyphColor
        opacity: g.emphasis
        font.family: g.family
        font.weight: g.weight
        font.pixelSize: Math.max(6, Math.min(width, height) * 0.96)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        fontSizeMode: Text.Fit
        renderType: Text.QtRendering
    }

    // ── procedural rune ────────────────────────────────────────────────────
    Shape {
        anchors.fill: parent
        visible: g.procedural && !g.isPoo
        opacity: g.emphasis
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: g.glyphColor
            fillColor: "transparent"
            strokeWidth: g.strokeW
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: g.width > 0 ? g.buildStroke() : "" }
        }
    }
    Repeater {
        model: (g.procedural && !g.isPoo) ? g.shape.nodes : []
        delegate: Rectangle {
            required property var modelData
            readonly property real rr: g.strokeW * 0.95
            x: modelData[0] * g.width - rr
            y: modelData[1] * g.height - rr
            width: rr * 2; height: rr * 2; radius: rr
            color: g.glyphColor
            opacity: g.emphasis
        }
    }

    // ── point of origin: pyramid under the sun ───────────────────────────────
    Item {
        anchors.fill: parent
        visible: g.isPoo
        opacity: g.emphasis
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: g.glyphColor
                fillColor: "transparent"
                strokeWidth: g.strokeW
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                PathSvg {
                    path: {
                        var w = g.width, h = g.height;
                        return "M " + (w * 0.16) + " " + (h * 0.80) + " L " + (w * 0.84) + " " + (h * 0.80)
                             + " M " + (w * 0.28) + " " + (h * 0.80) + " L " + (w * 0.50) + " " + (h * 0.44)
                             + " L " + (w * 0.72) + " " + (h * 0.80);
                    }
                }
            }
        }
        Rectangle {                          // sun
            readonly property real rr: Math.min(g.width, g.height) * 0.11
            x: g.width * 0.5 - rr; y: g.height * 0.26 - rr
            width: rr * 2; height: rr * 2; radius: rr
            color: g.glyphColor
        }
        Rectangle {                          // sun halo
            readonly property real rr: Math.min(g.width, g.height) * 0.19
            x: g.width * 0.5 - rr; y: g.height * 0.26 - rr
            width: rr * 2; height: rr * 2; radius: rr
            color: "transparent"
            border.width: g.strokeW * 0.8
            border.color: g.glyphColor
            opacity: 0.6
        }
    }
}
