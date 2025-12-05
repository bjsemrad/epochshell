import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.theme as T
import qs.services as S
import qs.commonwidgets

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
            width: parent.width*.93
            Text {
                text: "Ethernet"
                color: T.Config.fg
                font.bold: true
                font.pointSize: 13
            }
        }

        Column {
            width: parent.width*.07
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
                    id: networkSettings
                    iconText: ""
                    function onClick(){
                        S.Network.editNetworks()
                    }
                }
            }
        }
     }
}
