pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

/**
 * Wallhaven as a desktop tile. The host sets `pluginApi`, `screen`, `s`,
 * `widthBudget` and `active`; the view lays out to `widthBudget` and reports its
 * own size back. Results, query, filters and page all live in the service
 * (pluginApi.mainInstance), so they survive the tile being dragged or hidden.
 *
 * `editing` is read by the wallpaper-layer host: while the search field holds
 * focus the layer takes the keyboard on demand, then hands it back on blur.
 */
Item {
    id: root

    property var pluginApi
    property var screen
    property bool active: true
    property string density: "compact"
    property real s: 1
    property real widthBudget: 0

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property real contentW: widthBudget > 0 ? widthBudget : 360 * s
    readonly property bool editing: search.editing

    // nearest common wallhaven aspect for this monitor, for the Fit chip. empty
    // when the host did not hand us a screen, which hides the chip.
    readonly property string fitRatio: {
        if (!screen || !screen.width || !screen.height)
            return "";
        const a = screen.width / screen.height;
        const table = [["9x16", 0.5625], ["10x16", 0.625], ["1x1", 1], ["5x4", 1.25],
            ["4x3", 1.333], ["3x2", 1.5], ["16x10", 1.6], ["16x9", 1.777],
            ["21x9", 2.333], ["32x9", 3.555]];
        let best = "16x9", bd = 1e9;
        for (const [r, ar] of table) {
            const d = Math.abs(ar - a);
            if (d < bd) { bd = d; best = r; }
        }
        return best;
    }

    implicitWidth: contentW
    implicitHeight: body.implicitHeight

    function _autoSearch() {
        if (active && service && (service.results?.length ?? 0) === 0 && !service.searching)
            service.searchLatest("");
    }
    onServiceChanged: _autoSearch()
    Component.onCompleted: Qt.callLater(_autoSearch)

    // Let go of the keyboard if the search is focused but idle, so a tile that
    // was clicked into and then left alone never holds the keyboard hostage.
    Timer {
        id: idleBlur
        interval: 6000
        running: search.input.activeFocus
        onTriggered: search.input.focus = false
    }
    Connections {
        target: search.input
        function onTextChanged() { if (search.input.activeFocus) idleBlur.restart(); }
    }

    Column {
        id: body
        width: root.contentW
        spacing: 12 * root.s

        // masthead: wordmark on the left, pager on the right.
        Item {
            width: root.contentW
            implicitHeight: 22 * root.s
            MicroLabel {
                label: qsTr("Wallhaven"); s: root.s
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 9 * root.s
                WhStep {
                    s: root.s; glyph: "chevron-left"
                    enabled: (root.service?.page ?? 1) > 1 && !(root.service?.searching ?? false)
                    onActivated: root.service?.previousPage()
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: `${root.service?.page ?? 1}`
                    color: (root.service?.searching ?? false) ? Theme.brand : Theme.subtle
                    font.family: Theme.mono
                    font.pixelSize: 12 * root.s
                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                }
                WhStep {
                    s: root.s; glyph: "chevron-right"
                    enabled: !(root.service?.searching ?? false)
                    onActivated: root.service?.nextPage()
                }
            }
        }

        // search.
        Rectangle {
            width: root.contentW
            implicitHeight: 44 * root.s
            radius: Motion.rSmall * root.s
            color: Theme.tileBg
            border.width: 1
            border.color: search.input.activeFocus ? Theme.brand : Theme.border
            Behavior on border.color { ColorAnimation { duration: Motion.fast } }
            SearchField {
                id: search
                anchors.fill: parent
                anchors.leftMargin: 12 * root.s
                anchors.rightMargin: 12 * root.s
                s: root.s
                kanji: "力"
                placeholder: qsTr("Search wallhaven")
                text: root.service?.query ?? ""
                readonly property bool editing: input.activeFocus
                onAccepted: { root.service?.searchLatest(search.text); input.focus = false; }
                onDismissed: input.focus = false
            }
        }

        // filters: sort on the left, Fit toggle on the right.
        Item {
            width: root.contentW
            implicitHeight: 20 * root.s
            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16 * root.s
                WhChip {
                    s: root.s; label: qsTr("Latest")
                    on: (root.service?.topRange ?? "") === ""
                    onActivated: root.service?.searchTop("")
                }
                WhChip {
                    s: root.s; label: qsTr("Top week")
                    on: (root.service?.topRange ?? "") === "1w"
                    onActivated: root.service?.searchTop("1w")
                }
                WhChip {
                    s: root.s; label: qsTr("Top month")
                    on: (root.service?.topRange ?? "") === "1M"
                    onActivated: root.service?.searchTop("1M")
                }
            }
            WhChip {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: root.fitRatio.length > 0
                s: root.s; label: qsTr("Fit screen")
                on: (root.service?.ratios ?? "") !== ""
                onActivated: root.service?.setRatios(on ? "" : root.fitRatio)
            }
        }

        // result grid.
        WhGrid {
            width: root.contentW; s: root.s; service: root.service
            onApply: (item) => { search.input.focus = false; root.service?.setAsWallpaper(item); }
            onWeb: (item) => root.service?.openInWeb(item)
        }

        // transient status (downloading / set / error).
        Item {
            width: root.contentW
            implicitHeight: (root.service?.status ?? "").length > 0 ? 14 * root.s : 0
            visible: implicitHeight > 0
            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 7 * root.s
                Rectangle {
                    width: 5 * root.s; height: width; radius: 1 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    color: (root.service?.downloading ?? false) ? Theme.brand : Theme.faint
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: (root.service?.status ?? "").toUpperCase()
                    color: Theme.faint
                    font.family: Theme.mono
                    font.pixelSize: 9.5 * root.s
                    font.letterSpacing: 1.4 * root.s
                }
            }
        }
    }

    // ---- pager step ----------------------------------------------------------

    component WhStep: Item {
        id: step
        property real s: 1
        property string glyph: ""
        property bool enabled: true
        signal activated()
        implicitWidth: 18 * s
        implicitHeight: 18 * s
        opacity: enabled ? 1 : 0.3
        GlyphIcon {
            anchors.centerIn: parent
            width: 14 * step.s; height: width
            name: step.glyph
            color: sma.containsMouse && step.enabled ? Theme.brand : Theme.iconDim
        }
        MouseArea {
            id: sma
            anchors.fill: parent
            enabled: step.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: step.activated()
        }
    }

    // ---- filter chip: text with a thin vermilion tick when active ------------

    component WhChip: Item {
        id: chip
        property real s: 1
        property string label: ""
        property bool on: false
        signal activated()
        implicitWidth: lbl.implicitWidth
        implicitHeight: 20 * s
        Text {
            id: lbl
            anchors.top: parent.top
            text: chip.label
            color: chip.on ? Theme.bright : (cma.containsMouse ? Theme.subtle : Theme.faint)
            font.family: Theme.font
            font.pixelSize: 12 * chip.s
            font.weight: chip.on ? Font.DemiBold : Font.Medium
            Behavior on color { ColorAnimation { duration: Motion.fast } }
        }
        Rectangle {
            anchors.top: lbl.bottom
            anchors.topMargin: 4 * chip.s
            anchors.left: lbl.left
            width: lbl.implicitWidth
            height: 1.5 * chip.s
            radius: 1
            color: Theme.brand
            opacity: chip.on ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
        }
        MouseArea {
            id: cma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.activated()
        }
    }

    // ---- result grid ---------------------------------------------------------

    component WhGrid: Item {
        id: g
        property real s: 1
        property var service
        readonly property int columns: 3
        readonly property int maxRows: 3
        signal apply(var item)
        signal web(var item)

        readonly property var items: {
            const r = g.service?.results ?? [];
            const max = g.columns * g.maxRows;
            return r.length > max ? r.slice(0, max) : r;
        }
        readonly property real gap: 8 * s
        readonly property real cellW: (width - gap * (columns - 1)) / columns
        readonly property real cellH: Math.round(cellW * 0.62)
        readonly property int rows: Math.max(1, Math.ceil(items.length / columns))
        readonly property bool empty: items.length === 0

        implicitHeight: empty ? 132 * s : rows * cellH + (rows - 1) * gap

        Grid {
            anchors.fill: parent
            visible: !g.empty
            columns: g.columns
            rowSpacing: g.gap
            columnSpacing: g.gap
            Repeater {
                model: g.items
                delegate: WhCell {
                    required property var modelData
                    s: g.s
                    item: modelData
                    width: g.cellW
                    height: g.cellH
                    setting: (g.service?.downloadingId ?? "") === (modelData?.id ?? "_")
                    onApply: g.apply(modelData)
                    onWeb: g.web(modelData)
                }
            }
        }

        // dim the grid while a fetch is in flight, so paging reads as a load.
        Rectangle {
            anchors.fill: parent
            visible: opacity > 0
            radius: Motion.rSmall * g.s
            color: Qt.rgba(0, 0, 0, 0.35)
            opacity: (g.service?.searching ?? false) && !g.empty ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
        }

        // empty / busy / error.
        Rectangle {
            anchors.fill: parent
            visible: g.empty
            radius: Motion.rTile * g.s
            color: "transparent"
            border.width: 1
            border.color: Theme.border
            Column {
                anchors.centerIn: parent
                spacing: 8 * g.s
                GlyphIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 22 * g.s; height: width
                    name: (g.service?.searching ?? false) ? "sun" : "image"
                    color: Theme.faint
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: (g.service?.searching ?? false) ? qsTr("Searching")
                        : (g.service?.error || qsTr("No wallpapers"))
                    color: Theme.faint
                    font.family: Theme.font
                    font.pixelSize: 12 * g.s
                }
            }
        }
    }

    // ---- one thumbnail -------------------------------------------------------

    component WhCell: Rectangle {
        id: cell
        property real s: 1
        property var item
        property bool setting: false
        signal apply()
        signal web()

        radius: Motion.rSmall * s
        color: Theme.tileBg
        border.width: 1
        border.color: cma.containsMouse ? Theme.brand : Theme.border
        clip: true
        Behavior on border.color { ColorAnimation { duration: Motion.fast } }

        Image {
            anchors.fill: parent
            anchors.margins: 1
            asynchronous: true
            cache: true
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(Math.ceil(cell.width * 2), Math.ceil(cell.height * 2))
            source: cell.item?.thumb ?? ""
        }

        // hover: dim plus the resolution.
        Rectangle {
            anchors.fill: parent
            visible: cma.containsMouse && !cell.setting
            color: Qt.rgba(0, 0, 0, 0.32)
            Text {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 5 * cell.s
                text: cell.item?.resolution ?? ""
                color: Theme.cream
                font.family: Theme.mono
                font.pixelSize: 9.5 * cell.s
            }
        }

        // setting feedback: dim plus a turning mark.
        Rectangle {
            anchors.fill: parent
            visible: cell.setting
            color: Qt.rgba(0, 0, 0, 0.5)
            GlyphIcon {
                id: spin
                anchors.centerIn: parent
                width: 18 * cell.s; height: width
                name: "sun"
                color: Theme.brand
                RotationAnimator {
                    target: spin; running: cell.setting
                    from: 0; to: 360; duration: Motion.heat; loops: Animation.Infinite
                }
            }
        }

        MouseArea {
            id: cma
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: (e) => { if (e.button === Qt.RightButton) cell.web(); else cell.apply(); }
        }
    }
}
