import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.theme as T

// A panel opened from the bar.
//
// Two looks. By default the panel is *attached*: it hangs flush from the bar's bottom edge in the
// bar's own colour, its top corners flaring out into the bar, and it opens by growing down out of
// it -- one surface that happens to have a panel in it, rather than a card floating below. A panel
// that sets its own anchoring (the theme picker, flying sideways out of the system menu) is not
// next to the bar at all, and keeps the floating card: rounded all round, bordered, faded in.
PopupWindow {
    id: popup
    visible: false
    color: "transparent"

    property var anim_CURVE_SMOOTH_SLIDE: [0.23, 1, 0.32, 1, 1, 1]

    default property alias content: contentLayout.data

    property int padding: T.Config.popupPadding
    property int bottomPadding: padding * 2
    property real popupWidth: 1

    // A ring of transparent space around the floating card.
    //
    // On a fractionally scaled output -- 1.333 on a 2880x1920 panel run at 2160x1440 -- the
    // window's last physical column and row can be rounded away, and they take the card's 1px
    // border with them: the panel renders with no right edge, or no bottom edge, depending on how
    // its size happens to round. Insetting the card by a whole logical pixel means the border is
    // never the outermost pixel, so there is nothing at the edge left to lose. (An attached panel
    // has no border to lose, and its top edge must touch the bar, so it has none.)
    readonly property int edgeInset: attached ? 0 : 1

    // Attached unless the anchoring below is overridden -- a panel placed somewhere else is not
    // touching the bar, and flares drawn into thin air would look like a mistake.
    readonly property bool attached: anchorEdges === (Edges.Left | Edges.Bottom) && anchorRectY < 0

    // The flares reach outside the card, so an attached window is that much wider on each side.
    readonly property real flare: attached ? T.Config.popupRadius : 0

    readonly property real cardHeight: contentLayout.implicitHeight + padding + bottomPadding

    implicitWidth: popupWidth + flare * 2 + edgeInset * 2
    implicitHeight: cardHeight + edgeInset * 2

    property bool open: false

    // How far open, 0 to 1. Drives the attached panel's growth out of the bar; a floating card
    // only fades.
    property real reveal: open ? 1 : 0
    Behavior on reveal {
        NumberAnimation {
            duration: 260
            easing.type: Easing.BezierSpline
            easing.bezierCurve: popup.anim_CURVE_SMOOTH_SLIDE
        }
    }

    // The window outlives `open` by the closing animation: it is hidden once the panel has
    // retracted into the bar, not the moment it is asked to close.
    onRevealChanged: if (reveal <= 0 && !open && attached) visible = false

    function showPanel() {
        open = true;
        visible = true;
    }

    function hidePanel() {
        if (!stopHide) {
            open = false;
            if (!attached) visible = false;
            popupHover = false;
        }
    }

    property Item trigger: null

    property bool popupHover: false
    property bool stopHide: false

    function _updateHover() {
        if (!popupHover && !stopHide) {
            hidePanel();
        }
    }

    // Where the panel sits relative to its trigger. The defaults are the bar case -- hanging from
    // the bar below a bar module -- and are what every panel but one uses. A panel opened from
    // inside another panel overrides them to fly out sideways instead.
    //
    // anchorRectY < 0 means "the bar's bottom edge": worked out here from where the trigger sits in
    // its window, so the panel starts exactly where the bar ends whatever the trigger's own height.
    property int anchorEdges: Edges.Left | Edges.Bottom
    property int anchorGravity: Edges.Bottom | Edges.Middle
    property real anchorRectY: -1

    // The anchor rect is relative to the trigger. For an attached panel it is a one-pixel line
    // under the trigger at the bar's bottom edge -- one pixel high, so less one -- raised a further
    // pixel so the panel overlaps the bar by that much: on a fractionally scaled output the two
    // surfaces' edges are rounded separately, and without the overlap a hairline of whatever is
    // behind can show between them.
    // Where the trigger sits in the bar, measured as the panel is placed rather than bound:
    // mapToItem is not reactive, so a binding would hold wherever the trigger was when the shell
    // started, before the bar had laid out. Measured in `anchoring`, which fires before every
    // placement, rather than in showPanel, which a panel may replace with its own.
    property real _triggerTop: 0
    Connections {
        target: popup.anchor
        function onAnchoring() {
            if (popup.trigger) popup._triggerTop = popup.trigger.mapToItem(null, 0, 0).y;
        }
    }
    readonly property real _barBottomRectY: T.Config.barHeight - _triggerTop - 1 - 1

    anchor {
        item: trigger
        edges: popup.attached ? Edges.Bottom : popup.anchorEdges
        gravity: popup.anchorGravity
        // No Flip for an attached panel: flipped, it would open upwards off the top of the screen.
        adjustment: popup.attached ? PopupAdjustment.Slide : PopupAdjustment.Slide | PopupAdjustment.Flip
        rect.x: 0
        rect.width: trigger ? trigger.width : 1
        rect.y: popup.attached ? popup._barBottomRectY : popup.anchorRectY
        rect.height: 1
    }

    // Input only where the panel has been drawn so far, so the part of the window it has not yet
    // grown into does not swallow clicks meant for what is underneath.
    // (No mask at all for a floating card: a Region with no item is an empty region, which would
    // take every click away from it.)
    mask: popup.attached ? attachedMask : null
    Region {
        id: attachedMask
        item: attachedBody
    }

    Item {
        anchors.fill: parent

        AttachedSurface {
            id: attachedSurface
            visible: popup.attached
            width: parent.width
            height: popup.cardHeight * popup.reveal
            fillColor: T.Config.barBackground
        }

        // The card's own rectangle within the shape. The content is laid out at full size from
        // the start and this clips it, so the panel is uncovered from the top down as it grows
        // rather than reflowing on every frame.
        Item {
            id: attachedBody
            visible: popup.attached
            x: attachedSurface.bodyX
            width: attachedSurface.bodyWidth
            height: attachedSurface.height
            clip: true
        }

        ClippingRectangle {
            id: contentSection
            visible: !popup.attached
            anchors.fill: parent
            anchors.margins: popup.edgeInset
            radius: T.Config.popupRadius
            antialiasing: true
            // Solid unless popupOpacity says otherwise -- a panel sits over windows, not over the
            // wallpaper, so what shows through is arbitrary rather than the desktop.
            color: T.Config.popupBackground
            border.width: 1
            border.color: T.Config.outline
            opacity: popup.visible ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: anim_CURVE_SMOOTH_SLIDE
                }
            }
        }

        // One content column for both looks, parented to whichever is showing.
        Item {
            id: contentHost
            parent: popup.attached ? attachedBody : contentSection
            width: popup.popupWidth
            height: popup.cardHeight
            opacity: popup.attached ? Math.min(1, popup.reveal * 1.5) : 1

            HoverHandler {
                onHoveredChanged: {
                    popup.popupHover = hovered;
                    popup._updateHover();
                }
            }

            ColumnLayout {
                id: contentLayout
                anchors.fill: parent
                anchors.leftMargin: padding * 2
                anchors.rightMargin: padding * 2
                anchors.bottomMargin: bottomPadding
                anchors.topMargin: padding
                spacing: T.Config.popupLayoutSpacing
            }
        }
    }
}
