pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// Cassette deck face: a dark inset shell holding two reels that turn in
// lockstep only while playing. A single `angle` property is driven by one
// NumberAnimation; both reels read from it, so the spokes can never drift
// out of phase. Above the shell, a J-card label band carries the 力 MEDIA
// eyebrow with the title + artist marquees; below it, Transport renders the
// deck buttons. Own surface (cardTop→cardBot gradient) + CornerTicks.
Item {
  id: root

  property var service
  property real s: 1
  property real cw: 360

  implicitWidth: cw
  implicitHeight: Math.round(cw * 0.66)

  readonly property color accent: root.service ? root.service.accentColor() : Theme.brand

  // Single rotation source - both hubs sample this, so they stay in lockstep
  // and the value holds (= reels freeze) the moment the animation pauses.
  property real angle: 0
  NumberAnimation on angle {
    from: 0
    to: 360
    duration: 4000
    loops: Animation.Infinite
    running: root.visible && (root.service?.playing ?? false)
  }

  // ---- Surface --------------------------------------------------------------
  Rectangle {
    anchors.fill: parent
    radius: 16 * root.s
    gradient: Gradient {
      GradientStop { position: 0.0; color: Theme.cardTop }
      GradientStop { position: 1.0; color: Theme.cardBot }
    }
  }

  // ---- J-card label band ----------------------------------------------------
  Rectangle {
    id: jcard
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.leftMargin: 18 * root.s
    anchors.rightMargin: 18 * root.s
    anchors.topMargin: 14 * root.s
    height: label.implicitHeight + 14 * root.s
    radius: 5 * root.s
    color: Qt.alpha(Theme.tileBg, 0.55)
    border.width: 1
    border.color: Qt.alpha(Theme.hair, 0.6)
  }

  Column {
    id: label
    anchors.left: jcard.left
    anchors.right: jcard.right
    anchors.top: jcard.top
    anchors.leftMargin: 10 * root.s
    anchors.rightMargin: 10 * root.s
    anchors.topMargin: 7 * root.s
    spacing: 2 * root.s

    Row {
      spacing: 7 * root.s
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "力"
        color: Theme.brand
        font.family: Theme.fontJp
        font.weight: Font.Medium
        font.pixelSize: 13 * root.s
      }
      MicroLabel {
        anchors.verticalCenter: parent.verticalCenter
        label: "MEDIA"
        s: root.s
      }
    }

    Marquee {
      anchors.left: parent.left
      anchors.right: parent.right
      text: root.service?.title ?? ""
      color: Theme.cream
      pixelSize: 15 * root.s
      weight: Font.DemiBold
      active: root.visible && (root.service?.playing ?? false)
    }
    Marquee {
      anchors.left: parent.left
      anchors.right: parent.right
      text: root.service?.artist ?? ""
      color: Theme.dim
      pixelSize: 11 * root.s
      active: root.visible && (root.service?.playing ?? false)
      visible: text.length > 0
    }
  }

  // ---- Deck buttons (transport row) ----------------------------------------
  Transport {
    id: transport
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 14 * root.s
    service: root.service
    s: root.s
    accent: root.accent
  }

  // ---- Cassette shell -------------------------------------------------------
  Rectangle {
    id: shell
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: 22 * root.s
    anchors.rightMargin: 22 * root.s
    anchors.top: jcard.bottom
    anchors.topMargin: 12 * root.s
    anchors.bottom: transport.top
    anchors.bottomMargin: 12 * root.s

    radius: 10 * root.s
    color: Qt.darker(Theme.tileBg, 1.35)
    border.width: 1
    border.color: Qt.alpha(Theme.border, 0.7)

    readonly property real hubD: Math.round(root.cw * 0.18)
    readonly property real hubR: hubD / 2
    readonly property real leftCX: width * 0.28
    readonly property real rightCX: width * 0.72

    // Tape span: two thin lines bridging the hubs at the level of the heads.
    Rectangle {
      x: shell.leftCX
      width: shell.rightCX - shell.leftCX
      y: shell.height / 2 - Math.round(shell.hubR * 0.22)
      height: Math.max(1, 1 * root.s)
      color: Qt.alpha(Theme.cream, 0.32)
    }
    Rectangle {
      x: shell.leftCX
      width: shell.rightCX - shell.leftCX
      y: shell.height / 2 + Math.round(shell.hubR * 0.22)
      height: Math.max(1, 1 * root.s)
      color: Qt.alpha(Theme.cream, 0.18)
    }

    Reel {
      diameter: shell.hubD
      anchors.verticalCenter: shell.verticalCenter
      x: shell.leftCX - shell.hubR
      angle: root.angle
      accent: root.accent
      s: root.s
    }
    Reel {
      diameter: shell.hubD
      anchors.verticalCenter: shell.verticalCenter
      x: shell.rightCX - shell.hubR
      angle: root.angle
      accent: root.accent
      s: root.s
    }
  }

  // Inline reel: hub ring with N radiating spokes and a coloured centre cap.
  // The whole rotor is rotated by the shared `angle`; spokes use the default
  // Item.Center transformOrigin so they fan out from the hub centre.
  component Reel: Item {
    id: reel

    property real diameter: 60
    property real angle: 0
    property color accent: Theme.brand
    property real s: 1

    width: diameter
    height: diameter

    // Outer hub ring
    Rectangle {
      anchors.fill: parent
      radius: width / 2
      color: Qt.darker(Theme.tileBg, 1.7)
      border.width: 1
      border.color: Qt.alpha(Theme.border, 0.85)
    }

    // Rotor: the only thing that turns; angle holds when the animation stops.
    Item {
      id: rotor
      anchors.fill: parent
      transform: Rotation {
        origin.x: rotor.width / 2
        origin.y: rotor.height / 2
        angle: reel.angle
      }

      Repeater {
        model: 3
        delegate: Rectangle {
          required property int index
          anchors.centerIn: parent
          width: Math.max(1, 1.5 * reel.s)
          height: rotor.height * 0.74
          color: Qt.alpha(Theme.cream, 0.32)
          rotation: index * 60  // 3 rects × 2 arms = 6 spokes
        }
      }

      // Centre cap: the accent-coloured spindle hub.
      Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.3
        height: width
        radius: width / 2
        color: reel.accent
        border.width: 1
        border.color: Qt.alpha(Theme.border, 0.5)
      }
    }
  }

  CornerTicks {
    anchors.fill: parent
    anchors.margins: 9 * root.s
    s: root.s
  }
}
