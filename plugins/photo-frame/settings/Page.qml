pragma ComponentBehavior: Bound

import QtQuick
import "../../../../../Work/ryoku-arch/ryoku/hub/quickshell/Singletons" as Hub

/**
 * Photo Frame options, authored in the hub dialect so it sits natively inside
 * Ryoku Settings -> Plugins -> Photo Frame. The host loads this with `pluginApi`
 * set and calls saveSettings() on Apply; the live widget preview retunes from the
 * same pluginSettings the moment values are written.
 *
 * Note: like every plugin settings page, the relative import above points at the
 * in-repo hub Singletons for the dev live loop; when shipped, the Plugins page
 * provides the hub Theme on the import path.
 */
Column {
    id: root

    property var pluginApi
    spacing: 18

    readonly property var st: (pluginApi && pluginApi.pluginSettings) ? pluginApi.pluginSettings : ({})

    // Local, editable state seeded from the saved settings (with defaults).
    property string imagePath: (st.imagePath !== undefined) ? st.imagePath : ""
    property string style: (st.style !== undefined) ? st.style : "rounded"
    property string aspect: (st.aspect !== undefined) ? st.aspect : "4:3"
    property string caption: (st.caption !== undefined) ? st.caption : ""
    property string filter: (st.filter !== undefined) ? st.filter : "none"
    property bool shadowEnabled: (st.shadowEnabled !== undefined) ? (st.shadowEnabled === true || st.shadowEnabled === "true") : true
    property real shadowBlur: (st.shadowBlur !== undefined) ? Number(st.shadowBlur) : 0.55
    property real shadowOffset: (st.shadowOffset !== undefined) ? Number(st.shadowOffset) : 8
    property real shadowOpacity: (st.shadowOpacity !== undefined) ? Number(st.shadowOpacity) : 0.45

    function saveSettings() {
        if (!pluginApi || !pluginApi.pluginSettings)
            return;
        var s = pluginApi.pluginSettings;
        s.imagePath = imagePath.trim();
        s.style = style;
        s.aspect = aspect;
        s.caption = caption.trim();
        s.filter = filter;
        s.shadowEnabled = shadowEnabled;
        s.shadowBlur = shadowBlur;
        s.shadowOffset = shadowOffset;
        s.shadowOpacity = shadowOpacity;
        pluginApi.saveSettings();
    }

    // ---- reusable rows (hub idiom) -------------------------------------------

    component Head: Item {
        id: head
        property string text: ""
        width: root.width
        height: 16
        Text {
            id: headText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: head.text
            color: Hub.Theme.dim
            font.family: Hub.Theme.mono
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 2
        }
        Rectangle {
            anchors.left: headText.right
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 1
            color: Hub.Theme.lineSoft
        }
    }

    component FieldRow: Item {
        id: fr
        property string label: ""
        property string placeholder: ""
        property string value: ""
        signal edited(string text)
        width: root.width
        height: 38
        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: fr.label
            color: Hub.Theme.cream
            font.family: Hub.Theme.font
            font.pixelSize: 14
            font.weight: Font.Medium
        }
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 280
            height: 30
            radius: 9
            color: Hub.Theme.surfaceLo
            border.width: 1
            border.color: entry.activeFocus ? Hub.Theme.ember : Hub.Theme.line
            Behavior on border.color { ColorAnimation { duration: Hub.Theme.quick } }
            TextInput {
                id: entry
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                text: fr.value
                color: Hub.Theme.bright
                font.family: Hub.Theme.font
                font.pixelSize: 13
                clip: true
                selectByMouse: true
                onTextChanged: fr.edited(text)
                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    visible: entry.text === "" && !entry.activeFocus
                    text: fr.placeholder
                    color: Hub.Theme.faint
                    font: entry.font
                    elide: Text.ElideRight
                }
            }
        }
    }

    component ChipRow: Column {
        id: cr
        property string label: ""
        property var options: []   // [{ v, l }]
        property string value: ""
        signal picked(string v)
        width: root.width
        spacing: 9
        Text {
            text: cr.label
            color: Hub.Theme.cream
            font.family: Hub.Theme.font
            font.pixelSize: 14
            font.weight: Font.Medium
        }
        Flow {
            width: cr.width
            spacing: 7
            Repeater {
                model: cr.options
                delegate: Rectangle {
                    id: chip
                    required property var modelData
                    readonly property bool on: chip.modelData.v === cr.value
                    width: chipText.implicitWidth + 22
                    height: 28
                    radius: 8
                    color: chip.on ? Hub.Theme.ember : Hub.Theme.surfaceLo
                    border.width: 1
                    border.color: chip.on ? Hub.Theme.ember : Hub.Theme.line
                    Behavior on color { ColorAnimation { duration: Hub.Theme.quick } }
                    Text {
                        id: chipText
                        anchors.centerIn: parent
                        text: chip.modelData.l
                        color: chip.on ? Hub.Theme.onAccent : Hub.Theme.subtle
                        font.family: Hub.Theme.font
                        font.pixelSize: 12
                        font.weight: chip.on ? Font.DemiBold : Font.Medium
                    }
                    TapHandler { onTapped: cr.picked(chip.modelData.v) }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }
            }
        }
    }

    component ToggleRow: Item {
        id: tr
        property string label: ""
        property bool value: false
        signal toggled(bool v)
        width: root.width
        height: 30
        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: tr.label
            color: Hub.Theme.cream
            font.family: Hub.Theme.font
            font.pixelSize: 14
            font.weight: Font.Medium
        }
        Rectangle {
            id: sw
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 46
            height: 26
            radius: 13
            color: tr.value ? Hub.Theme.ember : Hub.Theme.surfaceLo
            border.width: 1
            border.color: tr.value ? Hub.Theme.ember : Hub.Theme.line
            Behavior on color { ColorAnimation { duration: Hub.Theme.quick } }
            Rectangle {
                width: 20
                height: 20
                radius: 10
                y: 3
                x: tr.value ? sw.width - width - 3 : 3
                color: tr.value ? Hub.Theme.onAccent : Hub.Theme.cream
                Behavior on x { NumberAnimation { duration: Hub.Theme.quick; easing.type: Hub.Theme.ease } }
            }
            TapHandler { onTapped: tr.toggled(!tr.value) }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }
    }

    component SliderRow: Item {
        id: sr
        property string label: ""
        property real from: 0
        property real to: 1
        property real value: 0
        property int decimals: 2
        signal moved(real v)
        width: root.width
        height: 34

        readonly property real frac: (to > from) ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0

        Text {
            id: lbl
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 92
            text: sr.label
            color: Hub.Theme.cream
            font.family: Hub.Theme.font
            font.pixelSize: 14
            font.weight: Font.Medium
        }
        Text {
            id: val
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            horizontalAlignment: Text.AlignRight
            text: sr.value.toFixed(sr.decimals)
            color: Hub.Theme.dim
            font.family: Hub.Theme.mono
            font.pixelSize: 12
        }
        Item {
            id: track
            anchors.left: lbl.right
            anchors.leftMargin: 12
            anchors.right: val.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: 22

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: Hub.Theme.surfaceLo
                Rectangle {
                    width: Math.round(parent.width * sr.frac)
                    height: parent.height
                    radius: 2
                    color: Hub.Theme.ember
                }
            }
            Rectangle {
                width: 14
                height: 14
                radius: 7
                anchors.verticalCenter: parent.verticalCenter
                x: Math.round((track.width - width) * sr.frac)
                color: Hub.Theme.cream
                border.width: 1
                border.color: Hub.Theme.ember
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                preventStealing: true
                cursorShape: Qt.PointingHandCursor
                function apply(mx) {
                    var f = Math.max(0, Math.min(1, mx / track.width));
                    sr.moved(sr.from + f * (sr.to - sr.from));
                }
                onPressed: (m) => apply(m.x)
                onPositionChanged: (m) => { if (pressed) apply(m.x); }
            }
        }
    }

    // ---- the page ------------------------------------------------------------

    Head { text: "PHOTO" }

    FieldRow {
        label: "Image"
        placeholder: "Path to an image, or blank for the sample"
        value: root.imagePath
        onEdited: (t) => root.imagePath = t
    }

    ChipRow {
        label: "Style"
        value: root.style
        options: [
            { v: "rounded", l: "Rounded" },
            { v: "square", l: "Square" },
            { v: "polaroid", l: "Polaroid" },
            { v: "framed", l: "Framed" },
            { v: "film", l: "Film" }
        ]
        onPicked: (v) => root.style = v
    }

    ChipRow {
        label: "Aspect"
        value: root.aspect
        options: [
            { v: "1:1", l: "Square" },
            { v: "4:3", l: "4:3" },
            { v: "3:2", l: "3:2" },
            { v: "16:9", l: "16:9" },
            { v: "3:4", l: "Portrait" }
        ]
        onPicked: (v) => root.aspect = v
    }

    FieldRow {
        label: "Caption"
        placeholder: "Shown under polaroid / framed styles"
        value: root.caption
        onEdited: (t) => root.caption = t
    }

    Head { text: "FILTER" }

    ChipRow {
        label: "Look"
        value: root.filter
        options: [
            { v: "none", l: "None" },
            { v: "mono", l: "Mono" },
            { v: "noir", l: "Noir" },
            { v: "sepia", l: "Sepia" },
            { v: "warm", l: "Warm" },
            { v: "cool", l: "Cool" },
            { v: "vivid", l: "Vivid" },
            { v: "fade", l: "Fade" }
        ]
        onPicked: (v) => root.filter = v
    }

    Head { text: "SHADOW" }

    ToggleRow {
        label: "Drop shadow"
        value: root.shadowEnabled
        onToggled: (v) => root.shadowEnabled = v
    }

    SliderRow {
        label: "Blur"
        from: 0
        to: 1
        value: root.shadowBlur
        decimals: 2
        onMoved: (v) => root.shadowBlur = v
    }

    SliderRow {
        label: "Offset"
        from: 0
        to: 28
        value: root.shadowOffset
        decimals: 0
        onMoved: (v) => root.shadowOffset = Math.round(v)
    }

    SliderRow {
        label: "Opacity"
        from: 0
        to: 1
        value: root.shadowOpacity
        decimals: 2
        onMoved: (v) => root.shadowOpacity = v
    }
}
