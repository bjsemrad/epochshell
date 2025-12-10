import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.theme as T

Rectangle {
    id: frame
    required property var popup
    required property var iconSet
    required property bool mouseEnabled
    required property bool hoverEnabled
    property int padding: 10

    border.color: T.surfaceContainer
    color: T.Config.surfaceContainer
    border.width: 1
    radius: 20
    Layout.alignment: Qt.AlignVCenter
    implicitHeight: inner.implicitHeight + padding
    implicitWidth: inner.implicitWidth + padding * 2

    MouseArea {
        anchors.fill: parent

        implicitWidth: inner.implicitWidth
        implicitHeight: inner.implicitHeight

        hoverEnabled: frame.hoverEnabled
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (!popup.visible) {
                popup.visible = true; //Don't set this to !popup.visible, on high-refresh get odd flickering
            }
        }

        onEntered: {
            popup.visible = mouseArea.containsMouse;
        }

        onExited: {
            if (root.hoverEnabled) {
                popup.visible = !mouseArea.containMouse;
            }
        }
    }

    RowLayout {
        id: inner
        spacing: padding * 2
        anchors.centerIn: parent

        Repeater {
            model: iconSet

            delegate: Text {
                id: ws
                Layout.alignment: Qt.AlignVCenter
                text: modelData
                font.pixelSize: 16
                font.weight: Font.Normal
                font.family: T.Config.fontFamily
                color: T.Config.surfaceText
            }
        }
    }
}
