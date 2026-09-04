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
    property int padding: T.Config.barModuleVerticalPadding

    color: popup.open ? T.Config.surfaceContainer : mouseArea.containsMouse ? T.Config.surfaceContainer : "transparent"
    radius: T.Config.popupRadius
    Layout.alignment: Qt.AlignVCenter
    implicitHeight: inner.implicitHeight + padding
    implicitWidth: inner.implicitWidth + T.Config.barModuleHorizontalPadding

    MouseArea {
        id: mouseArea
        anchors.fill: parent

        implicitWidth: inner.implicitWidth
        implicitHeight: inner.implicitHeight

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (!popup.open) {
                popup.showPanel();
            } else {
                popup.hidePanel();
            }
        }

        onEntered: {
            if (frame.hoverEnabled) {
                if (mouseArea.containsMouse) {
                    popup.showPanel();
                } else {
                    popup.hidePanel();
                }
            }
        }

        onExited: {
            if (frame.hoverEnabled) {
                if (mouseArea.containsMouse) {
                    popup.showPanel();
                } else {
                    popup.hidePanel();
                }
            }
        }
    }

    RowLayout {
        id: inner
        spacing: T.Config.barGroupIconSpacing
        anchors.centerIn: parent

        Repeater {
            model: iconSet

            delegate: Text {
                id: ws
                Layout.alignment: Qt.AlignVCenter
                text: modelData
                font.pixelSize: T.Config.barIconSize
                font.weight: Font.Normal
                font.family: T.Config.fontFamily
                color: T.Config.surfaceText
            }
        }
    }
}
