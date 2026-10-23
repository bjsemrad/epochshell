import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import qs.theme as T

Shape {
    id: root

    property color fillColor: T.Config.barBackground
    property real radius: T.Config.popupRadius
    property real flare: T.Config.popupRadius
    property bool leftFlush: false
    property bool rightFlush: false

    property color outlineColor: T.Config.outline
    property real outlineOpacity: 0
    property bool outlineBottom: true
    property real outlineFade: 0
    readonly property color _stroke: Qt.rgba(outlineColor.r, outlineColor.g, outlineColor.b, outlineColor.a * outlineOpacity)

    readonly property real bodyX: leftFlush ? 0 : flare
    readonly property real bodyWidth: Math.max(0, width - (leftFlush ? 0 : flare) - (rightFlush ? 0 : flare))

    // Never exactly zero: a zero-radius arc is a degenerate path segment.
    readonly property real _f: Math.max(0.001, Math.min(flare, height))
    readonly property real _r: Math.max(0.001, Math.min(radius, height - _f, bodyWidth / 2))
    readonly property real _fl: leftFlush ? 0.001 : _f
    readonly property real _fr: rightFlush ? 0.001 : _f
    readonly property real _rl: leftFlush ? 0.001 : _r
    readonly property real _rr: rightFlush ? 0.001 : _r
    readonly property real _left: leftFlush ? 0 : _f
    readonly property real _right: width - (rightFlush ? 0 : _f)

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.fillColor
        strokeWidth: 0
        strokeColor: "transparent"

        startX: 0
        startY: 0
        PathLine { x: root.width; y: 0 }
        PathArc {
            x: root._right
            y: root._fr
            radiusX: root._fr
            radiusY: root._fr
            direction: PathArc.Counterclockwise
        }
        PathLine { x: root._right; y: root.height - root._rr }
        PathArc {
            x: root._right - root._rr
            y: root.height
            radiusX: root._rr
            radiusY: root._rr
            direction: PathArc.Clockwise
        }
        PathLine { x: root._left + root._rl; y: root.height }
        PathArc {
            x: root._left
            y: root.height - root._rl
            radiusX: root._rl
            radiusY: root._rl
            direction: PathArc.Clockwise
        }
        PathLine { x: root._left; y: root._fl }
        PathArc {
            x: 0
            y: 0
            radiusX: root._fl
            radiusY: root._fl
            direction: PathArc.Counterclockwise
        }
    }

    Shape {
        id: outlineShape
        // A pixel past the bottom and right: a layer only holds its item's bounds, and the bottom
        // line is centred on the edge.
        anchors.fill: parent
        anchors.bottomMargin: -1
        anchors.rightMargin: -1
        preferredRendererType: Shape.CurveRenderer
        layer.enabled: root.outlineFade > 0 && root.outlineOpacity > 0
        layer.effect: OpacityMask {
            maskSource: outlineFadeMask
        }

        ShapePath {
            fillColor: "transparent"
            strokeWidth: 1
            strokeColor: root.outlineOpacity > 0 && !root.leftFlush ? root._stroke : "transparent"
            startX: 0
            startY: 0
            PathArc {
                x: root._left
                y: root._fl
                radiusX: root._fl
                radiusY: root._fl
                direction: PathArc.Clockwise
            }
            PathLine { x: root._left; y: root.height - root._rl }
            PathArc {
                x: root._left + root._rl
                y: root.height
                radiusX: root._rl
                radiusY: root._rl
                direction: PathArc.Counterclockwise
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeWidth: 1
            strokeColor: root.outlineOpacity > 0 && root.outlineBottom ? root._stroke : "transparent"
            startX: root._left + root._rl
            startY: root.height
            PathLine { x: root._right - root._rr; y: root.height }
        }

        ShapePath {
            fillColor: "transparent"
            strokeWidth: 1
            strokeColor: root.outlineOpacity > 0 && !root.rightFlush ? root._stroke : "transparent"
            startX: root._right - root._rr
            startY: root.height
            PathArc {
                x: root._right
                y: root.height - root._rr
                radiusX: root._rr
                radiusY: root._rr
                direction: PathArc.Counterclockwise
            }
            PathLine { x: root._right; y: root._fr }
            PathArc {
                x: root.width
                y: 0
                radiusX: root._fr
                radiusY: root._fr
                direction: PathArc.Clockwise
            }
        }
    }

    Rectangle {
        id: outlineFadeMask
        width: outlineShape.width
        height: outlineShape.height
        visible: false
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "transparent"
            }
            GradientStop {
                position: outlineShape.height > 0 ? Math.min(1, root.outlineFade / outlineShape.height) : 1
                color: "black"
            }
        }
    }
}
