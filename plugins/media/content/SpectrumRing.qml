pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit.Singletons

// Radial spectrum: one short bar per entry in `levels`, walked around a circle
// of `diameter`. Each bar starts on the ring and extends outward by
// `level * maxOut`. Repaints only when `levels` changes - no idle timer.
Item {
  id: root

  property var levels: []
  property color accent: Theme.brand
  property real s: 1
  property real diameter: 200 * s

  implicitWidth: diameter
  implicitHeight: diameter

  Connections {
    target: root
    function onLevelsChanged() { ring.requestPaint(); }
    function onAccentChanged() { ring.requestPaint(); }
  }

  Canvas {
    id: ring
    anchors.fill: parent

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onVisibleChanged: if (visible) requestPaint()

    onPaint: {
      const ctx = getContext("2d");
      ctx.reset();
      if (width <= 0 || height <= 0)
        return;

      const arr = root.levels || [];
      const n = arr.length;
      const cx = width / 2;
      const cy = height / 2;
      // Reserve ~18% of the radius for the outward bars; rest is the carrier.
      const rOuter = Math.min(cx, cy) - 1;
      const maxOut = rOuter * 0.18;
      const rInner = rOuter - maxOut;

      // Carrier ring: a faint hairline so the circle reads when the service is
      // idle or hasn't emitted yet.
      ctx.strokeStyle = Theme.hair;
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.arc(cx, cy, rInner, 0, 6.28318);
      ctx.stroke();

      if (n <= 0)
        return;

      const step = (2 * Math.PI) / n;
      ctx.strokeStyle = root.accent;
      ctx.lineCap = "round";
      ctx.lineWidth = Math.max(1, (2 * Math.PI * rInner) / n * 0.55);

      for (let i = 0; i < n; i++) {
        const lv = Math.max(0, Math.min(1, arr[i] || 0));
        if (lv <= 0)
          continue;
        // Start at -90deg so index 0 sits at 12 o'clock.
        const a = -Math.PI / 2 + i * step;
        const ca = Math.cos(a);
        const sa = Math.sin(a);
        const x0 = cx + ca * rInner;
        const y0 = cy + sa * rInner;
        const x1 = cx + ca * (rInner + lv * maxOut);
        const y1 = cy + sa * (rInner + lv * maxOut);
        ctx.beginPath();
        ctx.moveTo(x0, y0);
        ctx.lineTo(x1, y1);
        ctx.stroke();
      }
    }
  }
}
