pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes

/**
 * The event horizon - the liquid "puddle", not a glowing orb. It reads as a
 * backlit pool of energy: a cool body that darkens toward the centre, a bright
 * meniscus where the surface meets the ring, drifting vertical caustics, a slow
 * rotating sheen and expanding ripple rings. It deepens as the address dials
 * (`progress`) and only animates while `live` and `open`, so a hidden gate is
 * free.
 */
Item {
    id: eh

    property real diameter: 200
    property color energy: "#3fb8ff"
    property bool open: true
    property real progress: 1
    property bool live: true

    width: diameter
    height: diameter

    readonly property real r: diameter / 2
    readonly property bool animating: live && open

    opacity: open ? 1 : (0.08 + 0.4 * progress)
    Behavior on opacity { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }

    // pool body: brightest just off the top (light spills in from above the
    // gate), sinking to a deep core - the opposite of a centred glow orb.
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: eh.r; centerY: eh.r * 0.78; centerRadius: eh.r * 1.15
                focalX: eh.r; focalY: eh.r * 0.62
                GradientStop { position: 0.0; color: Qt.lighter(eh.energy, 1.35) }
                GradientStop { position: 0.34; color: eh.energy }
                GradientStop { position: 0.72; color: Qt.darker(eh.energy, 1.85) }
                GradientStop { position: 1.0; color: Qt.rgba(0.02, 0.08, 0.16, 1) }
            }
            startX: eh.diameter; startY: eh.r
            PathAngleArc { centerX: eh.r; centerY: eh.r; radiusX: eh.r; radiusY: eh.r; startAngle: 0; sweepAngle: 360 }
        }
    }

    // drifting vertical caustics - thin light columns that wander, like a
    // disturbed water surface catching light.
    Item {
        anchors.fill: parent
        clip: true
        Repeater {
            model: 3
            delegate: Rectangle {
                id: caustic
                required property int index
                readonly property real baseX: eh.diameter * (0.3 + caustic.index * 0.22)
                width: eh.diameter * (0.10 + caustic.index * 0.03)
                height: eh.diameter * 1.2
                x: baseX; y: -eh.diameter * 0.1
                rotation: 8 - caustic.index * 6
                opacity: eh.open ? 0.16 : 0
                Behavior on opacity { NumberAnimation { duration: 500 } }
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.5) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                SequentialAnimation on x {
                    running: eh.animating; loops: Animation.Infinite
                    NumberAnimation { from: caustic.baseX - eh.diameter * 0.06; to: caustic.baseX + eh.diameter * 0.06
                        duration: 3200 + caustic.index * 900; easing.type: Easing.InOutSine }
                    NumberAnimation { to: caustic.baseX - eh.diameter * 0.06
                        duration: 3200 + caustic.index * 900; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    // rotating sheen.
    Shape {
        id: sheen
        anchors.fill: parent
        opacity: eh.open ? 0.16 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 500 } }
        preferredRendererType: Shape.CurveRenderer
        transform: Rotation { origin.x: eh.r; origin.y: eh.r; angle: sheen.spin }
        property real spin: 0
        RotationAnimation on spin { from: 0; to: 360; duration: 11000; loops: Animation.Infinite; running: eh.animating }
        ShapePath {
            strokeColor: "transparent"
            fillGradient: ConicalGradient {
                centerX: eh.r; centerY: eh.r; angle: 0
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0) }
                GradientStop { position: 0.16; color: Qt.rgba(1, 1, 1, 0.4) }
                GradientStop { position: 0.32; color: Qt.rgba(1, 1, 1, 0) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
            }
            startX: eh.diameter; startY: eh.r
            PathAngleArc { centerX: eh.r; centerY: eh.r; radiusX: eh.r; radiusY: eh.r; startAngle: 0; sweepAngle: 360 }
        }
    }

    // bright meniscus where the surface meets the ring.
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: eh.r; centerY: eh.r; centerRadius: eh.r
                focalX: eh.r; focalY: eh.r
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.80; color: "transparent" }
                GradientStop { position: 0.92; color: Qt.rgba(Qt.lighter(eh.energy, 1.6).r, Qt.lighter(eh.energy, 1.6).g, Qt.lighter(eh.energy, 1.6).b, 0.7) }
                GradientStop { position: 1.0; color: "transparent" }
            }
            startX: eh.diameter; startY: eh.r
            PathAngleArc { centerX: eh.r; centerY: eh.r; radiusX: eh.r; radiusY: eh.r; startAngle: 0; sweepAngle: 360 }
        }
    }

    // expanding ripple rings.
    Repeater {
        model: 3
        delegate: Rectangle {
            id: ring
            required property int index
            anchors.centerIn: parent
            width: eh.diameter * ring.f; height: width; radius: width / 2
            color: "transparent"
            border.width: Math.max(1, eh.diameter * 0.006)
            border.color: Qt.rgba(1, 1, 1, ring.a)
            property real f: 0.2
            property real a: 0
            SequentialAnimation {
                running: eh.animating; loops: Animation.Infinite
                PauseAnimation { duration: ring.index * 1500 }
                ParallelAnimation {
                    NumberAnimation { target: ring; property: "f"; from: 0.24; to: 0.98; duration: 4200; easing.type: Easing.OutCubic }
                    SequentialAnimation {
                        NumberAnimation { target: ring; property: "a"; from: 0.0; to: 0.22; duration: 900 }
                        NumberAnimation { target: ring; property: "a"; from: 0.22; to: 0.0; duration: 3300 }
                    }
                }
            }
        }
    }
}
