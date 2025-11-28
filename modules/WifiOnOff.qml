import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import "../theme" as T
import "../services" as S
import "../commonwidgets"

import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    width: parent.width
    height: 30
    radius: 40
    color: "transparent"

    Row {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        Column {
            spacing: 20
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width*.75
            Text {
                text: "Wifi"
                color: T.Config.fg
                font.bold: true
                font.pointSize: 13
            }
        }

        Column {
            width: parent.width*.25
            height: parent.height
            anchors.right: parent.right
            anchors.rightMargin: 10
            spacing: 8
            Row {
                spacing: 10
                anchors.right: parent.right
                anchors.left: parent.left
                width: parent.width
                height: parent.height


                RoundedSwitch{
                    id: wifiSwitch
                    anchors.verticalCenter: parent.verticalCenter
                    checked: S.NetworkMonitor.wifiEnabled
                    onToggled: {
                        S.NetworkMonitor.disableWifi(wifiSwitch.checked)
                    }
                }


                Rectangle {
                    id: networkSettings
                    implicitWidth: 40;
                    implicitHeight: 40
                    radius: 20
                    border.width: 2
                    border.color: settingsMouseArea.containsMouse ? T.Config.blue : "transparent"
                    color: "transparent"
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: ""
                        font.pixelSize: 18
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.centerIn: parent
                        color: T.Config.fg
                    }
                    MouseArea {
                        id: settingsMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            S.NetworkMonitor.editNetworks()
                        }

                    }
                }
            }
        }
     }
}
