import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme" as T
PopupWindow {
    id: root
    visible: false
    color: "transparent"
    implicitWidth: container.implicitWidth + 20
    implicitHeight: container.implicitHeight + 20

    property Item trigger: null
    default property alias content: container.data

    property bool _popupHover: false

    function _updateHover() {
        if (!_popupHover)
            root.visible = false
    }

    Window.onActiveChanged: {
        if (!Window.active)
            root.visible = false
    }

    anchor {
        item: trigger
        edges: Edges.Left | Edges.Bottom
        gravity: Edges.Bottom | Edges.Right
        adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 8
        color: "#101010"
        border.color: "#555"

        HoverHandler {
            onHoveredChanged: {
                root._popupHover = hovered
                root._updateHover()
            }
        }

        Column {
            id: container
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8
        }
    }
}
