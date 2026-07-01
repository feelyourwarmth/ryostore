pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Ryoku.PluginKit.Singletons

// Compact price polyline. Renders `values` (normalised to [min,max]) as a
// Shape/ShapePath line - never a Canvas, so it paints on the render thread and
// the draw-in stays cheap (qt-qml perf rule). On new data it re-reveals left to
// right via a clip sweep, but only while visible; hidden it just shows drawn.
Item {
  id: root

  property var values: []
  property real min: 0
  property real max: 1
  property color color: Theme.cream
  property real lineWidth: 2
  property bool animateDraw: true

  readonly property int n: Array.isArray(values) ? values.length : 0
  readonly property real span: (max - min) > 0 ? (max - min) : 1
  readonly property real pad: lineWidth

  // 0..1 reveal. Clip only sweeps while < 1, so no offscreen pass at rest.
  property real progress: 0
  function reveal() {
    drawAnim.stop();
    if (animateDraw && visible && n > 1) { progress = 0; drawAnim.start(); }
    else progress = 1;
  }
  onNChanged: reveal()
  Component.onCompleted: reveal()

  NumberAnimation {
    id: drawAnim
    target: root; property: "progress"
    from: 0; to: 1
    duration: Motion.shapeshift
    easing.type: Easing.OutCubic
  }

  // Map values -> points across the item box, y inverted (high value = high up),
  // inset by pad so the stroke never clips at the edges.
  function points() {
    var out = [];
    if (root.n < 2) return out;
    var w = root.width, h = root.height, p = root.pad;
    var iw = Math.max(1, w), ih = Math.max(1, h - 2 * p);
    for (var i = 0; i < root.n; i++) {
      var x = i / (root.n - 1) * iw;
      var y = p + (1 - (root.values[i] - root.min) / root.span) * ih;
      out.push(Qt.point(x, y));
    }
    return out;
  }

  Item {
    id: clipper
    height: parent.height
    width: parent.width * root.progress
    clip: root.progress < 1

    Shape {
      width: root.width
      height: root.height
      antialiasing: true
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        strokeColor: root.color
        strokeWidth: root.lineWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathPolyline { path: root.points() }
      }
    }
  }
}
