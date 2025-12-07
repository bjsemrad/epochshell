import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import QtQuick.Controls
import Quickshell.Io
import qs.theme as T
import qs.services as S
import qs.commonwidgets

Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 30

    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        height: 30
        color: "transparent"

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "System"
            color: T.Config.fg
            font.bold: true
            font.pointSize: 13
        }
    }

    RowLayout {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10
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

    // Rectangle {
    //     anchors.fill: parent
    //     anchors.leftMargin: 10
    //     anchors.rightMargin: 10
    //     color: "transparent"
    //
    //     Text {
    //         text: "System"
    //         color: T.Config.fg
    //         font.bold: true
    //         font.pointSize: 13
    //         anchors.verticalCenter: parent.verticalCenter
    //         anchors.left: parent.left
    //     }
    //
    //     Column {
    //         width: parent.width*.45
    //         height: parent.height
    //         anchors.right: parent.right
    //         anchors.rightMargin: 10
    //         Row {
    //             spacing: 5
    //             anchors.right: parent.right
    //             anchors.left: parent.left
    //             width: parent.width
    //             height: parent.height
    //
    //             Process {
    //                 id: missionCenter
    //                 command: ["flatpak", "run", "io.missioncenter.MissionCenter"]
    //             }
    //
    //             PanelHeaderIcon {
    //                 id: systemMonitorSettings
    //                 iconText: "󰄧"
    //                 function onClick(){
    //                     missionCenter.running = true
    //                 }
    //             }
    //
    //             Process {
    //                 id: firmware
    //                 command: ["gnome-firmware"]
    //             }
    //
    //             PanelHeaderIcon {
    //                 id: firmwareSettings
    //                 iconText: ""
    //                 function onClick(){
    //                     firmware.running = true
    //                 }
    //             }
    //         }
    //     }
    //  }
}
