import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import qs.theme as T
import qs.services as S

Rectangle {
    id: root
    color: "transparent"
    implicitWidth: inner.implicitWidth + T.Config.widthPaddingLarge
    implicitHeight: inner.implicitHeight + T.Config.heightPaddingSmall
    required property string iconText
    required property bool mouseEnabled

    function performLeftClickAction() {
        console.log("Missing Implementation");
    }

    function performRightClickAction() {
        performLeftClickAction();
    }

    MouseArea {
        enabled: mouseEnabled
        anchors.fill: parent
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
            font.pixelSize: T.Config.fontSizeLarge
            anchors.verticalCenter: parent.verticalCenter
            color: T.Config.surfaceText
        }
    }
}
