import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import "../services" as S
import "../theme" as T

Rectangle {
    id: networksSection
    width: parent.width
    anchors.right: parent.right
    anchors.left: parent.left
    color: "transparent"

    property bool expanded: false
    implicitHeight: header.height + listContainer.height


    Connections {
        target: networkPanel
        onVisibleChanged: if (!networkPanel.visible) networksSection.expanded = false
    }
    Column {
        anchors.fill: parent
        spacing: 6
        anchors.bottomMargin: 12
        Rectangle {
            id: header
            implicitHeight: 20
            width: parent.width
            color: "transparent"
            Row {
                width: parent.width
                spacing: 10
                Text {
                    id: avText
                    text: "Available Networks"
                    color: "white"
                    font.pixelSize: 13
                }

                Text {
                    text: expanded ? "▲" : "▼"
                    color: "#aaaaaa"
                    font.pixelSize: 12
                    anchors.left: avText.left + 20 
                }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: function() {
                    networksSection.expanded = !networksSection.expanded
                }
            }
        }

        Rectangle {
            id: listContainer
            radius: 6
            color: "#181818"
            clip: true
            border.width: 1
            border.color: T.Config.bg2
            width: parent.width
            implicitHeight: networksSection.expanded
                    ? Math.min(networkList.contentHeight, 300)
                    : 0

            Behavior on height {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.InOutQuad
                }
            }

            ListView {
                id: networkList
                anchors.fill: parent
                implicitHeight: Math.min(listContainer.implicitHeight,  100)
                model: S.NetworkMonitor.accessPoints
                interactive: true

                delegate: Rectangle {
                    width: ListView.view.width
                    implicitHeight: 30
                    color: "transparent"
                    border.width: 1
                    radius: 6
                    anchors.margins: 10
                    border.color: mouseArea.containsMouse ? T.Config.blue : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8



                        IconImage {
                              source: {
                                if (modelData.strength >= 75) return Quickshell.iconPath("network-wireless-signal-excellent-symbolic")
                                if (modelData.strength >= 50) return Quickshell.iconPath("network-wireless-signal-good-symbolic")
                                if (modelData.strength >= 25) return Quickshell.iconPath("network-wireless-signal-ok-symbolic")
                                if (modelData.strength > 0)   return Quickshell.iconPath("network-wireless-signal-weak-symbolic")
                                return Quickshell.iconPath("network-wireless-signal-none-symbolic")
                            }
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            implicitHeight: 18
                        }

                        Text {
                            text: modelData.ssid
                            color: "white"
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                           S.NetworkMonitor.connectTo(modelData.ssid) 
                            // connect to this AP here if you want
                            // e.g. call your nmcli Process with ssid
                        }
                    }
                }
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AlwaysOn
                }
            }
        }
    }
}
