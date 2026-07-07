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

    implicitWidth: w
    implicitHeight: col.implicitHeight

    readonly property int nodeCount: service && service.graphData && service.graphData.nodes ? service.graphData.nodes.length : 0

    function layout() {
        var g = root.service ? root.service.graphData : null;
        var nodes = (g && g.nodes) ? g.nodes : [];
        var links = (g && g.links) ? g.links : [];
        var n = nodes.length;
        if (n === 0) { root.laid = []; edges.requestPaint(); return; }
        var W = root.w, H = root.areaH, i, j;
        var md = 1;
        for (i = 0; i < n; i++) md = Math.max(md, nodes[i].deg || 0);
        var pos = {}, arr = [];
        for (i = 0; i < n; i++) {
            var a = (i / n) * 6.28318;
            var node = { id: nodes[i].id, label: nodes[i].label, deg: nodes[i].deg || 0,
                x: W / 2 + Math.cos(a) * W * 0.3, y: H / 2 + Math.sin(a) * H * 0.3, vx: 0, vy: 0 };
            arr.push(node); pos[node.id] = node;
        }
        var k = 32 * root.s;
        for (var it = 0; it < 90; it++) {
            var cool = 1 - it / 90;
            for (i = 0; i < n; i++) for (j = i + 1; j < n; j++) {
                var dx = arr[i].x - arr[j].x, dy = arr[i].y - arr[j].y;
                var d2 = dx * dx + dy * dy + 0.01, d = Math.sqrt(d2);
                var f = (k * k) / d2 * 6, ux = dx / d, uy = dy / d;
                arr[i].vx += ux * f; arr[i].vy += uy * f;
                arr[j].vx -= ux * f; arr[j].vy -= uy * f;
            }
            for (var e = 0; e < links.length; e++) {
                var s1 = pos[links[e].s], t1 = pos[links[e].t];
                if (!s1 || !t1) continue;
                var ex = t1.x - s1.x, ey = t1.y - s1.y, ed = Math.sqrt(ex * ex + ey * ey) + 0.01;
                var fa = (ed * ed) / k * 0.008, ax = ex / ed, ay = ey / ed;
                s1.vx += ax * fa; s1.vy += ay * fa;
                t1.vx -= ax * fa; t1.vy -= ay * fa;
            }
            for (i = 0; i < n; i++) {
                arr[i].vx += (W / 2 - arr[i].x) * 0.02;
                arr[i].vy += (H / 2 - arr[i].y) * 0.02;
                arr[i].x += Math.max(-14, Math.min(14, arr[i].vx)) * cool;
                arr[i].y += Math.max(-14, Math.min(14, arr[i].vy)) * cool;
                arr[i].vx *= 0.85; arr[i].vy *= 0.85;
            }
        }
        var m = 18 * root.s;
        for (i = 0; i < n; i++) {
            arr[i].r = (4.5 + 9 * (arr[i].deg / md)) * root.s;
            arr[i].x = Math.max(m, Math.min(W - m, arr[i].x));
            arr[i].y = Math.max(m, Math.min(H - m, arr[i].y));
        }
        root.maxDeg = md;
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
                text: qsTr("%1 notes").arg(root.nodeCount)
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
                    ctx.lineWidth = 1;
                    ctx.strokeStyle = Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.3);
                    var links = g.links || [];
                    for (var e = 0; e < links.length; e++) {
                        var a = map[links[e].s], b = map[links[e].t];
                        if (!a || !b) continue;
                        ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.stroke();
                    }
                }
            }

            Repeater {
                model: root.laid
                delegate: Item {
                    id: gn
                    required property var modelData
                    readonly property real r: modelData.r
                    readonly property bool hub: modelData.deg >= Math.max(2, root.maxDeg * 0.5)
                    x: modelData.x
                    y: modelData.y
                    z: nma.containsMouse ? 10 : (hub ? 2 : 1)

                    Rectangle {
                        anchors.centerIn: parent
                        width: gn.r * 2
                        height: gn.r * 2
                        radius: 0
                        antialiasing: false
                        color: nma.containsMouse ? Theme.bright
                            : (gn.modelData.deg > 0 ? root.accent : Qt.alpha(root.accent, 0.22))
                        border.width: 1
                        border.color: root.accent
                        Behavior on color { ColorAnimation { duration: Motion.fast } }
                    }
                    Text {
                        visible: gn.hub || nma.containsMouse
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.verticalCenter
                        anchors.topMargin: gn.r + 3 * root.s
                        text: gn.modelData.label
                        color: nma.containsMouse ? Theme.bright : Theme.subtle
                        font.family: Theme.mono
                        font.pixelSize: 9 * root.s
                        font.weight: nma.containsMouse ? Font.DemiBold : Font.Normal
                    }
                    MouseArea {
                        id: nma
                        anchors.centerIn: parent
                        width: Math.max(gn.r * 2, 22 * root.s)
                        height: Math.max(gn.r * 2, 22 * root.s)
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
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
