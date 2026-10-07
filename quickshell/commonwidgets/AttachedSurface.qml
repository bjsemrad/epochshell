import QtQuick
import QtQuick.Shapes
import qs.theme as T

// The ground of a panel that grows out of the bar rather than floating below it: a card whose
// top corners flare outwards into the bar's bottom edge and whose bottom corners are rounded.
//
//      bar  ───────────────────────────────
//             ╲                         ╱      flare  (concave, outside the card)
//              │                       │
//              │          card         │
//              ╰───────────────────────╯       radius (convex)
//
// The flares sit outside the card, so the shape is `flare` wider than the card on each side: a
// window carrying one is sized to `width`, and puts its content in the `body*` rectangle.
//
// `height` can be anything from 0 up, which is how a panel opens: animate it and the card grows
// down out of the bar. Both radii shrink with it rather than drawing arcs larger than the card,
// so the shape is well-formed at every frame of the animation.
Shape {
    id: root

    property color fillColor: T.Config.barBackground
    property real radius: T.Config.popupRadius
    property real flare: T.Config.popupRadius

    // The card proper, within the shape.
    readonly property real bodyX: flare
    readonly property real bodyWidth: Math.max(0, width - flare * 2)

    // Never exactly zero: a zero-radius arc is a degenerate path segment, and these reach zero at
    // the closed end of every animation.
    readonly property real _f: Math.max(0.001, Math.min(flare, height))
    readonly property real _r: Math.max(0.001, Math.min(radius, height - _f, bodyWidth / 2))

    // Antialiased curves without a multisampled layer behind them.
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.fillColor
        strokeWidth: 0
        strokeColor: "transparent"

        // Clockwise from the top-left, along the bar's bottom edge first.
        startX: 0
        startY: 0
        PathLine { x: root.width; y: 0 }
        // Right flare: curves from the bar down onto the card's right side.
        PathArc {
            x: root.width - root._f
            y: root._f
            radiusX: root._f
            radiusY: root._f
            direction: PathArc.Counterclockwise
        }
        PathLine { x: root.width - root._f; y: root.height - root._r }
        PathArc {
            x: root.width - root._f - root._r
            y: root.height
            radiusX: root._r
            radiusY: root._r
            direction: PathArc.Clockwise
        }
        PathLine { x: root._f + root._r; y: root.height }
        PathArc {
            x: root._f
            y: root.height - root._r
            radiusX: root._r
            radiusY: root._r
            direction: PathArc.Clockwise
        }
        PathLine { x: root._f; y: root._f }
        // Left flare, back up into the bar.
        PathArc {
            x: 0
            y: 0
            radiusX: root._f
            radiusY: root._f
            direction: PathArc.Counterclockwise
        }
    }
}
