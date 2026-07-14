// Shared, pure logic for the Stargate widget: the glyph alphabet, the
// time -> gate-address encoding, the SGC designation string, and the
// procedural constellation generator that draws a glyph when no Stargate
// font is loaded. No QML types are touched here, so it is a plain library
// the service and the content both import.
.pragma library

// Reliably-mapped glyph slots. Every cap_resources Stargate font maps A-Z and
// 0-9 to 36 distinct gate glyphs; the higher, less certain code points are
// avoided so an address never renders a blank cell. The point of origin is the
// 7th glyph and is always drawn procedurally (a pyramid under the sun), so it
// stays unmistakable and font-independent.
var ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
var GLYPHS = ALPHABET.length; // 36

// glyphSet id -> the internal family name of the matching cap_resources TTF.
// Used when the user installed a font system-wide and picks it by set.
var _FAMILIES = {
    sg1:       "Stargate Address Glyphs SG1",
    concept:   "Stargate Address Glyphs Concept",
    universe:  "Stargate Address Glyphs U",
    atlantis:  "Stargate Address Glyphs Atl",
    anquietas: "Anquietas",
    quiver:    "Quiver"
};

function family(set) {
    return _FAMILIES[set] || "";
}

function charForIndex(i) {
    return ALPHABET.charAt(((i % GLYPHS) + GLYPHS) % GLYPHS);
}

// mulberry32 - a tiny deterministic PRNG so a given seed always yields the same
// address and the same constellation shapes.
function _rng(seed) {
    var a = seed >>> 0;
    return function () {
        a |= 0; a = (a + 0x6D2B79F5) | 0;
        var t = Math.imul(a ^ (a >>> 15), 1 | a);
        t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
}

function _dayOfYear(d) {
    var start = new Date(d.getFullYear(), 0, 0);
    return Math.floor((d - start) / 86400000);
}

// The seed a mode derives its address from. clock changes every minute; date
// changes once a day. Returned as an int so QML fires the change signal only
// when the value actually rolls over, not every tick.
function seedFor(date, mode) {
    if (mode === "date")
        return (date.getFullYear() * 366 + _dayOfYear(date)) >>> 0;
    // clock: unique per minute, spread across the day and year.
    return ((_dayOfYear(date) * 1440) + date.getHours() * 60 + date.getMinutes()) >>> 0;
}

// A gate address: `count` unique glyph indices (constellations) drawn from the
// 36-slot pool by a seeded partial Fisher-Yates shuffle. Real addresses never
// repeat a constellation, so uniqueness is enforced.
function address(seed, count) {
    count = count || 6;
    if (count > GLYPHS) count = GLYPHS;
    var r = _rng((seed >>> 0) ^ 0x9e3779b9);
    var pool = [];
    for (var i = 0; i < GLYPHS; i++) pool.push(i);
    for (var k = 0; k < count; k++) {
        var j = k + Math.floor(r() * (pool.length - k));
        var t = pool[k]; pool[k] = pool[j]; pool[j] = t;
    }
    return pool.slice(0, count);
}

// An SGC-style planet designation, e.g. "P3X-482", derived from the address so
// it is stable for a given address and looks like the dialing computer's label.
function designation(glyphs) {
    if (!glyphs || glyphs.length === 0) return "P0X-000";
    var d = glyphs[0] % 10;
    var letter = String.fromCharCode(65 + (glyphs[Math.min(1, glyphs.length - 1)] % 26));
    var n = 0;
    for (var i = 0; i < glyphs.length; i++) n = (n * 37 + glyphs[i] + 7) % 900;
    var num = 100 + n;
    return "P" + d + letter + "-" + num;
}

// A procedural gate glyph for an index: a mirror-symmetric rune built from a
// small stroke grammar (spine, crown, cross-members, foot, optional cartouche
// brackets) plus a few terminal nodes. Coordinates are normalised 0..1 and the
// shape is deterministic per index, so the ring reads as one coherent alien
// script - not scattered dots. This is the font-free default; a loaded
// cap_resources font renders the authentic glyphs instead.
function glyphShape(index) {
    var r = _rng((Math.imul(index + 1, 2654435761)) ^ 0x1a2b3c4d);
    function ri(n) { return Math.floor(r() * n); }
    var lines = [];      // polylines: [[x,y],[x,y],...]
    var nodes = [];      // terminal dots: [x,y]
    var cx = 0.5;
    var top = 0.15 + r() * 0.05;
    var bot = 0.85 - r() * 0.05;

    lines.push([[cx, top], [cx, bot]]);              // spine

    // crown
    switch (ri(4)) {
    case 0: { var d = 0.08 + r() * 0.03;             // diamond
        lines.push([[cx, top - d], [cx - d, top], [cx, top + d], [cx + d, top], [cx, top - d]]); break; }
    case 1: { var w = 0.14 + r() * 0.12;             // crossbar
        lines.push([[cx - w, top], [cx + w, top]]); nodes.push([cx - w, top]); nodes.push([cx + w, top]); break; }
    case 2: { var w = 0.13 + r() * 0.09;             // antennae (V up)
        lines.push([[cx - w, top - 0.06], [cx, top + 0.03]]);
        lines.push([[cx + w, top - 0.06], [cx, top + 0.03]]);
        nodes.push([cx - w, top - 0.06]); nodes.push([cx + w, top - 0.06]); break; }
    default: nodes.push([cx, top]);
    }

    // one or two cross-members down the spine
    var nMid = 1 + ri(2);
    for (var i = 0; i < nMid; i++) {
        var my = 0.36 + (i + r()) * (0.44 / (nMid + 0.2));
        switch (ri(4)) {
        case 0: { var w = 0.17 + r() * 0.17;         // bar with end nodes
            lines.push([[cx - w, my], [cx + w, my]]); nodes.push([cx - w, my]); nodes.push([cx + w, my]); break; }
        case 1: { var w = 0.18 + r() * 0.14, dh = 0.09; // opposed chevrons
            lines.push([[cx - w, my - dh], [cx, my], [cx - w, my + dh]]);
            lines.push([[cx + w, my - dh], [cx, my], [cx + w, my + dh]]); break; }
        case 2: { var d = 0.11 + r() * 0.06;         // rhombus on the spine
            lines.push([[cx, my - d], [cx - d, my], [cx, my + d], [cx + d, my], [cx, my - d]]); break; }
        default: { var w2 = 0.15 + r() * 0.12, t = 0.06; // side ticks
            lines.push([[cx - w2, my - t], [cx - w2, my + t]]);
            lines.push([[cx + w2, my - t], [cx + w2, my + t]]); break; }
        }
    }

    // foot
    switch (ri(3)) {
    case 0: { var w = 0.13 + r() * 0.1; lines.push([[cx - w, bot], [cx + w, bot]]); break; }
    case 1: { var w = 0.12; lines.push([[cx - w, bot - 0.03], [cx, bot + 0.07], [cx + w, bot - 0.03]]); break; }
    default: nodes.push([cx, bot]);
    }

    // optional cartouche brackets
    if (r() < 0.4) {
        var ew = 0.33 + r() * 0.05;
        lines.push([[cx - ew, top + 0.05], [cx - ew, bot - 0.05]]);
        lines.push([[cx + ew, top + 0.05], [cx + ew, bot - 0.05]]);
    }

    return { lines: lines, nodes: nodes };
}

// Split free text into words of glyph indices for the Inscription face: each
// word becomes an array of ALPHABET indices (A-Z, 0-9), punctuation dropped, so
// a typed sentence transliterates to gate glyphs word by word.
function words(text) {
    var raw = String(text || "").toUpperCase().split(/\s+/);
    var out = [];
    for (var w = 0; w < raw.length; w++) {
        var idxs = [];
        for (var i = 0; i < raw[w].length; i++) {
            var p = ALPHABET.indexOf(raw[w].charAt(i));
            if (p >= 0) idxs.push(p);
        }
        if (idxs.length > 0) out.push(idxs);
    }
    return out;
}
