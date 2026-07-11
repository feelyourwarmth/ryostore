import QtQuick
import QtQuick.Shapes
import Ryoku.PluginKit.Singletons

// A plugin-local pencil glyph. The shared kit's GlyphIcon carries no edit/pencil
// mark, and the kit must stay untouched so this plugin keeps working against
// already-shipped shells — so the "edit this block" control draws its own here.
// Same 24x24 box + stroked-path idiom as GlyphIcon, tinted by Theme tokens, so
// it sits beside the kit glyphs without a seam.
Item {
    id: root

    property color color: Theme.iconDim
    property real stroke: 1.8

    readonly property real u: Math.min(width, height) / 24

    Shape {
        width: 24
        height: 24
        scale: root.u
        transformOrigin: Item.TopLeft
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.color
            fillColor: "transparent"
            strokeWidth: root.stroke
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            // a pencil: eraser cap top-right, nib into the bottom-left corner.
            PathSvg { path: "M17 3a2.828 2.828 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z" }
        }
    }
}
