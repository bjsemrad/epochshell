import Quickshell
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
    readonly property int padding: 10
    property real popupWidth: 100
    implicitWidth: popupWidth
    implicitHeight: contentLayout.implicitHeight + padding * 2

    property Item trigger: null

    property bool popupHover: false
    property bool stopHide: false

    function _updateHover() {
        if (!popupHover && !stopHide) {
            popup.visible = false;
        }
    }

    anchor {
        item: trigger
        edges: Edges.Left | Edges.Bottom
        gravity: Edges.Bottom | Edges.Middle
        adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
        rect.y: trigger.mapToGlobal(0, 0).y + trigger.height + 20
    }

    Item {
        Window.onActiveChanged: {
            if (!Window.active) {
                popup.visible = false;
            }
        }
        anchors.fill: parent

        ClippingRectangle {
            id: contentSection
            anchors.fill: parent
            anchors.bottomMargin: 10
            radius: 10
            color: T.Config.background
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

            HoverHandler {
                onHoveredChanged: {
                    popup.popupHover = hovered;
                    popup._updateHover();
                }
            }

            ColumnLayout {
                id: contentLayout
                anchors.fill: parent
                anchors.margins: padding * 2
                spacing: 8
            }
        }
    }
}
