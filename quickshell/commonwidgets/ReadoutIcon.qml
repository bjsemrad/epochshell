import QtQuick
import QtQuick.Controls
import Quickshell.Widgets
import qs.theme as T

// A bare icon button for a ReadoutIconLine: a glyph or an image, a hover fill and nothing else,
// in the accent with a tick on its bottom edge while active, its name as a tooltip.
Item {
    id: button

    property string icon: ""
    // An image instead of a glyph (a tray item's icon).
    property string source: ""
    property string name: ""
    property bool active: false
    signal clicked()
    signal secondaryClicked()

    width: Readout.rowHeight + 4
    height: Readout.rowHeight + 4

    Rectangle {
        anchors.fill: parent
        radius: Readout.hoverRadius
        color: mouse.containsMouse ? Readout.hover : "transparent"
    }

    Text {
        visible: button.source.length === 0
        anchors.centerIn: parent
        text: button.icon
        color: button.active ? Readout.accent : Readout.value
        font.pixelSize: Readout.iconSize
        font.family: Readout.font
    }

    IconImage {
        visible: button.source.length > 0
        anchors.centerIn: parent
        implicitSize: Readout.iconSize
        source: button.source
    }

    Rectangle {
        visible: button.active
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 10
        height: Readout.tick
        color: Readout.accent
    }

    ToolTip.visible: mouse.containsMouse && button.name.length > 0
    ToolTip.delay: 500
    ToolTip.text: button.name

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.RightButton) button.secondaryClicked();
            else button.clicked();
        }
    }
}
