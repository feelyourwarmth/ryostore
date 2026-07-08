pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// The vault as a constellation: notes are nodes sized by how many links touch
// them, the [[wikilinks]] between them are the edges. A one-shot force layout
// (repulsion + link springs + collision, computed on data/size change, never per
// frame) spreads the graph across a virtual canvas; the view then fits it into
// the panel. Drag to pan, scroll to zoom, drag a node to move it, double-tap to
// reset, tap a node to open it in Obsidian. Surface-less: the container supplies
// the panel.
Item {
    id: root

    property real s: 1
    property real w: 320
    property var service: null
    property color accent: Theme.verm

    readonly property real areaH: 300 * s
    property var laid: []
    property real maxDeg: 1
    property string hoveredId: ""
    property var adj: ({})

    // laid-out world extent (0-based), and the pan/zoom view onto it.
    property real worldW: 1
    property real worldH: 1
    property real panX: 0
    property real panY: 0
    property real zoom: 1
    property real fitZoom: 1

    implicitWidth: w
    implicitHeight: col.implicitHeight

    readonly property int nodeCount: service && service.graphData && service.graphData.nodes ? service.graphData.nodes.length : 0
    readonly property int total: (service && service.graphTotal > root.nodeCount) ? service.graphTotal : root.nodeCount

    function layout() {
        var g = root.service ? root.service.graphData : null;
        var nodes = (g && g.nodes) ? g.nodes : [];
        var links = (g && g.links) ? g.links : [];
        var n = nodes.length;
        if (n === 0) {
            root.laid = [];
            root.adj = ({});
            edges.requestPaint();
            return;
        }
        var i, j, e;
        var md = 1;
        for (i = 0; i < n; i++)
            md = Math.max(md, nodes[i].deg || 0);

        // spread across a virtual canvas that grows with the node count, so a big
        // vault doesn't clump; fitView() scales the finished layout into the panel.
        var side = 140 + Math.sqrt(n) * 48;
        var k = side / Math.sqrt(n) * 0.9;   // ideal link length

        // seed on a golden-angle spiral so the start is already even, not a ring.
        var pos = {}, arr = [];
        for (i = 0; i < n; i++) {
            var ang = i * 2.399963, rr = side * 0.5 * Math.sqrt((i + 0.5) / n);
            var node = {
                id: nodes[i].id, label: nodes[i].label, deg: nodes[i].deg || 0,
                x: side / 2 + Math.cos(ang) * rr, y: side / 2 + Math.sin(ang) * rr,
                vx: 0, vy: 0, r: (4 + 8 * Math.sqrt((nodes[i].deg || 0) / md)) * root.s
            };
            arr.push(node);
            pos[node.id] = node;
        }

        // force settle: all-pairs repulsion, a spring toward the ideal link length,
        // and a very weak centre pull so stray islands don't drift off.
        for (var it = 0; it < 90; it++) {
            var cool = 1 - it / 90;
            for (i = 0; i < n; i++)
                for (j = i + 1; j < n; j++) {
                    var dx = arr[i].x - arr[j].x, dy = arr[i].y - arr[j].y;
                    var d2 = dx * dx + dy * dy + 0.01, d = Math.sqrt(d2);
                    var f = (k * k) / d2, ux = dx / d, uy = dy / d;
                    arr[i].vx += ux * f; arr[i].vy += uy * f;
                    arr[j].vx -= ux * f; arr[j].vy -= uy * f;
                }
            for (e = 0; e < links.length; e++) {
                var s1 = pos[links[e].s], t1 = pos[links[e].t];
                if (!s1 || !t1)
                    continue;
                var ex = t1.x - s1.x, ey = t1.y - s1.y, ed = Math.sqrt(ex * ex + ey * ey) + 0.01;
                var fa = (ed - k) * 0.05, ax = ex / ed, ay = ey / ed;
                s1.vx += ax * fa; s1.vy += ay * fa;
                t1.vx -= ax * fa; t1.vy -= ay * fa;
            }
            for (i = 0; i < n; i++) {
                arr[i].vx += (side / 2 - arr[i].x) * 0.004;
                arr[i].vy += (side / 2 - arr[i].y) * 0.004;
                var step = 24 * cool;
                arr[i].x += Math.max(-step, Math.min(step, arr[i].vx));
                arr[i].y += Math.max(-step, Math.min(step, arr[i].vy));
                arr[i].vx *= 0.85; arr[i].vy *= 0.85;
            }
        }

        // collision relax: hard-separate any overlap so no two notes stack (the
        // reported overlap). No bounds clamp here; fitView() frames the result.
        var pad = 5 * root.s;
        for (var cp = 0; cp < 22; cp++) {
            var hit = false;
            for (i = 0; i < n; i++)
                for (j = i + 1; j < n; j++) {
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
            if (!hit)
                break;
        }

        // normalise to a 0-based box and size the world to it.
        var minx = 1e9, miny = 1e9, maxx = -1e9, maxy = -1e9;
        for (i = 0; i < n; i++) {
            var a = arr[i];
            if (a.x - a.r < minx) minx = a.x - a.r;
            if (a.x + a.r > maxx) maxx = a.x + a.r;
            if (a.y - a.r < miny) miny = a.y - a.r;
            if (a.y + a.r > maxy) maxy = a.y + a.r;
        }
        var m2 = 14 * root.s;
        for (i = 0; i < n; i++) {
            arr[i].x += m2 - minx;
            arr[i].y += m2 - miny;
        }
        root.worldW = (maxx - minx) + 2 * m2;
        root.worldH = (maxy - miny) + 2 * m2;

        var A = {};
        for (i = 0; i < n; i++)
            A[arr[i].id] = {};
        for (e = 0; e < links.length; e++)
            if (A[links[e].s] && A[links[e].t]) {
                A[links[e].s][links[e].t] = 1;
                A[links[e].t][links[e].s] = 1;
            }

        root.maxDeg = md;
        root.adj = A;
        root.laid = arr;
        root.resetView();
        edges.requestPaint();
    }

    // frame the whole world in the panel (Obsidian-style fit), the default view.
    function fitView() {
        if (root.worldW <= 1)
            return;
        var pad = 8 * root.s, fw = root.w, fh = root.areaH;
        var z = Math.min((fw - 2 * pad) / root.worldW, (fh - 2 * pad) / root.worldH);
        z = Math.max(0.2, Math.min(1.6, z));
        root.fitZoom = z;
        root.zoom = z;
        root.panX = (fw - z * root.worldW) / 2;
        root.panY = (fh - z * root.worldH) / 2;
    }
    function resetView() { root.fitView(); }

    // zoom around a panel point, clamped relative to the fit zoom.
    function zoomAround(cx, cy, factor) {
        var nz = Math.max(root.fitZoom * 0.7, Math.min(root.fitZoom * 6, root.zoom * factor));
        var wx = (cx - root.panX) / root.zoom, wy = (cy - root.panY) / root.zoom;
        root.panX = cx - nz * wx;
        root.panY = cy - nz * wy;
        root.zoom = nz;
    }

    Component.onCompleted: layout()
    onWChanged: layout()
    Connections {
        target: root.service
        function onGraphDataChanged() { root.layout(); }
    }

    Column {
        id: col
        width: root.w
        spacing: 10 * root.s

        Item {
            width: parent.width
            height: 14 * root.s
            Eyebrow {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Graph")
                s: root.s
                tick: root.accent
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.total > root.nodeCount ? qsTr("%1 of %2").arg(root.nodeCount).arg(root.total) : qsTr("%1 notes").arg(root.nodeCount)
                color: Theme.faint
                font.family: Theme.mono
                font.pixelSize: 9.5 * root.s
                font.letterSpacing: 1 * root.s
            }
        }

        Rectangle {
            id: frame
            width: parent.width
            height: root.areaH
            radius: 0
            antialiasing: false
            color: Qt.rgba(0, 0, 0, 0.2)
            border.width: 1
            border.color: Theme.hair
            clip: true

            // scroll to zoom, around the cursor.
            WheelHandler {
                target: null
                onWheel: function (ev) {
                    root.zoomAround(ev.x, ev.y, ev.angleDelta.y > 0 ? 1.15 : 1 / 1.15);
                }
            }
            // drag empty space to pan. A node's own DragHandler grabs first when a
            // drag starts on it, so this only fires on the background.
            DragHandler {
                target: null
                property real sx: 0
                property real sy: 0
                onActiveChanged: if (active) {
                    sx = root.panX;
                    sy = root.panY;
                }
                onTranslationChanged: {
                    root.panX = sx + translation.x;
                    root.panY = sy + translation.y;
                }
            }
            // double-tap the background to reframe.
            TapHandler {
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onDoubleTapped: root.resetView()
            }

            Item {
                id: world
                width: root.worldW
                height: root.worldH
                transformOrigin: Item.TopLeft
                x: root.panX
                y: root.panY
                scale: root.zoom

                Canvas {
                    id: edges
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        if (root.laid.length === 0)
                            return;
                        var map = {};
                        for (var i = 0; i < root.laid.length; i++)
                            map[root.laid[i].id] = root.laid[i];
                        var hv = root.hoveredId;
                        var g = root.service ? root.service.graphData : null;
                        var links = (g && g.links) ? g.links : [];
                        ctx.lineWidth = 1;
                        for (var e = 0; e < links.length; e++) {
                            var a = map[links[e].s], b = map[links[e].t];
                            if (!a || !b)
                                continue;
                            var on = hv !== "" && (links[e].s === hv || links[e].t === hv);
                            var al = hv === "" ? 0.26 : (on ? 0.8 : 0.06);
                            ctx.strokeStyle = Qt.rgba(root.accent.r, root.accent.g, root.accent.b, al);
                            ctx.beginPath();
                            ctx.moveTo(a.x, a.y);
                            ctx.lineTo(b.x, b.y);
                            ctx.stroke();
                        }
                    }
                }
                Connections {
                    target: root
                    function onHoveredIdChanged() { edges.requestPaint(); }
                }

                Repeater {
                    model: root.laid
                    delegate: Item {
                        id: gn
                        required property var modelData
                        required property int index
                        readonly property real r: modelData.r
                        readonly property bool hub: modelData.deg >= Math.max(2, root.maxDeg * 0.5)
                        readonly property bool hovering: root.hoveredId === modelData.id
                        readonly property bool near: root.hoveredId === "" || hovering
                            || (root.adj[root.hoveredId] && root.adj[root.hoveredId][modelData.id] ? true : false)

                        width: Math.max(gn.r * 2, 20 * root.s)
                        height: width
                        x: modelData.x - width / 2
                        y: modelData.y - height / 2
                        z: hovering ? 10 : (hub ? 2 : 1)
                        opacity: near ? 1 : 0.22
                        Behavior on opacity { NumberAnimation { duration: Motion.fast } }

                        // dragging a node writes its centre back so the edges follow.
                        onXChanged: {
                            root.laid[gn.index].x = x + width / 2;
                            edges.requestPaint();
                        }
                        onYChanged: {
                            root.laid[gn.index].y = y + height / 2;
                            edges.requestPaint();
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: gn.r * 2
                            height: gn.r * 2
                            radius: 0
                            antialiasing: false
                            color: gn.hovering ? Theme.bright : (gn.modelData.deg > 0 ? root.accent : Qt.alpha(root.accent, 0.22))
                            border.width: 1
                            border.color: root.accent
                            Behavior on color { ColorAnimation { duration: Motion.fast } }
                        }
                        Text {
                            visible: gn.hub || gn.hovering
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.verticalCenter
                            anchors.topMargin: gn.r + 3 * root.s
                            width: (gn.hovering ? 150 : 96) * root.s
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            text: gn.modelData.label
                            color: gn.hovering ? Theme.bright : Theme.subtle
                            font.family: Theme.mono
                            font.pixelSize: 9 * root.s
                            font.weight: gn.hovering ? Font.DemiBold : Font.Normal
                        }

                        HoverHandler {
                            id: hh
                            cursorShape: Qt.PointingHandCursor
                            onHoveredChanged: {
                                if (hovered)
                                    root.hoveredId = gn.modelData.id;
                                else if (root.hoveredId === gn.modelData.id)
                                    root.hoveredId = "";
                            }
                        }
                        DragHandler {
                            id: nodeDrag
                            target: gn
                        }
                        TapHandler {
                            gesturePolicy: TapHandler.ReleaseWithinBounds
                            onTapped: if (root.service) root.service.openNote(gn.modelData.id)
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                width: parent.width - 40 * root.s
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                visible: root.laid.length === 0
                text: root.service && root.service.graphLoading ? qsTr("Reading vault…") : qsTr("No notes yet. Capture something, then link notes with [[wikilinks]] to grow the graph.")
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
            text: qsTr("Drag to pan · scroll to zoom · drag a node to move · tap to open")
            color: Theme.faint
            font.family: Theme.mono
            font.pixelSize: 9 * root.s
            font.letterSpacing: 0.5 * root.s
            elide: Text.ElideRight
        }
    }
}
