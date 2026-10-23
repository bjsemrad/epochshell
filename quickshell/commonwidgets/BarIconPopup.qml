import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import qs.theme as T
import qs.services as S

// No border: an uncoloured 1px border draws black.
Rectangle {
    id: root
    // `popup` is briefly null while a panel is rebuilt (status style change).
    color: popup && popup.open ? T.Config.onBar(T.Config.surfaceContainer) : mouseArea.containsMouse ? T.Config.onBar(T.Config.surfaceContainer) : "transparent"
    radius: T.Config.popupRadius
    antialiasing: true
    implicitWidth: inner.implicitWidth + T.Config.barModuleHorizontalPadding
    implicitHeight: inner.implicitHeight + verticalPadding

    property var popup
    required property string iconText
    required property bool mouseEnabled
    required property bool hoverEnabled
    property int fontPixelSize: T.Config.barIconSize
    property int verticalPadding: T.Config.barModuleVerticalPadding
    property color iconColor: T.Config.surfaceText
    property string badgeText: ""
    property alias isHovered: mouseArea.containsMouse

    MouseArea {
        id: mouseArea
        enabled: mouseEnabled
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: mouseEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.rightClicked();
                return;
            }
            if (!popup) return;
            if (popup.open) {
                popup.hidePanel();
            } else {
                popup.showPanel();
            }
        }

        onEntered: {
            if (root.hoverEnabled && popup) {
                if (mouseArea.containsMouse) {
                    popup.showPanel();
                } else {
                    popup.hidePanel();
                }
            }
        }

        onExited: {
            if (root.hoverEnabled && popup) {
                if (!mouseArea.containsMouse) {
                    popup.hidePanel();
                }
            }
        }
    }

    signal rightClicked()

    Rectangle {
        id: inner
        implicitWidth: T.Config.barIconSize + (badge.visible ? badge.implicitWidth + Ui.badgeGap : 0)
        implicitHeight: T.Config.barIconSize
        color: "transparent"
        anchors.centerIn: parent
        Text {
            id: iconText
            text: root.iconText
            font.pixelSize: root.fontPixelSize
            font.family: T.Config.fontFamily
            anchors.verticalCenter: parent.verticalCenter
            x: (T.Config.barIconSize - implicitWidth) / 2
            color: root.iconColor
        }
        Text {
            id: badge
            visible: root.badgeText.length > 0
            anchors.verticalCenter: parent.verticalCenter
            x: T.Config.barIconSize + Ui.badgeGap
            text: root.badgeText
            color: Ui.alpha(T.Config.surfaceText, Ui.detailFloor)
            font.pixelSize: T.Config.fontSizeSubtext
            font.family: T.Config.fontFamily
        }
    }
}
