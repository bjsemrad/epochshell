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

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        color: "transparent"

        Column {
            spacing: 20
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width*.90
            Text {
                text: "Sound"
                color: T.Config.fg
                font.bold: true
                font.pointSize: 13
            }
        }

        Column {
            width: parent.width*.10
            height: parent.height
            anchors.right: parent.right
            anchors.rightMargin: 10
            Row {
                spacing: 10
                anchors.right: parent.right
                anchors.left: parent.left
                width: parent.width
                height: parent.height


                PanelHeaderIcon {
                    id: audioSettings
                    iconText: ""
                    function onClick(){
                        S.AudioService.openSettings()
                    }
                }
            }
        }
     }
}
