import QtQuick
import QtQuick.Shapes
import qs.theme as T

// A surface hanging from an edge above it: its top corners flare outwards into that edge and its
// bottom corners are rounded. A panel growing out of the bar is one.
//
//      edge ───────────────────────────────
//             ╲                         ╱      flare  (concave, outside the body)
//              │                       │
//              │          body         │
//              ╰───────────────────────╯       radius (convex)
//
// The flares sit outside the body, so the shape is `flare` wider than the body on each flared
// side: whatever carries one is sized to `width`, and puts its content in the `body*` rectangle.
//
// A side can instead be flush -- against a screen edge, where there is nothing to flare into --
// and is then straight, with a square bottom corner.
//
// `height` can be anything from 0 up, which is how a panel opens: animate it and the body grows
// down out of the edge. Both radii shrink with it rather than drawing arcs larger than the body,
// so the shape is well-formed at every frame of the animation; `radius` can be animated too.
Shape {
    id: root

    property color fillColor: T.Config.barBackground
    property real radius: T.Config.popupRadius
    property real flare: T.Config.popupRadius
    property bool leftFlush: false
    property bool rightFlush: false

    // An outline along the flares, the sides and -- if `outlineBottom` -- the bottom, but never the
    // top: the top is where this surface joins the one above it, and the outline is meant to run
    // around the two as one shape. Nor along a flush side, which is the screen's edge. Off at 0.
    property color outlineColor: T.Config.outline
    property real outlineOpacity: 0
    property bool outlineBottom: true
    readonly property color _stroke: Qt.rgba(outlineColor.r, outlineColor.g, outlineColor.b, outlineColor.a * outlineOpacity)

    // The body proper, within the shape.
    readonly property real bodyX: leftFlush ? 0 : flare
    readonly property real bodyWidth: Math.max(0, width - (leftFlush ? 0 : flare) - (rightFlush ? 0 : flare))

    // Never exactly zero: a zero-radius arc is a degenerate path segment, and these reach zero at
    // the closed end of every animation and on every flush side.
    readonly property real _f: Math.max(0.001, Math.min(flare, height))
    readonly property real _r: Math.max(0.001, Math.min(radius, height - _f, bodyWidth / 2))
    readonly property real _fl: leftFlush ? 0.001 : _f
    readonly property real _fr: rightFlush ? 0.001 : _f
    readonly property real _rl: leftFlush ? 0.001 : _r
    readonly property real _rr: rightFlush ? 0.001 : _r
    // Where the body's sides are.
    readonly property real _left: leftFlush ? 0 : _f
    readonly property real _right: width - (rightFlush ? 0 : _f)

    // Antialiased curves without a multisampled layer behind them.
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.fillColor
        strokeWidth: 0
        strokeColor: "transparent"

        // Clockwise from the top-left, along the edge first.
        startX: 0
        startY: 0
        PathLine { x: root.width; y: 0 }
        // Right flare: curves from the edge down onto the body's right side.
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
        // Left flare, back up into the edge.
        PathArc {
            x: 0
            y: 0
            radiusX: root._fl
            radiusY: root._fl
            direction: PathArc.Counterclockwise
        }
    }

    // --- Outline -------------------------------------------------------------------------------
    // The fill's path walked the other way round, in three pieces so the flush sides and the
    // bottom can each be left out: down the left, along the bottom, up the right.

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
