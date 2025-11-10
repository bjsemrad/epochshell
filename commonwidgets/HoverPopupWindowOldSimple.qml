import Quickshell
import QtQuick
import QtQuick.Controls

PopupWindow {
    id: root
    visible: false
    // focus: true
    color: "transparent"


    // Public API
    property Item trigger: null
    default property alias content: container.data

    // Internal hover flags
    property bool _triggerHover: false
    property bool _popupHover: false

    function _updateHover() {
        if (!_triggerHover && !_popupHover)
            root.visible = false
    }

    // Close on click outside
    Window.onActiveChanged: {
      if (!Window.active) {
          root.visible = false
      }
    }

    // Anchor popup to trigger
    anchor {
        item: trigger
        edges: Edges.Left | Edges.Bottom
        gravity: Edges.Bottom | Edges.Right
        adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
    }

    // Visual wrapper
    Rectangle {
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
