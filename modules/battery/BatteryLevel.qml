import QtQuick
import Quickshell
import Quickshell.Widgets
import QtQuick.Controls
import Quickshell.Io
import qs.theme as T
import qs.services as S
import qs.commonwidgets

import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    width: parent.width
    height: content.implicitHeight
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        color: "transparent"

        Column {
            id: content
            spacing: 20
            width: parent.width*.55
            anchors.verticalCenter: parent.verticalCenter
            Row {
                spacing: 10
                width: parent.width
                Text {
                    text: S.BatteryService.batteryIcon()
                    color: T.Config.fg
                    font.bold: true
                    font.pointSize: 12
                }

                Text {
                    text: Math.round(S.BatteryService.percentage) + "%"
                    color: T.Config.fg
                    font.bold: true
                    font.pointSize: 12
                }
            }

             Row {
                spacing: 10
                width: parent.width
                Text {
                    text: S.BatteryService.stateText()
                    color: T.Config.fg
                    font.bold: true
                    font.pointSize: 11
                }

            }

        }
    }
  }
