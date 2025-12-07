import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell
import Quickshell.Io
import qs.theme as T
import qs.services as S
import qs.commonwidgets

Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 30

    property string ssid: ""

    RowLayout {
        spacing: 10
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.left: parent.left
        width: parent.width
        height: parent.height

        Rectangle {
            radius: 6
            color: mouseArea.containsMouse ? T.Config.activeSelection : "transparent"
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: parent.height
            RowLayout {
                spacing: 10
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.left: parent.left
                width: parent.width

                Text {
                    text: "󰤨"
                    font.pixelSize: 18
                    Layout.alignment: Qt.AlignVCenter
                    color: T.Config.fg
                }

                Text {
                    text: root.ssid
                    Layout.alignment: Qt.AlignVCenter
                    color: T.Config.fg
                    font.pixelSize: 13
                }

                Spinner {
                    id: wifiSpinner
                    running: S.Network.wifiConnecting && S.Network.wifiConnectingTo === root.ssid
                }
            }
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    S.Network.connectTo(root.ssid)
                }
            }
        }
    }
}
