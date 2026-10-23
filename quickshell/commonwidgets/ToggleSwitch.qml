import QtQuick
import qs.theme as T

Item {
    id: control

    property bool checked: false
    signal toggled()

    implicitWidth: 34
    implicitHeight: 18

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: control.checked ? T.Config.accent : Ui.alpha(T.Config.surfaceText, 0.18)

        Rectangle {
            x: control.checked ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 12
            height: 12
            radius: 3
            color: control.checked ? T.Config.background : Ui.alpha(T.Config.surfaceText, 0.6)
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        onClicked: control.toggled()
    }
}
