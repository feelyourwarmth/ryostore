pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit.Singletons

// Ryoku-wave seek line: a uniform sine ripple painted twice - dim base across
// the full width plus a bright accent crest from the tail to the playback head,
// capped with a head dot where the soul bead would dock. Drag (when
// `interactive && service.canSeek`) commits to `service.seek(frac)`. The 500ms
// position poke timer here is gated on `visible && service.playing` so a hidden
// or paused face stays cold. Ported from ryoku/shell/quickshell/pill/Media.qml
// ~419-534.
Item {
  id: root

  property var service
  property real s: 1
  property color accent: Theme.brand
  property bool interactive: true

  // Drag book-keeping; the seek line reads `frac` for the head position.
  property real dragFrac: 0
  property bool dragging: false
  readonly property real playFrac: service ? service.playFrac : 0
  readonly property real frac: dragging ? dragFrac : playFrac

  implicitHeight: 18 * s

  // Cheap re-poke of the player's position while we're on-screen and playing -
  // strictly gated so a hidden or paused face costs nothing.
  Timer {
    interval: 500
    running: root.visible && (root.service?.playing ?? false)
    repeat: true
    onTriggered: {
      if (root.service && root.service.player)
        root.service.player.positionChanged();
    }
  }

  Canvas {
    id: stroke
    anchors.fill: parent

    readonly property real inset: 3 * root.s
    readonly property real usable: Math.max(1, width - 2 * inset)
    readonly property real amp: 2.2 * root.s
    readonly property real wavelength: 8 * root.s
    property real targetF: root.frac
    property real lastFrac: 0
    property real drawF: targetF
    readonly property real headX: inset + drawF * usable
    readonly property real headY: waveY(drawF)

    /**
     * Half-second chase between position ticks. Only enabled for small
     * advances, so seeks and track changes snap instead of gliding.
     */
    Behavior on drawF {
      enabled: Math.abs(root.frac - stroke.lastFrac) < 0.02
      NumberAnimation { duration: 500; easing.type: Easing.Linear }
    }
    onTargetFChanged: Qt.callLater(() => { stroke.lastFrac = root.frac; })

    onDrawFChanged: requestPaint()
    onWidthChanged: requestPaint()
    onVisibleChanged: if (visible) requestPaint()

    /** A Ryoku wave: a uniform sine ripple across the stroke, the same
     * signature the WaveMeter draws, so the seek line reads as the house wave. */
    function waveY(u) {
      return height / 2 + amp * Math.sin(u * usable * (6.28318 / wavelength));
    }

    onPaint: {
      const ctx = getContext("2d");
      ctx.reset();
      if (width <= 0 || height <= 0)
        return;
      ctx.lineWidth = 2 * root.s;
      ctx.lineCap = "round";
      ctx.lineJoin = "round";
      const steps = Math.max(8, Math.round(usable / 1.5));

      // Dim full-width base: the track the playback head has not reached.
      ctx.strokeStyle = Theme.border;
      ctx.beginPath();
      for (let i = 0; i <= steps; i++) {
        const u = i / steps;
        const x = inset + u * usable;
        const y = waveY(u);
        if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
      }
      ctx.stroke();

      if (drawF <= 0.002)
        return;

      // Bright crest from the tail to the playback head.
      ctx.strokeStyle = root.accent;
      ctx.beginPath();
      const lit = Math.max(2, Math.round(steps * drawF));
      for (let i = 0; i <= lit; i++) {
        const u = (i / lit) * drawF;
        const x = inset + u * usable;
        const y = waveY(u);
        if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
      }
      ctx.stroke();

      // Head dot: the playback position, where the soul bead docks.
      ctx.fillStyle = root.accent;
      ctx.beginPath();
      ctx.arc(headX, headY, 2.6 * root.s, 0, 6.28318);
      ctx.fill();
    }

    // Batch in-flight drags into 150 ms commits so we don't hammer MPRIS.
    Timer {
      id: dragWrite
      interval: 150
      repeat: true
      onTriggered: seekArea.commit()
    }

    MouseArea {
      id: seekArea
      anchors.fill: parent
      anchors.margins: -8 * root.s
      enabled: root.interactive
        && (root.service?.canSeek ?? false)
        && ((root.service?.lengthSec ?? 0) > 0)
      cursorShape: Qt.PointingHandCursor
      function fracAt(mx) {
        return Math.max(0, Math.min(1, (mx - 8 * root.s - stroke.inset) / stroke.usable));
      }
      function commit() {
        if (root.service)
          root.service.seek(root.dragFrac);
      }
      onPressed: (e) => {
        root.dragFrac = fracAt(e.x);
        root.dragging = true;
        dragWrite.restart();
      }
      onPositionChanged: (e) => { if (pressed) root.dragFrac = fracAt(e.x); }
      onReleased: {
        dragWrite.stop();
        commit();
        root.dragging = false;
      }
    }
  }
}
