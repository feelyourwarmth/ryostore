pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes

/**
 * One Stargate chevron, hand-authored as vector paths rather than a plain
 * triangle so it reads as the real gate hardware: a beveled metal housing
 * (a downward shield that clamps the ring's outer edge) cradling the iconic
 * downward chevron "light", which burns red-orange when the chevron locks.
 *
 * The item is oriented outer-edge-up / point-inward, matching a radial arm that
 * places it on the ring and rotates it into position. `style` switches between
 * the solid `metal` gate (Naquadah) and a luminous `holo` outline (Hologram).
 * `primary` adds the larger top-chevron console.
 */
Item {
    id: cv

    property real unit: 40
    property bool lit: false
    property bool primary: false
    property string style: "metal"          // "metal" | "holo"
    property color tint: "#3fe0ff"          // holo line colour
    property color lampColor: "#ff6a2a"     // metal lit colour

    width: unit
    height: unit * 1.12

    readonly property bool holo: style === "holo"
    property color litColor: cv.holo ? Qt.lighter(cv.tint, 1.3) : cv.lampColor

    // housing shield (points inward/down) and the chevron light path.
    readonly property string housingPath: "M 0.14 0.08 L 0.86 0.08 L 0.86 0.34 L 0.50 0.94 L 0.14 0.34 Z"
    readonly property string lightPath: "M 0.50 0.82 L 0.21 0.39 L 0.35 0.25 L 0.50 0.50 L 0.65 0.25 L 0.79 0.39 Z"
    readonly property string consolePath: "M 0.30 0.00 L 0.70 0.00 L 0.65 0.11 L 0.35 0.11 Z"

    function scaled(p) {
        // scale a normalised path (0..1) into this item's pixels.
        var w = width, h = height;
        return p.replace(/([0-9]*\.?[0-9]+) ([0-9]*\.?[0-9]+)/g, function (_, a, b) {
            return (parseFloat(a) * w).toFixed(2) + " " + (parseFloat(b) * h).toFixed(2);
        });
    }

    // hot core behind the light when locked - a tight core, not a soft halo.
    Rectangle {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -cv.height * 0.08
        width: cv.unit * 0.9; height: width; radius: width / 2
        visible: cv.lit
        opacity: cv.lit ? (cv.holo ? 0.5 : 0.42) : 0
        Behavior on opacity { NumberAnimation { duration: 260 } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(cv.litColor.r, cv.litColor.g, cv.litColor.b, cv.holo ? 0.9 : 1.0) }
            GradientStop { position: 0.4; color: Qt.rgba(cv.litColor.r, cv.litColor.g, cv.litColor.b, cv.holo ? 0.3 : 0.4) }
            GradientStop { position: 1.0; color: Qt.rgba(cv.litColor.r, cv.litColor.g, cv.litColor.b, 0) }
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // top console (primary chevron only).
        ShapePath {
            fillColor: cv.holo ? "transparent" : "#33383f"
            strokeColor: cv.holo ? Qt.rgba(cv.tint.r, cv.tint.g, cv.tint.b, 0.5) : Qt.rgba(1, 1, 1, 0.08)
            strokeWidth: cv.holo ? Math.max(1, cv.unit * 0.03) : 1
            PathSvg { path: cv.primary ? cv.scaled(cv.consolePath) : "" }
        }

        // metal housing.
        ShapePath {
            fillColor: cv.holo ? "transparent" : "#2b2f38"
            strokeColor: cv.holo ? Qt.rgba(cv.tint.r, cv.tint.g, cv.tint.b, 0.6) : Qt.rgba(1, 1, 1, 0.10)
            strokeWidth: cv.holo ? Math.max(1, cv.unit * 0.032) : 1
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: cv.scaled(cv.housingPath) }
        }

        // chevron light.
        ShapePath {
            fillColor: cv.holo ? "transparent" : (cv.lit ? cv.lampColor : "#431b13")
            strokeColor: cv.holo ? (cv.lit ? Qt.lighter(cv.litColor, 1.15) : Qt.rgba(cv.tint.r, cv.tint.g, cv.tint.b, 0.45))
                                 : Qt.rgba(0, 0, 0, 0.35)
            strokeWidth: cv.holo ? Math.max(1.2, cv.unit * (cv.lit ? 0.055 : 0.032)) : 1
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: cv.scaled(cv.lightPath) }
            Behavior on fillColor { ColorAnimation { duration: 260 } }
        }
    }
}
