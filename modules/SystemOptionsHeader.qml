import QtQuick
import Quickshell
import Quickshell.Widgets
import QtQuick.Controls
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

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        color: "transparent"

        Column {
            spacing: 20
            width: parent.width*.75
            Text {
                text: "System"
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
            Row {
                spacing: 5
                anchors.right: parent.right
                anchors.left: parent.left
                width: parent.width
                height: parent.height

                Process {
                    id: missionCenter
                    command: ["flatpak", "run", "io.missioncenter.MissionCenter"]
                }

                PanelHeaderIcon {
                    id: systemMonitorSettings
                    iconText: "󰄧"
                    function onClick(){
                        missionCenter.running = true
                    }
                }

                Process {
                    id: firmware
                    command: ["gnome-firmware"]
                }

                PanelHeaderIcon {
                    id: firmwareSettings
                    iconText: ""
                    function onClick(){
                        firmware.running = true
                    }
                }
            }
        }
     }
}
