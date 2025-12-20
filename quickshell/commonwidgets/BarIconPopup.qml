import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import qs.theme as T
import qs.services as S

Rectangle {
    id: root
    color: popup && popup.visible ? T.Config.surfaceContainerHighest : "transparent"
    border.width: 1
    border.color: popup && popup.visible ? T.Config.outline : "transparent"
    radius: T.Config.popupRadius
    implicitWidth: inner.implicitWidth + T.Config.widthPaddingLarge
    implicitHeight: inner.implicitHeight + T.Config.heightPaddingSmall

    property var popup
    required property string iconText
    required property bool mouseEnabled
    required property bool hoverEnabled

    Rectangle {
        id: inner
        implicitWidth: iconText.implicitWidth
        implicitHeight: iconText.implicitHeight
        color: "transparent"
        anchors.centerIn: parent
        Text {
            id: iconText
            text: root.iconText
            font.pixelSize: T.Config.fontSizeLarge
            anchors.verticalCenter: parent.verticalCenter
            color: T.Config.surfaceText

            MouseArea {
                id: mouseArea
                enabled: mouseEnabled
                anchors.fill: parent
                hoverEnabled: root.hoverEnabled
                cursorShape: mouseEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (popup.visible) {
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
        }
    }
}
