pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Ryoku.PluginKit.Singletons

// A 3D ridgeline chart: the price history drawn as a joyplot surface inside a
// wireframe box, in an axonometric ("viewed from above") projection matching the
// reference card - the sample/time axis runs along the front floor edge and
// tilts gently DOWN to the right, the depth recedes UP-right at a shallow angle,
// and price climbs the vertical front-left edge. Surface rows recede back-to-
// front, painted in that order so nearer ridges occlude farther ones; each is a
// Shape whose fill runs a blue->green vertical gradient with a dark crest line.
//
// Performance split, per the qt-qml rules: the box + grid + back-wall glow is
// STATIC (a Canvas that repaints only when the geometry changes - the rule's
// sanctioned use of Canvas for one-time drawing, never per frame). The surface
// rows are Shapes, and the only motion is a one-shot grow-in reveal on new data,
// gated on visibility. Axis labels are Text bound to the service formatters.
Item {
  id: root

  property var service: null
  property real s: 1
  property color crest: Theme.brand

  readonly property var vals: root.service && root.service.spark ? root.service.spark : []
  readonly property var tms: root.service && root.service.times ? root.service.times : []
  readonly property int n: root.vals.length
  readonly property real lo: root.service ? root.service.sparkMin : 0
  readonly property real hi: root.service ? root.service.sparkMax : 1
  readonly property real span: (root.hi - root.lo) > 0 ? (root.hi - root.lo) : 1

  // margins reserve room for the axis labels; the box lives inside them.
  readonly property real mL: 38 * s
  readonly property real mB: 18 * s
  readonly property real mT: 8 * s
  readonly property real mR: 10 * s
  readonly property real plotW: Math.max(1, width - mL - mR)
  readonly property real plotH: Math.max(1, height - mT - mB)

  // projection: depth recedes up-right (shallow), the sample axis tilts down-
  // right. depthX/xTilt are fractions of the box's own width so the angle is
  // stable across sizes. boxH takes whatever vertical room the two tilts leave.
  readonly property real depthX: plotW * 0.30
  readonly property real boxW: plotW - depthX
  readonly property real xTilt: boxW * 0.15         // sample-axis drop L->R (~9 deg)
  readonly property real depthY: plotH * 0.27       // depth rise front->back (~20 deg)
  readonly property real boxH: Math.max(1, plotH - xTilt - depthY)
  readonly property real baseY: height - mB - xTilt // y of the near (t0,fd0) floor corner

  readonly property int rows: 12
  readonly property int yTicks: 4                   // -> 5 price levels
  readonly property int xTicks: 4                   // -> 5 time labels
  readonly property real amp: boxH * 0.72
  readonly property int seg: Math.min(Math.max(2, n - 1), 40)

  // --- axonometric projection ---------------------------------------------
  // t: 0..1 along the sample/time axis (front floor edge, right + down).
  // fd: 0..1 depth, front(0)->back(1) (right + up).
  // h: 0..1 height above the floor (straight up).
  function pxAt(t, fd) { return mL + fd * depthX + t * boxW; }
  function floorY(t, fd) { return baseY + t * xTilt - fd * depthY; }
  function pyAt(t, fd, h) { return floorY(t, fd) - h * boxH; }

  // Pre-smoothed, normalised profile (moving average), computed once per data
  // change - joyplots smooth their density, and it turns noisy 5-min candles
  // into the reference's rolling hills. prof() just interpolates this array.
  readonly property var profile: {
    if (root.n < 2) return [];
    var norm = [];
    for (var i = 0; i < root.n; i++) norm.push((root.vals[i] - root.lo) / root.span);
    var r = Math.max(2, Math.round(root.n * 0.05));
    var out = [];
    for (var j = 0; j < root.n; j++) {
      var s0 = 0, c = 0;
      for (var k = -r; k <= r; k++) {
        var idx = j + k;
        if (idx < 0 || idx >= root.n) continue;
        var w = 1 - Math.abs(k) / (r + 1);   // triangular weight
        s0 += norm[idx] * w; c += w;
      }
      out.push(c > 0 ? s0 / c : norm[j]);
    }
    return out;
  }

  function prof(t, fd) {
    if (root.profile.length < 2) return 0;
    var tt = t - fd * 0.06;
    if (tt < 0) tt = 0; else if (tt > 1) tt = 1;
    var fx = tt * (root.profile.length - 1);
    var i = Math.floor(fx), f = fx - i;
    var a = root.profile[i];
    var b = root.profile[Math.min(root.profile.length - 1, i + 1)];
    return a + (b - a) * f;
  }

  // --- reveal: rows grow up from their baseline on new data, gated visible ---
  property real grow: 0
  function reveal() {
    growAnim.stop();
    if (visible && n > 1) { grow = 0; growAnim.start(); } else grow = 1;
  }
  onNChanged: reveal()
  onWidthChanged: reveal()
  onHeightChanged: reveal()
  Component.onCompleted: reveal()
  NumberAnimation {
    id: growAnim
    target: root; property: "grow"; from: 0; to: 1
    duration: Motion.shapeshift; easing.type: Easing.OutCubic
  }

  // --- static box + grid + glow (Canvas: repaint on geometry change only) ---
  Canvas {
    id: grid
    anchors.fill: parent
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onVisibleChanged: if (visible) requestPaint()

    onPaint: {
      var ctx = getContext("2d");
      ctx.reset();

      // green back-wall glow behind the peaks.
      var gx = root.pxAt(0.5, 0.7), gy = root.pyAt(0.5, 0.7, 0.7);
      var rg = ctx.createRadialGradient(gx, gy, 0, gx, gy, root.boxW * 0.7);
      rg.addColorStop(0, Qt.rgba(0.20, 0.86, 0.52, 0.18));
      rg.addColorStop(1, Qt.rgba(0.20, 0.86, 0.52, 0.0));
      ctx.fillStyle = rg;
      ctx.fillRect(0, 0, width, height);

      ctx.strokeStyle = "rgba(180,190,230,0.13)";
      ctx.lineWidth = 1;

      function line(x1, y1, x2, y2) {
        ctx.beginPath(); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke();
      }

      // back wall: horizontals (price levels) + verticals (time divisions).
      for (var k = 0; k <= root.yTicks; k++) {
        var fy = k / root.yTicks;
        line(root.pxAt(0, 1), root.pyAt(0, 1, fy), root.pxAt(1, 1), root.pyAt(1, 1, fy));
        // left wall: connect front-left tick to back-left tick at this level.
        line(root.pxAt(0, 0), root.pyAt(0, 0, fy), root.pxAt(0, 1), root.pyAt(0, 1, fy));
      }
      for (var v = 0; v <= root.xTicks; v++) {
        var ft = v / root.xTicks;
        line(root.pxAt(ft, 1), root.floorY(ft, 1), root.pxAt(ft, 1), root.pyAt(ft, 1, 1));
      }

      // floor: sample-axis lines (parallel to front edge) + depth connectors.
      for (var d = 0; d <= root.yTicks; d++) {
        var fdp = d / root.yTicks;
        line(root.pxAt(0, fdp), root.floorY(0, fdp), root.pxAt(1, fdp), root.floorY(1, fdp));
      }
      for (var c = 0; c <= root.xTicks; c++) {
        var t = c / root.xTicks;
        line(root.pxAt(t, 0), root.floorY(t, 0), root.pxAt(t, 1), root.floorY(t, 1));
      }

      // front-left vertical edge (the price axis spine).
      line(root.pxAt(0, 0), root.floorY(0, 0), root.pxAt(0, 0), root.pyAt(0, 0, 1));
    }
  }

  // --- the surface: rows back (index 0) to front (last), painted in order ---
  Repeater {
    model: root.rows

    Shape {
      id: rowShape
      required property int index
      anchors.fill: parent
      antialiasing: true
      preferredRendererType: Shape.CurveRenderer
      opacity: root.grow

      // index 0 = back (fd 1), last = front (fd 0).
      readonly property real fd: root.rows > 1 ? 1 - index / (root.rows - 1) : 0
      readonly property real midBaseY: root.floorY(0.5, fd)

      readonly property var crestPts: {
        var out = [];
        for (var k = 0; k <= root.seg; k++) {
          var t = k / root.seg;
          out.push(Qt.point(root.pxAt(t, fd), root.pyAt(t, fd, root.prof(t, fd))));
        }
        return out;
      }
      // fill down to the row's own (tilted) floor line, so it reads as a curtain.
      readonly property var fillPts: {
        var out = [Qt.point(root.pxAt(0, fd), root.floorY(0, fd))];
        for (var k = 0; k < crestPts.length; k++) out.push(crestPts[k]);
        out.push(Qt.point(root.pxAt(1, fd), root.floorY(1, fd)));
        return out;
      }

      // grow up from this row's baseline (pinned near its midpoint).
      transform: Scale { origin.x: 0; origin.y: rowShape.midBaseY; yScale: root.grow }

      ShapePath {
        strokeColor: "transparent"
        PathPolyline { path: rowShape.fillPts }
        fillGradient: LinearGradient {
          x1: 0; y1: rowShape.midBaseY - root.amp
          x2: 0; y2: rowShape.midBaseY
          GradientStop { position: 0.0; color: "#37e08a" }
          GradientStop { position: 0.4; color: "#25c6c0" }
          GradientStop { position: 0.72; color: "#3f7be6" }
          GradientStop { position: 1.0; color: "#4531b8" }
        }
      }
      ShapePath {
        strokeColor: Qt.rgba(0, 0, 0, 0.42)
        strokeWidth: 1.1
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathPolyline { path: rowShape.crestPts }
      }
      ShapePath {
        strokeColor: rowShape.index === root.rows - 1 ? Qt.alpha(root.crest, 0.75) : "transparent"
        strokeWidth: 1.6
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathPolyline { path: rowShape.crestPts }
      }
    }
  }

  // --- Y axis: price ticks up the front-left vertical edge ---
  Repeater {
    model: root.yTicks + 1
    Text {
      id: yl
      required property int index
      readonly property real fy: index / root.yTicks
      width: root.mL - 6 * root.s
      horizontalAlignment: Text.AlignRight
      x: 0
      y: root.pyAt(0, 0, fy) - implicitHeight / 2
      text: root.service ? root.service.fmtCompact(root.lo + root.span * fy) : ""
      color: Theme.faint
      font.family: Theme.mono
      font.pixelSize: 9 * root.s
      font.weight: Font.Medium
    }
  }

  // --- X axis: time ticks along the front floor edge (follows the down-tilt) ---
  Repeater {
    model: root.xTicks + 1
    Text {
      id: xl
      required property int index
      readonly property real ft: index / root.xTicks
      readonly property int di: Math.round(ft * (root.n - 1))
      horizontalAlignment: Text.AlignHCenter
      width: 40 * root.s
      x: root.pxAt(ft, 0) - width / 2
      y: root.floorY(ft, 0) + 3 * root.s
      text: (root.service && root.n > 1 && di >= 0 && di < root.tms.length) ? root.service.fmtTime(root.tms[di]) : ""
      color: Theme.faint
      font.family: Theme.mono
      font.pixelSize: 9 * root.s
      font.weight: Font.Medium
    }
  }
}
