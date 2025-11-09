import QtQuick
import Quickshell
import "../theme" as T

Rectangle {
    id: clock

    SystemClock {
      id: sysclk
      precision: SystemClock.Seconds
    }

    Text {
        text: Qt.formatDateTime(sysclk.date, "ddd hh:mm AP")
        color: T.Config.fgDark
        font {
          pointSize: 12
          family: T.Config.fontFamily
        }
        anchors {
          verticalCenter: parent.verticalCenter
          horizontalCenter: parent.horizontalCenter
        }

    }
}
