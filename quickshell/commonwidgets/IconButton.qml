import QtQuick
import QtQuick.Controls
import Quickshell.Widgets
import qs.theme as T

Item {
    id: button

    property string icon: ""
    property string source: ""
    property string name: ""
    property bool active: false
    signal clicked()
    signal secondaryClicked()

    width: Ui.iconButtonSize
    height: Ui.iconButtonSize

    Rectangle {
        anchors.fill: parent
        radius: Ui.hoverRadius
        color: mouse.containsMouse ? Ui.hover : "transparent"
    }

    Text {
        visible: button.source.length === 0
        anchors.centerIn: parent
        text: button.icon
        color: button.active ? Ui.accent : Ui.value
        font.pixelSize: Ui.iconSize
        font.family: Ui.font
    }

    IconImage {
        visible: button.source.length > 0
        anchors.centerIn: parent
        implicitSize: Ui.iconSize
        source: button.source
    }

    ToolTip.visible: mouse.containsMouse && button.name.length > 0
    ToolTip.delay: Ui.tooltipDelay
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
