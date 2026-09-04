import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import qs.theme as T
import qs.services as S

Rectangle {
    id: root
    color: mouseArea.containsMouse ? T.Config.surfaceContainer : "transparent"
    radius: T.Config.popupRadius
    implicitWidth: inner.implicitWidth + T.Config.widthPaddingLarge
    implicitHeight: inner.implicitHeight + T.Config.popupPadding
    required property string iconText
    required property bool mouseEnabled
    property int fontPixelSize: T.Config.fontSizeLarge

    function performLeftClickAction() {
        console.log("Missing Implementation");
    }

    function performRightClickAction() {
        performLeftClickAction();
    }

    MouseArea {
        id: mouseArea
        enabled: mouseEnabled
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: mouseEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button == Qt.RightButton) {
                performRightClickAction();
            } else {
                performLeftClickAction();
            }
        }
    }

    Row {
        id: inner
        anchors.centerIn: parent
        height: parent.height
        spacing: T.Config.heightPaddingSmall
        Text {
            text: root.iconText
            font.pixelSize: root.fontPixelSize
            anchors.verticalCenter: parent.verticalCenter
            color: T.Config.surfaceText
        }
    }
}
