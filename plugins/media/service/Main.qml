pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Ryoku.PluginKit.Singletons

/**
 * Media plugin service: headless settings resolver + active-MPRIS-player state
 * + transport actions + spectrum wiring. The desktop-widget host keeps one of
 * these alive across mounts and hands it to the content as
 * pluginApi.mainInstance, so every face binds the same player and settings.
 *
 * Player pick order: playing > paused-with-track > controllable. Keeps a
 * browser that exposes an empty MPRIS endpoint from shadowing a paused player
 * that still has a track (ported from pill/Media.qml).
 *
 * Plugin settings are NOT auto-seeded from the manifest at runtime, so every
 * value is read here behind a default (resolver pattern matches
 * plugins/photo-frame/service/Main.qml).
 */
Item {
  id: root

  property var pluginApi
  readonly property var settings: pluginApi ? pluginApi.pluginSettings : null

  function _has(k) {
    return settings && settings[k] !== undefined && settings[k] !== null && settings[k] !== "";
  }
  function _str(k, d) { return _has(k) ? String(settings[k]) : d; }
  function _num(k, d) { return _has(k) ? Number(settings[k]) : d; }
  function _bool(k, d) {
    if (!settings || settings[k] === undefined || settings[k] === null)
      return d;
    return settings[k] === true || settings[k] === "true";
  }

  // ── settings ────────────────────────────────────────────────────────────
  readonly property string design: _str("design", "dossier")
  readonly property string accent: _str("accent", "wallust")
  readonly property bool showSource: _bool("showSource", true)
  readonly property bool showSeek: _bool("showSeek", true)
  readonly property real artRadius: _num("artRadius", 14)
  readonly property string posterFilter: _str("posterFilter", "none")
  readonly property bool spectrumOverlay: _bool("spectrumOverlay", false)
  readonly property int spectrumBars: _num("spectrumBars", 48)

  // Raw configured GIF path (the Loop face's source): empty, a bare absolute
  // path, ~/relative, or a url. Resolved into `gifSource` below.
  readonly property string gifPath: _str("gifPath", "")

  // Effective GIF url. Empty path falls back to the bundled sample so the
  // Loop face is never blank; a url is used verbatim; ~/ is expanded; a bare
  // path becomes a file url. Mirrors photo-frame's `source` resolution.
  readonly property url gifSource: {
    var p = gifPath.trim();
    if (p.length === 0)
      return (pluginApi && pluginApi.pluginDir) ? ("file://" + pluginApi.pluginDir + "/assets/sample.gif") : "";
    if (p.indexOf("://") >= 0)
      return p;
    if (p.indexOf("~/") === 0)
      p = (Quickshell.env("HOME") || "") + p.substring(1);
    return "file://" + p;
  }

  // ── player state ────────────────────────────────────────────────────────
  readonly property var player: {
    var list = Mpris.players.values;
    if (!list || list.length === 0)
      return null;
    var withTrack = null;
    var controllable = null;
    for (var i = 0; i < list.length; i++) {
      var p = list[i];
      if (!p)
        continue;
      if (p.isPlaying)
        return p;
      if (!withTrack && p.canControl && p.trackTitle && p.trackTitle.length > 0)
        withTrack = p;
      if (!controllable && p.canControl)
        controllable = p;
    }
    return withTrack ? withTrack : (controllable ? controllable : list[0]);
  }

  readonly property bool hasPlayer: player !== null
  readonly property bool playing: hasPlayer && player.isPlaying
  readonly property string title: hasPlayer && player.trackTitle ? player.trackTitle : "Nothing playing"
  readonly property string artist: hasPlayer
    ? Theme.joinArtists(player.trackArtists, player.trackArtist) : ""
  readonly property string artUrl: hasPlayer && player.trackArtUrl ? player.trackArtUrl : ""
  readonly property string playerService: {
    if (!hasPlayer)
      return "";
    var n = player.identity ? player.identity : (player.desktopEntry ? player.desktopEntry : "");
    return n.toLowerCase();
  }
  readonly property real lengthSec: hasPlayer && player.length > 0 ? player.length : 0
  readonly property real positionSec: hasPlayer ? player.position : 0
  readonly property real playFrac: lengthSec > 0 ? Math.max(0, Math.min(1, positionSec / lengthSec)) : 0

  // ── actions + capabilities ──────────────────────────────────────────────
  // Each action is a no-op when the matching capability is false, so faces
  // can wire buttons unconditionally and just dim/disable on the cap bool.
  function togglePlaying() { if (canTogglePlaying) player.togglePlaying(); }
  function next() { if (canGoNext) player.next(); }
  function previous() { if (canGoPrevious) player.previous(); }
  function seek(frac) {
    if (canSeek && lengthSec > 0)
      player.position = Math.max(0, Math.min(1, frac)) * lengthSec;
  }

  readonly property bool canGoNext: hasPlayer && player.canGoNext
  readonly property bool canGoPrevious: hasPlayer && player.canGoPrevious
  readonly property bool canSeek: hasPlayer && player.canSeek
  readonly property bool canTogglePlaying: hasPlayer && player.canTogglePlaying

  // ── spectrum wiring ─────────────────────────────────────────────────────
  // Cava only runs while a face that actually shows bars/ring is selected
  // AND something is playing. The spectrum singleton was made non-singleton
  // so each service owns its own cava process and tears it down with the
  // plugin.
  readonly property bool spectrumNeeded:
    design === "spectrum"
    || ((design === "vinyl" || design === "poster" || design === "loop") && spectrumOverlay)

  Spectrum {
    id: spectrumSvc
    active: root.spectrumNeeded && root.playing
    bars: root.spectrumBars
  }
  readonly property var spectrum: spectrumSvc

  // ── accent helper ───────────────────────────────────────────────────────
  // Faces call this instead of branching on `accent` themselves so the
  // wallust-vs-brand-vs-mono decision lives in one place. Wallust's `accent`
  // is a real `color` property (see Ryoku.PluginKit.Singletons.Wallust), so
  // the `!== undefined` guard is belt-and-braces against a future singleton
  // rev that drops the field.
  function accentColor() {
    return accent === "brand" ? Theme.brand
      : accent === "mono" ? Theme.cream
      : (Wallust.accent !== undefined ? Wallust.accent : Theme.brand);
  }

  // 500ms position poke so faces that bind to player.position get a steady
  // tick while playing. Cheap; only runs while something is actually playing,
  // and faces still gate their own repaints/animation on service.playing.
  Timer {
    interval: 500
    running: root.playing
    repeat: true
    onTriggered: if (root.player) root.player.positionChanged()
  }
}
