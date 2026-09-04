import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.theme as T

Rectangle {
    id: root
    color: popup && popup.open ? T.Config.surfaceContainer : mouseArea.containsMouse ? T.Config.surfaceContainer : "transparent"
    radius: T.Config.popupRadius
    implicitWidth: clockText.implicitWidth + T.Config.barModuleHorizontalPadding
    implicitHeight: clockText.implicitHeight + T.Config.barModuleVerticalPadding

    property var popup

    SystemClock {
        id: sysclk
        precision: SystemClock.Seconds
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (popup.open) {
                popup.hidePanel();
            } else {
                popup.showPanel();
            }
        }
    }

    Text {
        id: clockText
        text: Qt.formatDateTime(sysclk.date, "ddd hh:mm AP")
        color: T.Config.surfaceText
        font {
            pointSize: T.Config.barClockSize
            family: T.Config.fontFamily
        }
        anchors.centerIn: parent
    }
}
