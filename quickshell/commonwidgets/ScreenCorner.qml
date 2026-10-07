import QtQuick
import QtQuick.Shapes
import qs.theme as T

// A concave fillet under one end of the bar: the bar's colour, curving from the bar's bottom edge
// down into the screen edge, so the desktop below looks like it has a rounded top corner.
//
// Drawn for the left end; `mirrored` flips it for the right.
//
//      bar  ─────────            ───────── bar
//           █▀                          ▀█
//           ▌        (left)    (right)   ▐
Shape {
    id: root

    property bool mirrored: false
    property real radius: T.Config.cornerRadius
    property color fillColor: T.Config.barBackground

    width: radius
    height: radius
    preferredRendererType: Shape.CurveRenderer

    // The filled part is the corner square less a quarter circle centred on its far corner.
    ShapePath {
        fillColor: root.fillColor
        strokeWidth: 0
        strokeColor: "transparent"

        startX: root.mirrored ? root.radius : 0
        startY: 0
        // Down the screen edge.
        PathLine { x: root.mirrored ? root.radius : 0; y: root.radius }
        // Back up to the bar along the curve.
        PathArc {
            x: root.mirrored ? 0 : root.radius
            y: 0
            radiusX: root.radius
            radiusY: root.radius
            direction: root.mirrored ? PathArc.Counterclockwise : PathArc.Clockwise
        }
    }
}
