import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.theme as T

PopupWindow {
    id: popup
    visible: false
    color: "transparent"

    property var anim_CURVE_SMOOTH_SLIDE: [0.23, 1, 0.32, 1, 1, 1]

    default property alias content: contentLayout.data

    property int padding: T.Config.popupPadding
    property int bottomPadding: padding * 2
    property real popupWidth: 1

    // Transparent margin round the floating card: at a fractional scale the window's last physical
    // row/column can be rounded away, taking the border with it.
    readonly property int edgeInset: attached ? 0 : 1

    readonly property bool fromBar: anchorEdges === (Edges.Left | Edges.Bottom) && anchorRectY < 0

    readonly property bool attached: fromBar && T.Config.panelStyle !== "floating" && T.Config.barOpacity >= 0.5
        && (!T.Config.barCentered || T.Config.barIsLedge)

    readonly property int floatingGap: Ui.floatingGap

    function _findUp(name) {
        for (let item = trigger; item; item = item.parent) {
            if (item[name] !== undefined) return item[name];
        }
        return null;
    }

    property Item barBody: null
    readonly property bool fromPill: attached && barBody !== null
    readonly property bool cardOnPill: fromBar && !attached && barBody !== null
    readonly property bool _placedOnPill: fromPill || cardOnPill

    readonly property bool onLedge: fromPill && T.Config.barIsLedge
    readonly property real _ledgeNatural: barBody && barBody.naturalWidth !== undefined ? barBody.naturalWidth : 0
    readonly property string ledgeJoin: {
        if (!onLedge) return "";
        const d = popupWidth - _ledgeNatural;
        const r = T.Config.popupRadius;
        return d < -Ui.ledgeHangCorners * r ? "hang" : "snap";
    }
    readonly property bool _ledgeCard: ledgeJoin === "snap"
    readonly property real _cardWidth: ledgeJoin === "snap" ? Math.max(popupWidth, _ledgeNatural) : popupWidth

    property Item barStrip: null

    property bool snapRight: false
    readonly property bool atRightEdge: attached && !fromPill && snapRight
    readonly property real snapDistance: T.Config.popupRadius * 2
    readonly property real _barInset: barStrip && barStrip.radius > 0 ? barStrip.radius : 0
    property real _nudge: 0

    readonly property real flare: attached && (!_ledgeCard || T.Config.barSpanFull) ? T.Config.popupRadius : 0
    readonly property real _flareRight: atRightEdge && _barInset === 0 ? 0 : flare

    readonly property real cardHeight: contentLayout.implicitHeight + padding + bottomPadding

    implicitWidth: _cardWidth + flare + _flareRight + edgeInset * 2
    implicitHeight: cardHeight + edgeInset * 2 + (attached ? 1 : 0)

    property bool open: false

    property real reveal: 0
    NumberAnimation {
        id: revealAnimation
        target: popup
        property: "reveal"
        to: 1
        duration: Ui.revealMs
        easing.type: Easing.BezierSpline
        easing.bezierCurve: popup.anim_CURVE_SMOOTH_SLIDE
    }

    function showPanel() {
        barBody = _findUp("barPill");
        barStrip = _findUp("barStrip");
        snapRight = false;
        _nudge = 0;
        if (attached && !fromPill && barStrip && trigger) {
            const centre = trigger.mapToItem(barStrip, trigger.width / 2, 0).x;
            const centredWidth = popupWidth + flare * 2;
            snapRight = barStrip.width - _barInset - (centre + centredWidth / 2) < snapDistance;
            const left = centre - centredWidth / 2;
            if (!snapRight && _barInset > 0 && left < _barInset)
                _nudge = _barInset - left;
        }
        if (attached) {
            const bar = _findUp("barPanels");
            if (bar) bar.attach(popup);
        }
        open = true;
        visible = true;
        revealAnimation.restart();
    }

    function hidePanel() {
        if (!stopHide) {
            open = false;
            revealAnimation.stop();
            reveal = 0;
            visible = false;
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

    property int anchorEdges: Edges.Left | Edges.Bottom
    property int anchorGravity: Edges.Bottom | Edges.Middle
    property real anchorRectY: -1

    property real _triggerTop: 0
    property real _pillLeft: 0
    Connections {
        target: popup.anchor
        function onAnchoring() {
            if (!popup.trigger) return;
            popup._triggerTop = popup.trigger.mapToItem(null, 0, 0).y;
            if (popup.ledgeJoin === "snap") {
                popup._pillLeft = (popup.barBody.width - popup.width) / 2;
            } else if (popup._placedOnPill) {
                const margin = popup.fromPill ? T.Config.popupRadius : 0;
                const pillWidth = popup.barBody.width;
                const centre = popup.trigger.mapToItem(popup.barBody, popup.trigger.width / 2, 0).x;
                if (popup.width + margin * 2 > pillWidth)
                    popup._pillLeft = (pillWidth - popup.width) / 2;
                else
                    popup._pillLeft = Math.max(margin, Math.min(pillWidth - popup.width - margin, centre - popup.width / 2));
            }
        }
    }
    // Overlap the bar by a pixel only while it is solid; see-through, the doubled row shows as a
    // dark line.
    readonly property int _overlap: T.Config.barOpacity >= Ui.solidOpacity ? 1 : 0
    readonly property real _barBottomRectY: T.Config.barBottom - _triggerTop - 1 - _overlap

    anchor {
        item: popup._placedOnPill ? popup.barBody : popup.atRightEdge ? popup.barStrip : popup.trigger
        edges: popup._placedOnPill ? Edges.Bottom | Edges.Left
            : popup.atRightEdge ? Edges.Bottom | Edges.Right
            : popup.fromBar ? Edges.Bottom : popup.anchorEdges
        gravity: popup._placedOnPill ? Edges.Bottom | Edges.Right
            : popup.atRightEdge ? Edges.Bottom | Edges.Left : popup.anchorGravity
        // No Flip for attached panels (it would open off the top). Nothing at the right edge:
        // Hyprland slides an exact fit anyway, leaving a 4px gap.
        adjustment: popup.atRightEdge ? PopupAdjustment.None
            : popup.attached ? PopupAdjustment.Slide : PopupAdjustment.Slide | PopupAdjustment.Flip
        rect.x: popup._placedOnPill ? popup._pillLeft
            : popup.atRightEdge ? popup.barStrip.width - 1 - popup._barInset
            : popup._nudge
        rect.width: popup._placedOnPill || popup.atRightEdge ? 1 : popup.trigger ? popup.trigger.width : 1
        rect.y: popup.fromPill || popup.atRightEdge ? T.Config.barHeight - 1 - popup._overlap
            : popup.cardOnPill ? T.Config.barHeight - 1 + popup.floatingGap
            : popup.attached ? popup._barBottomRectY
            : popup.fromBar ? T.Config.barBottom - popup._triggerTop - 1 + popup.floatingGap
            : popup.anchorRectY
        rect.height: 1
    }

    // No mask for a floating card: a Region with no item is empty and would swallow every click.
    mask: popup.attached ? attachedMask : null
    Region {
        id: attachedMask
        item: attachedBody
    }

    // Never null or empty: a niri rule forcing xray on popups paints a popup with no region (or an
    // empty one, as while a panel's body is still zero height opening) edge to edge, clear margins
    // included. One pixel under the panel's own top row keeps a region with nothing visible to paint.
    readonly property real _anchorX: attached ? attachedBody.x + attachedBody.width / 2 : contentSection.x + contentSection.width / 2
    readonly property real _anchorY: attached ? 0 : contentSection.y + T.Config.popupRadius
    BackgroundEffect.blurRegion: !T.Config.popupBlur ? noBlur : popup.attached ? attachedBlur : floatingBlur
    Region {
        id: noBlur
        x: popup._anchorX
        y: popup._anchorY
        width: 1
        height: 1
    }
    // While the panel grows, the region trails its edge: the region lands a frame ahead of the paint,
    // and any of it past the painted edge shows a frame of bare wallpaper. Starting at half open and
    // catching up by the end keeps it behind even the opening's first, largest steps.
    readonly property real _blurHeight: cardHeight * Math.max(0, 2 * reveal - 1)
    Region {
        id: attachedBlur
        Region {
            x: attachedBody.x
            width: attachedBody.width
            height: popup._blurHeight
            radius: T.Config.popupRadius
        }
        Region {
            x: attachedBody.x
            width: attachedBody.width
            height: Math.min(popup._blurHeight, T.Config.popupRadius)
        }
        Region {
            x: popup._anchorX
            y: popup._anchorY
            width: 1
            height: 1
        }
    }
    Region {
        id: floatingBlur
        Region {
            item: contentSection
            radius: T.Config.popupRadius
        }
        Region {
            x: popup._anchorX
            y: popup._anchorY
            width: 1
            height: 1
        }
    }

    Item {
        anchors.fill: parent

        AttachedSurface {
            id: attachedSurface
            visible: popup.attached
            width: parent.width
            height: popup.cardHeight * popup.reveal
            flare: popup.flare
            rightFlush: popup.atRightEdge && popup._barInset === 0
            fillColor: popup.onLedge ? T.Config.barBackground : T.Config.panelBackground
            outlineOpacity: ["panel", "bar", "fade"].indexOf(T.Config.panelOutline) !== -1 ? popup.reveal : 0
            outlineFade: T.Config.panelOutline === "fade" && (!popup._ledgeCard || T.Config.barSpanFull) ? popup.flare : 0
        }

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
            color: popup.fromBar ? T.Config.panelBackground : T.Config.popupBackground
            border.width: 1
            border.color: T.Config.outline
            opacity: popup.visible ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Ui.fadeMs
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: anim_CURVE_SMOOTH_SLIDE
                }
            }
        }

        Item {
            id: contentHost
            parent: popup.attached ? attachedBody : contentSection
            x: popup._ledgeCard ? Math.round((parent.width - width) / 2) : 0
            width: popup.popupWidth
            height: popup.cardHeight
            opacity: popup.attached ? Math.min(1, popup.reveal * Ui.revealFadeRate) : 1

            HoverHandler {
                onHoveredChanged: {
                    popup.popupHover = hovered;
                    // Deferred: a hover change can come from the window resizing under the pointer,
                    // and closing inside that delivery crashed Qt 6.11.
                    Qt.callLater(popup._updateHover);
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
