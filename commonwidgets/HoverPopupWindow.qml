import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme" as T
PopupWindow {
    id: root
    visible: false
    color: "transparent"

    // Public API
    property Item trigger: null
    default property alias content: container.data

    // Hover state
    property bool _triggerHover: false
    property bool _popupHover: false

    function _updateHover() {
        if (!_triggerHover && !_popupHover)
            root.visible = false
    }

    // Close on unfocus
    Window.onActiveChanged: {
        if (!Window.active)
            root.visible = false
    }

    // Anchor popup to trigger button
    anchor {
        item: trigger
        edges: Edges.Left | Edges.Bottom
        gravity: Edges.Bottom | Edges.Right
        adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
    }

    //
    // ✅ This must have a real visible size
    //
    // If you want automatic content sizing:
    // use a reasonable fixed/default width
    width: Math.max(container.implicitWidth + 20, T.Config.controlCenterWidth + 30)
    height: container.implicitHeight + 20


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

        // ✅ Content fills, but margin keeps padding
        Column {
            id: container
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8
        }
    }
}
