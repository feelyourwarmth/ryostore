pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Ryoku.PluginKit.Singletons

// A 2.5D layered ridgeline: the price profile extruded backward into a stack of
// depth rows, painted back-to-front so nearer rows occlude farther ones. Each
// row is one Shape whose fill runs a blue->green vertical gradient; a dark crest
// stroke draws the ridge separations. This is the "3D surface" illusion from the
// reference card without a real 3D engine.
//
// Performance: row PATHS are recomputed only when the data or size changes
// (never per frame). The passive drift and the data-reveal are TRANSFORM-only
// (a per-row sin translate + a Scale grow) so nothing rebuilds a path each
// frame - the qt-qml "no Canvas for animated content" rule, honoured with
// Shapes plus render-thread-friendly transforms. Both are gated on `visible`.
Item {
  id: root

  property var values: []
  property real min: 0
  property real max: 1
  property color crest: Theme.brand   // trend tint for the front crest highlight
  property int rows: 14
  property bool flow: true

  readonly property int n: Array.isArray(values) ? values.length : 0
  readonly property real span: (max - min) > 0 ? (max - min) : 1
  readonly property int seg: Math.min(Math.max(2, n - 1), 44)

  // ── reveal: rows scale up from the floor on new data, gated on visible ──
  property real grow: 0
  function reveal() {
    growAnim.stop();
    if (visible && n > 1) { grow = 0; growAnim.start(); }
    else grow = 1;
  }
  onNChanged: reveal()
  onWidthChanged: reveal()
  onHeightChanged: reveal()
  Component.onCompleted: reveal()
  NumberAnimation {
    id: growAnim
    target: root; property: "grow"
    from: 0; to: 1
    duration: Motion.shapeshift
    easing.type: Easing.OutCubic
  }

  // ── passive flow: one shared phase, each row reads sin(phase + depth) ──
  property real phase: 0
  NumberAnimation on phase {
    running: root.flow && root.visible
    loops: Animation.Infinite
    from: 0; to: 6.28318
    duration: 9000
  }

  // normalised height [0..1] of the data at fractional t, with a per-depth phase
  // shift so successive rows undulate and the surface reads as flowing in depth.
  function heightAt(t, d) {
    if (root.n < 2) return 0;
    var tt = t + d * 0.10;
    tt = tt - Math.floor(tt);
    var fx = tt * (root.n - 1);
    var i = Math.floor(fx), f = fx - i;
    var a = (root.values[i] - root.min) / root.span;
    var b = (root.values[Math.min(root.n - 1, i + 1)] - root.min) / root.span;
    return a + (b - a) * f;
  }

  // faint back grid, drawn behind the rows (matches the reference's back wall).
  Item {
    anchors.fill: parent
    visible: root.n > 1
    Repeater {
      model: 5
      Rectangle {
        required property int index
        width: parent.width
        height: 1
        y: parent.height * (0.16 + index * 0.13)
        color: Theme.hair
        opacity: 0.5
      }
    }
  }

  Repeater {
    model: root.rows

    Shape {
      id: rowShape
      required property int index
      anchors.fill: parent
      antialiasing: true
      preferredRendererType: Shape.CurveRenderer
      opacity: root.grow

      // depth 0 = back (higher, narrower, shifted right), 1 = front (low, wide).
      readonly property real d: root.rows > 1 ? index / (root.rows - 1) : 1
      readonly property real rowW: root.width * (0.72 + 0.28 * d)
      readonly property real xOff: (root.width - rowW) * 0.66
      readonly property real baseY: root.height * (0.46 + 0.52 * d)
      readonly property real amp: root.height * 0.44 * (0.85 + 0.15 * d)
      readonly property real floorY: root.height

      // crest points (for the dark separation stroke).
      readonly property var crestPts: {
        var out = [];
        for (var k = 0; k <= root.seg; k++) {
          var t = k / root.seg;
          var y = baseY - root.heightAt(t, d) * amp;
          out.push(Qt.point(xOff + t * rowW, y));
        }
        return out;
      }
      // fill polygon: floor -> crest -> floor -> close, so the row is a solid
      // curtain that occludes everything behind and below it.
      readonly property var fillPts: {
        var out = [Qt.point(xOff, floorY)];
        for (var k = 0; k < crestPts.length; k++) out.push(crestPts[k]);
        out.push(Qt.point(xOff + rowW, floorY));
        out.push(Qt.point(xOff, floorY));
        return out;
      }

      // grow from the floor + a gentle per-row drift (front rows drift most).
      transform: [
        Scale { origin.x: 0; origin.y: rowShape.floorY; yScale: root.grow },
        Translate { y: root.flow ? Math.sin(root.phase + rowShape.d * 2.4) * (2.4 * rowShape.d) : 0 }
      ]

      // the curtain: blue (low/front) -> green (high) vertical gradient.
      ShapePath {
        strokeColor: "transparent"
        PathPolyline { path: rowShape.fillPts }
        fillGradient: LinearGradient {
          x1: 0; y1: rowShape.baseY - rowShape.amp
          x2: 0; y2: rowShape.floorY
          GradientStop { position: 0.0; color: "#37e08a" }
          GradientStop { position: 0.35; color: "#25c6c0" }
          GradientStop { position: 0.7; color: "#3f7be6" }
          GradientStop { position: 1.0; color: "#4531b8" }
        }
      }
      // dark ridge line along the crest = the separations between rows.
      ShapePath {
        strokeColor: Qt.rgba(0, 0, 0, 0.55)
        strokeWidth: 1.4
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathPolyline { path: rowShape.crestPts }
      }
      // trend-tinted highlight on the very front crest only.
      ShapePath {
        strokeColor: rowShape.index === root.rows - 1 ? Qt.alpha(root.crest, 0.7) : "transparent"
        strokeWidth: 1.5
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathPolyline { path: rowShape.crestPts }
      }
    }
  }
}
