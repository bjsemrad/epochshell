import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.theme as T

Rectangle {
    id: root
    color: popup && popup.open ? T.Config.onBar(T.Config.surfaceContainer) : mouseArea.containsMouse ? T.Config.onBar(T.Config.surfaceContainer) : "transparent"
    radius: T.Config.popupRadius
    antialiasing: true
    // Half the icons' side padding: text carries its own side bearings, so the full amount stood
    // the clock off from the icon before it.
    implicitWidth: clockText.implicitWidth + Math.round(T.Config.barModuleHorizontalPadding / 2)
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
        // Just the time, unpadded -- "3:19 PM", as the lock screen has it. The day is a click
        // away in the calendar.
        text: Qt.formatDateTime(sysclk.date, "h:mm AP")
        color: T.Config.surfaceText
        font {
            pixelSize: T.Config.barClockSize
            family: T.Config.fontFamily
        }
        anchors.centerIn: parent
    }
}
