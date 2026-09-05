import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import qs.theme as T
import qs.services as S

Rectangle {
    id: root
    color: popup && popup.open ? T.Config.surfaceContainer : mouseArea.containsMouse ? T.Config.surfaceContainer : "transparent"
    border.width: 1
    radius: T.Config.popupRadius
    implicitWidth: inner.implicitWidth + T.Config.barModuleHorizontalPadding
    implicitHeight: inner.implicitHeight + T.Config.barModuleVerticalPadding

    property var popup
    required property string iconText
    required property bool mouseEnabled
    required property bool hoverEnabled
    property int fontPixelSize: T.Config.barIconSize

    MouseArea {
        id: mouseArea
        enabled: mouseEnabled
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: mouseEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (popup.open) {
                popup.hidePanel();
            } else {
                popup.showPanel();
            }
        }

        onEntered: {
            if (root.hoverEnabled) {
                if (mouseArea.containsMouse) {
                    popup.showPanel();
                } else {
                    popup.hidePanel();
                }
            }
        }

        onExited: {
            if (root.hoverEnabled) {
                if (!mouseArea.containsMouse) {
                    popup.hidePanel();
                }
            }
        }
    }

    Rectangle {
        id: inner
        implicitWidth: iconText.implicitWidth
        implicitHeight: iconText.implicitHeight
        color: "transparent"
        anchors.centerIn: parent
        Text {
            id: iconText
            text: root.iconText
            font.pixelSize: root.fontPixelSize
            font.family: T.Config.fontFamily
            anchors.verticalCenter: parent.verticalCenter
            color: T.Config.surfaceText
        }
    }
}
