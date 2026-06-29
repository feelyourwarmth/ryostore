pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit.Singletons

// One row of rounded vertical bars, one per entry in `levels` (each 0..1). Each
// bar's height is `level * barHeight`, filled with `accent`, anchored to a faint
// baseline. The canvas repaints ONLY when `levels` changes - no idle timer - so
// a paused service that stops emitting holds its last frame at zero cost.
Item {
  id: root

  property var levels: []
  property color accent: Theme.brand
  property real s: 1
  property real barHeight: 56 * s

  implicitHeight: barHeight

  // Bars share a slot of width = full / count; the bar itself is a fraction of
  // that slot so adjacent bars get a hairline gap.
  readonly property real _slotFill: 0.62

  Connections {
    target: root
    function onLevelsChanged() { bars.requestPaint(); }
    function onAccentChanged() { bars.requestPaint(); }
  }

  Canvas {
    id: bars
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

      // Faint baseline regardless of whether we have data, so the row reads as
      // present (not missing) while a service is spinning up.
      ctx.fillStyle = Theme.faint;
      ctx.fillRect(0, height - 1, width, 1);

      if (n <= 0)
        return;

      const slot = width / n;
      const bw = Math.max(1, slot * root._slotFill);
      const radius = Math.min(bw / 2, 2 * root.s);

      ctx.fillStyle = root.accent;
      for (let i = 0; i < n; i++) {
        const lv = Math.max(0, Math.min(1, arr[i] || 0));
        const h = Math.max(0, lv * height);
        if (h <= 0)
          continue;
        const x = i * slot + (slot - bw) / 2;
        const y = height - h;
        // Rounded top, square bottom: caps the bar against the baseline.
        ctx.beginPath();
        ctx.moveTo(x, y + radius);
        ctx.arcTo(x, y, x + radius, y, radius);
        ctx.lineTo(x + bw - radius, y);
        ctx.arcTo(x + bw, y, x + bw, y + radius, radius);
        ctx.lineTo(x + bw, height);
        ctx.lineTo(x, height);
        ctx.closePath();
        ctx.fill();
      }
    }
  }
}
