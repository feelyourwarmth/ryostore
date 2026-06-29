pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Cava-backed audio spectrum stream. Non-singleton port of
 * ryoku/shell/quickshell/visualizer/Singletons/Spectrum.qml so each Media
 * service instance owns its own cava process and the process only runs while
 * the widget actually needs it.
 *
 * `active` gates the cava `Process` (raw ascii / pipewire input). `bars`
 * resizes the cava grid -- cava is restarted whenever bars changes so its
 * generated config picks up the new band count. When cava isn't installed
 * the wrapper exits cleanly (`command -v cava || exit 0`) and `levels`
 * stays at the flat resting line so the spectrum face never freezes on the
 * last peak.
 */
Item {
  id: root

  property bool active: false
  property int bars: 48

  // 0..1 per band (length == bars) + mean energy across all bands.
  property var levels: root.flat(0.02)
  property real energy: 0
  property real lastReadMs: 0

  function flat(v) {
    var a = [];
    for (var i = 0; i < root.bars; i++)
      a.push(v);
    return a;
  }

  function norm(v) {
    var n = parseInt(v);
    if (isNaN(n))
      return 0;
    return Math.max(0, Math.min(1, n / 100));
  }

  function readBars(line) {
    var t = line.trim();
    if (!t)
      return;
    var parts = t.split(/[;\s]+/);
    if (parts.length < root.bars)
      return;
    var out = [];
    var sum = 0;
    for (var i = 0; i < root.bars; i++) {
      var v = root.norm(parts[i]);
      out.push(v);
      sum += v;
    }
    root.levels = out;
    root.energy = sum / root.bars;
    root.lastReadMs = Date.now();
  }

  Process {
    id: cavaProc
    command: ["sh", "-c", "command -v cava >/dev/null 2>&1 || exit 0; cfg=$(mktemp); printf '%s\\n' '[general]' 'framerate = 60' 'bars = " + root.bars + "' '' '[input]' 'method = pipewire' '' '[output]' 'method = raw' 'raw_target = /dev/stdout' 'data_format = ascii' 'ascii_max_range = 100' 'channels = mono' 'mono_option = average' '' '[smoothing]' 'noise_reduction = 45' > \"$cfg\"; cava -p \"$cfg\"; rc=$?; rm -f \"$cfg\"; exit $rc"]
    running: root.active
    stdout: SplitParser {
      splitMarker: "\n"
      onRead: (line) => root.readBars(line)
    }
    onExited: if (root.active) restartTimer.restart()
  }

  Timer {
    id: restartTimer
    interval: 1200
    onTriggered: if (root.active && !cavaProc.running) cavaProc.running = true
  }

  // Restart cava when the band count changes so its generated config picks
  // up the new bars. The Process `command` binding already re-evaluates on
  // `bars`, but cava only reads its config at start, so we have to bounce.
  Timer {
    id: barsRestart
    interval: 300
    onTriggered: if (root.active && !cavaProc.running) cavaProc.running = true
  }

  // Settle to a flat resting line when no frame has arrived in a bit, so
  // a system gone silent (or a cava restart gap) doesn't freeze the bars
  // on the last peak.
  Timer {
    interval: 120
    running: root.active
    repeat: true
    onTriggered: if (Date.now() - root.lastReadMs > 260) {
      root.levels = root.flat(0.02);
      root.energy = 0;
    }
  }

  onActiveChanged: {
    levels = flat(0.02);
    energy = 0;
    if (active)
      lastReadMs = 0;
  }

  onBarsChanged: {
    levels = flat(0.02);
    if (root.active) {
      cavaProc.running = false;
      barsRestart.restart();
    }
  }
}
