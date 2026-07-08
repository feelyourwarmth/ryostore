pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// The vault as a constellation: notes are nodes sized by how many links touch
// them, the [[wikilinks]] between them are the edges. A one-shot force layout
// settles the positions (computed on data/size change, never per frame), the
// edges are drawn once on a Canvas, and each node is a tappable square that
// opens the note in Obsidian. Surface-less — the container supplies the panel.
Item {
    id: root

    property real s: 1
    property real w: 320
    property var service: null
    property color accent: Theme.verm

    readonly property real areaH: 292 * s
    property var laid: []
    property real maxDeg: 1
    property string hoveredId: ""
    property var adj: ({})

    implicitWidth: w
    implicitHeight: col.implicitHeight

    readonly property int nodeCount: service && service.graphData && service.graphData.nodes ? service.graphData.nodes.length : 0
    readonly property int total: (service && service.graphTotal > root.nodeCount) ? service.graphTotal : root.nodeCount

    function layout() {
        var g = root.service ? root.service.graphData : null;
        var nodes = (g && g.nodes) ? g.nodes : [];
        var links = (g && g.links) ? g.links : [];
        var n = nodes.length;
        if (n === 0) { root.laid = []; root.adj = ({}); edges.requestPaint(); return; }
        var W = root.w, H = root.areaH, i, j, e;
        var md = 1;
        for (i = 0; i < n; i++) md = Math.max(md, nodes[i].deg || 0);

        // ideal edge length scales with the node count, so a dense vault spreads
        // across the whole area instead of clumping in the middle.
        var k = Math.max(14 * root.s, Math.sqrt((W * H) / n) * 0.62);

        var pos = {}, arr = [];
        for (i = 0; i < n; i++) {
            var ang = (i / n) * 6.28318, rad = Math.min(W, H) * 0.42;
            var node = { id: nodes[i].id, label: nodes[i].label, deg: nodes[i].deg || 0,
                x: W / 2 + Math.cos(ang) * rad, y: H / 2 + Math.sin(ang) * rad, vx: 0, vy: 0,
                r: (4 + 8 * Math.sqrt((nodes[i].deg || 0) / md)) * root.s };
            arr.push(node); pos[node.id] = node;
        }

        // one-shot force settle: repulsion (all pairs), a spring pulling linked
        // notes toward the ideal length, and a gentle centre pull.
        for (var it = 0; it < 80; it++) {
            var cool = 1 - it / 80;
            for (i = 0; i < n; i++) for (j = i + 1; j < n; j++) {
                var dx = arr[i].x - arr[j].x, dy = arr[i].y - arr[j].y;
                var d2 = dx * dx + dy * dy + 0.01, d = Math.sqrt(d2);
                var f = (k * k) / d2, ux = dx / d, uy = dy / d;
                arr[i].vx += ux * f; arr[i].vy += uy * f;
                arr[j].vx -= ux * f; arr[j].vy -= uy * f;
            }
            for (e = 0; e < links.length; e++) {
                var s1 = pos[links[e].s], t1 = pos[links[e].t];
                if (!s1 || !t1) continue;
                var ex = t1.x - s1.x, ey = t1.y - s1.y, ed = Math.sqrt(ex * ex + ey * ey) + 0.01;
                var fa = (ed - k) * 0.06, ax = ex / ed, ay = ey / ed;
                s1.vx += ax * fa; s1.vy += ay * fa;
                t1.vx -= ax * fa; t1.vy -= ay * fa;
            }
            for (i = 0; i < n; i++) {
                arr[i].vx += (W / 2 - arr[i].x) * 0.01;
                arr[i].vy += (H / 2 - arr[i].y) * 0.01;
                arr[i].x += Math.max(-16, Math.min(16, arr[i].vx)) * cool;
                arr[i].y += Math.max(-16, Math.min(16, arr[i].vy)) * cool;
                arr[i].vx *= 0.86; arr[i].vy *= 0.86;
            }
        }

        // collision relax: hard-separate any pair still overlapping, so two notes
        // never sit on top of one another (the reported overlap). Converges fast.
        var pad = 3 * root.s, m = 16 * root.s;
        for (var cp = 0; cp < 24; cp++) {
            var hit = false;
            for (i = 0; i < n; i++) for (j = i + 1; j < n; j++) {
                var cx = arr[j].x - arr[i].x, cy = arr[j].y - arr[i].y;
                var cd = Math.sqrt(cx * cx + cy * cy) || 0.01;
                var mind = arr[i].r + arr[j].r + pad;
                if (cd < mind) {
                    var push = (mind - cd) / 2, px = cx / cd, py = cy / cd;
                    arr[i].x -= px * push; arr[i].y -= py * push;
                    arr[j].x += px * push; arr[j].y += py * push;
                    hit = true;
                }
            }
            // keep everyone in the panel; the next pass re-separates any pair the
            // clamp nudged together, so we settle both in-bounds and non-overlapping.
            for (i = 0; i < n; i++) {
                arr[i].x = Math.max(m, Math.min(W - m, arr[i].x));
                arr[i].y = Math.max(m, Math.min(H - m, arr[i].y));
            }
            if (!hit) break;
        }

        var A = {};
        for (i = 0; i < n; i++) A[arr[i].id] = {};
        for (e = 0; e < links.length; e++)
            if (A[links[e].s] && A[links[e].t]) { A[links[e].s][links[e].t] = 1; A[links[e].t][links[e].s] = 1; }

        root.maxDeg = md;
        root.adj = A;
        root.laid = arr;
        edges.requestPaint();
    }

    Component.onCompleted: layout()
    onWChanged: layout()
    Connections { target: root.service; function onGraphDataChanged() { root.layout(); } }

    Column {
        id: col
        width: root.w
        spacing: 10 * root.s

        Item {
            width: parent.width
            height: 14 * root.s
            Eyebrow { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Graph"); s: root.s; tick: root.accent }
            Text {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                text: root.total > root.nodeCount ? qsTr("%1 of %2").arg(root.nodeCount).arg(root.total) : qsTr("%1 notes").arg(root.nodeCount)
                color: Theme.faint; font.family: Theme.mono; font.pixelSize: 9.5 * root.s; font.letterSpacing: 1 * root.s
            }
        }

        Rectangle {
            width: parent.width
            height: root.areaH
            radius: 0
            antialiasing: false
            color: Qt.rgba(0, 0, 0, 0.2)
            border.width: 1
            border.color: Theme.hair
            clip: true

            Canvas {
                id: edges
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    var g = root.service ? root.service.graphData : null;
                    if (!g || root.laid.length === 0) return;
                    var map = {};
                    for (var i = 0; i < root.laid.length; i++) map[root.laid[i].id] = root.laid[i];
                    var hv = root.hoveredId, links = g.links || [];
                    ctx.lineWidth = 1;
                    for (var e = 0; e < links.length; e++) {
                        var a = map[links[e].s], b = map[links[e].t];
                        if (!a || !b) continue;
                        var on = hv !== "" && (links[e].s === hv || links[e].t === hv);
                        var al = hv === "" ? 0.28 : (on ? 0.75 : 0.07);
                        ctx.strokeStyle = Qt.rgba(root.accent.r, root.accent.g, root.accent.b, al);
                        ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.stroke();
                    }
                }
            }
            Connections { target: root; function onHoveredIdChanged() { edges.requestPaint(); } }

            Repeater {
                model: root.laid
                delegate: Item {
                    id: gn
                    required property var modelData
                    readonly property real r: modelData.r
                    readonly property bool hub: modelData.deg >= Math.max(2, root.maxDeg * 0.5)
                    readonly property bool hovering: root.hoveredId === modelData.id
                    readonly property bool near: root.hoveredId === "" || hovering
                        || (root.adj[root.hoveredId] && root.adj[root.hoveredId][modelData.id] ? true : false)
                    x: modelData.x
                    y: modelData.y
                    z: hovering ? 10 : (hub ? 2 : 1)
                    opacity: near ? 1 : 0.25
                    Behavior on opacity { NumberAnimation { duration: Motion.fast } }

                    Rectangle {
                        anchors.centerIn: parent
                        width: gn.r * 2
                        height: gn.r * 2
                        radius: 0
                        antialiasing: false
                        color: gn.hovering ? Theme.bright
                            : (gn.modelData.deg > 0 ? root.accent : Qt.alpha(root.accent, 0.22))
                        border.width: 1
                        border.color: root.accent
                        Behavior on color { ColorAnimation { duration: Motion.fast } }
                    }
                    Text {
                        visible: gn.hub || gn.hovering
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.verticalCenter
                        anchors.topMargin: gn.r + 3 * root.s
                        // cap the width so a long note name can't sprawl across and
                        // overlap its neighbours; hovering widens it to read more.
                        width: (gn.hovering ? 132 : 84) * root.s
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        text: gn.modelData.label
                        color: gn.hovering ? Theme.bright : Theme.subtle
                        font.family: Theme.mono
                        font.pixelSize: 9 * root.s
                        font.weight: gn.hovering ? Font.DemiBold : Font.Normal
                    }
                    MouseArea {
                        id: nma
                        anchors.centerIn: parent
                        width: Math.max(gn.r * 2, 22 * root.s)
                        height: Math.max(gn.r * 2, 22 * root.s)
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.hoveredId = gn.modelData.id
                        onExited: if (root.hoveredId === gn.modelData.id) root.hoveredId = ""
                        onClicked: if (root.service) root.service.openNote(gn.modelData.id)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                width: parent.width - 40 * root.s
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                visible: root.laid.length === 0
                text: root.service && root.service.graphLoading ? qsTr("Reading vault…")
                    : qsTr("No notes yet. Capture something, then link notes with [[wikilinks]] to grow the graph.")
                color: Theme.faint
                font.family: Theme.mono
                font.pixelSize: 10 * root.s
                font.letterSpacing: 1 * root.s
                lineHeight: 1.3
            }
        }

        Text {
            width: parent.width
            visible: root.laid.length > 0
            text: qsTr("Tap a node to open it in Obsidian")
            color: Theme.faint
            font.family: Theme.mono
            font.pixelSize: 9.5 * root.s
            font.letterSpacing: 1 * root.s
        }
    }
}
