import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.theme as T

PopupWindow {
    id: popup
    visible: false
    color: "transparent"

    default property alias content: contentLayout.data
    readonly property int padding: 10
    property real popupWidth: 100
    implicitWidth:  popupWidth //contentLayout.implicitWidth  + padding * 2
    implicitHeight: contentLayout.implicitHeight + padding * 2

    property Item trigger: null

    property bool popupHover: false
    property bool stopHide: false

    function _updateHover() {
        if (!popupHover && !stopHide){
            popup.visible = false
        }
    }

    Window.onActiveChanged: {
        if (!Window.active) {
            popup.visible = false
        }
    }

    //  // --- SHADOW ---
    // DropShadow {
    //     id: shadow
    //     anchors.fill: contentSection   // shadow covers popup area
    //     source: contentSection
    //     radius: 12          // softness of shadow
    //     samples: 24         // quality
    //     horizontalOffset: 0
    //     verticalOffset: 6   // pushes shadow downward a bit
    //     color: "#00000080"  // 50% opacity black
    // }

    anchor {
        item: trigger
        edges: Edges.Left | Edges.Bottom
        gravity: Edges.Bottom | Edges.Right
        adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
    }


    Rectangle {
        id: contentSection
        anchors.fill: parent
        radius: 8
        color: T.Config.bg
        border.color: T.Config.grey
          
        HoverHandler {
            onHoveredChanged: {
                popup.popupHover = hovered
                popup._updateHover()
            }
        }

        ColumnLayout {
            id: contentLayout
            anchors.fill: parent
            anchors.margins: padding * 2
            spacing: 8
            // children get added here via `content` alias
        }

        // Item {
        //     id: container
        //     anchors.fill: parent
        //     anchors.margins: 10
        // }

    }
}
