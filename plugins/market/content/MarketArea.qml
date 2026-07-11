pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

/**
 * Area face: the same header as Line, but the plot is a trend-tinted line over a
 * vertical gradient fill that fades to transparent at the floor - green when up,
 * vermilion when down. The whole plot reveals with a left-to-right clip sweep on
 * new data, gated on visibility. Draws its own surface.
 */
Item {
  id: root

  property var service: null
  property real s: 1
  property real cw: 360

  readonly property real pad: 16 * s
  readonly property real axisW: 30 * s
  readonly property real xAxisH: 13 * s
  readonly property bool grid: root.service ? root.service.showGrid : true
  readonly property var vals: root.service ? root.service.spark : []
  readonly property int n: Array.isArray(vals) ? vals.length : 0
  readonly property real lo: root.service ? root.service.sparkMin : 0
  readonly property real hi: root.service ? root.service.sparkMax : 1
  readonly property real span: (hi - lo) > 0 ? (hi - lo) : 1
  readonly property color tint: root.service ? root.service.trendColor : Theme.brand

  implicitWidth: cw
  implicitHeight: surface.implicitHeight

  function ptX(i) { return i / Math.max(1, root.n - 1) * plot.width; }
  function ptY(v) { return (1 - (v - root.lo) / root.span) * plot.height; }
  function linePts() {
    var out = [];
    for (var i = 0; i < root.n; i++) out.push(Qt.point(ptX(i), ptY(root.vals[i])));
    return out;
  }
  // line points plus the two floor corners, closed, for the gradient fill.
  function fillPts() {
    var out = root.linePts();
    if (out.length < 2) return out;
    out.push(Qt.point(plot.width, plot.height));
    out.push(Qt.point(0, plot.height));
    return out;
  }

  property real progress: 0
  function reveal() {
    drawAnim.stop();
    if (visible && root.n > 1) { progress = 0; drawAnim.start(); } else progress = 1;
  }
  onNChanged: reveal()
  Component.onCompleted: reveal()
  NumberAnimation {
    id: drawAnim
    target: root; property: "progress"; from: 0; to: 1
    duration: Motion.shapeshift; easing.type: Easing.OutCubic
  }

  Rectangle {
    id: surface
    width: root.cw
    implicitHeight: meta.y + meta.height + root.pad
    radius: 18 * root.s
    border.width: 1
    border.color: Theme.border
    gradient: Gradient {
      GradientStop { position: 0.0; color: Theme.cardTop }
      GradientStop { position: 1.0; color: Theme.cardBot }
    }

    CornerTicks { anchors.fill: parent; s: root.s }

    Column {
      id: header
      x: root.pad
      y: root.pad
      width: parent.width - root.pad * 2
      spacing: 5 * root.s

      // eyebrow: instrument name left, timeframe chips right.
      Item {
        width: parent.width
        height: Math.max(eyebrow.implicitHeight, chips.implicitHeight)
        MicroLabel {
          id: eyebrow
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          label: root.service && root.service.name.length > 0 ? root.service.name : qsTr("Market")
          s: root.s
        }
        WindowChips {
          id: chips
          anchors.right: parent.right
          anchors.rightMargin: 30 * root.s
          anchors.verticalCenter: parent.verticalCenter
          service: root.service
          s: root.s
        }
      }

      Row {
        spacing: 9 * root.s
        PriceText { anchors.bottom: parent.bottom; service: root.service; s: root.s; pixelSize: 26 * root.s }
        ChangeBadge { anchors.bottom: parent.bottom; anchors.bottomMargin: 3 * root.s; service: root.service; s: root.s }
      }
    }

    Item {
      id: plot
      x: root.pad + root.axisW
      y: header.y + header.height + 12 * root.s
      width: parent.width - root.pad * 2 - root.axisW
      height: 118 * root.s

      // faint grid (service.showGrid), same lattice the Line face draws.
      Repeater {
        model: root.grid ? 4 : 0
        Rectangle {
          required property int index
          width: plot.width; height: 1
          y: plot.height * (index / 3)
          color: Theme.hair
        }
      }
      Repeater {
        model: root.grid ? 5 : 0
        Rectangle {
          required property int index
          width: 1; height: plot.height
          x: plot.width * (index / 4)
          color: Theme.hair
          opacity: 0.6
        }
      }

      Item {
        width: plot.width * root.progress
        height: plot.height
        clip: root.progress < 1

        Shape {
          width: plot.width; height: plot.height
          antialiasing: true
          preferredRendererType: Shape.CurveRenderer
          visible: root.n > 1

          // gradient fill under the line.
          ShapePath {
            strokeColor: "transparent"
            PathPolyline { path: root.fillPts() }
            fillGradient: LinearGradient {
              x1: 0; y1: 0; x2: 0; y2: plot.height
              GradientStop { position: 0.0; color: Qt.alpha(root.tint, 0.42) }
              GradientStop { position: 1.0; color: Qt.alpha(root.tint, 0.0) }
            }
          }
          // the line on top.
          ShapePath {
            strokeColor: root.tint
            strokeWidth: 2.4 * root.s
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: root.linePts() }
          }
        }
      }

      // end-dot marker.
      Rectangle {
        visible: root.n > 1
        width: 9 * root.s; height: 9 * root.s; radius: width / 2
        color: Theme.cardBot
        border.width: 2 * root.s
        border.color: root.tint
        x: root.ptX(root.n - 1) - width / 2
        y: root.ptY(root.vals[root.n - 1]) - height / 2
        opacity: root.progress >= 0.98 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Motion.fast } }
      }

      // hover readout: nearest sample's price + time (hover-only, drag-safe).
      Crosshair {
        anchors.fill: parent
        visible: root.n > 1
        service: root.service
        s: root.s
        values: root.vals
        times: root.service ? root.service.times : []
        lo: root.lo
        hi: root.hi
      }

      // first-fetch / failed-with-no-data: the empty grid becomes a skeleton.
      FacePlaceholder {
        anchors.fill: parent
        visible: root.n < 2
        service: root.service
        s: root.s
      }
    }

    // Y axis: price ticks.
    Repeater {
      model: 4
      Text {
        required property int index
        width: root.axisW - 5 * root.s
        visible: root.n > 1
        horizontalAlignment: Text.AlignRight
        x: 0
        y: plot.y + plot.height * (index / 3) - implicitHeight / 2
        text: root.service ? root.service.fmtCompact(root.lo + root.span * (1 - index / 3), root.span) : ""
        color: Theme.faint
        font.family: Theme.mono
        font.pixelSize: 9 * root.s
        font.weight: Font.Medium
      }
    }
    // X axis: time ticks along the bottom.
    Repeater {
      model: 5
      Text {
        required property int index
        readonly property real ft: index / 4
        readonly property int di: Math.round(ft * (root.n - 1))
        horizontalAlignment: Text.AlignHCenter
        width: 40 * root.s
        x: plot.x + ft * plot.width - width / 2
        y: plot.y + plot.height + 3 * root.s
        text: (root.service && root.n > 1 && di >= 0 && di < (root.service.times ? root.service.times.length : 0)) ? root.service.fmtTime(root.service.times[di]) : ""
        color: Theme.faint
        font.family: Theme.mono
        font.pixelSize: 9 * root.s
        font.weight: Font.Medium
      }
    }

    // provenance footer: session state, as-of stamp, stale flag.
    MetaLine {
      id: meta
      x: root.pad
      y: plot.y + plot.height + root.xAxisH + 6 * root.s
      service: root.service
      s: root.s
    }
  }
}
