import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import "../theme" as T
import "../commonwidgets"

Rectangle {
    id: audioOutputSection
    width: parent.width
    anchors.right: parent.right
    anchors.left: parent.left
    color: "transparent"

    property bool expanded: false
    implicitHeight: header.height + listContainer.height

    property var sinks //Pipewire.nodes.filter(n => n.isSink && n.audio) 

    Connections {
        target: audioPanel
        onVisibleChanged: {
            if (!audioPanel.visible) {
                audioOutputSection.expanded = false
            }
        }
    }

    Column {
        anchors.margins: 4
        anchors.fill: parent
        spacing: 6
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
                    text: "Available Outputs"
                    color: T.Config.fg
                    font.pixelSize: 13
                    Layout.leftMargin: 4
                }

                Text {
                    text: expanded ? "▲" : "▼"
                    color: "#aaaaaa"
                    font.pixelSize: 12
                }

            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: function() {
                    audioOutputSection.expanded = !audioOutputSection.expanded

                }
            }
        }


        Rectangle {
            id: listContainer
            radius: 6
            color: "#181818"
            clip: true
            border.width: 2
            border.color: T.Config.bg2
            width: parent.width
            implicitHeight: audioOutputSection.expanded
                    ? Math.min(audioList.contentHeight, 300)
                    : 0

            Behavior on height {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.InOutQuad
                }
            }

            ListView {
                id: audioList
                anchors.fill: parent
                implicitHeight: Math.min(listContainer.implicitHeight,  100)
                model: sinks
                interactive: true

                delegate: Rectangle {
                    width: ListView.view.width*.9
                    implicitHeight: 30
                    color: "transparent"
                    border.width: 2
                    radius: 6
                    anchors.margins: 10
                    border.color: mouseArea.containsMouse ? T.Config.blue : "transparent"

                    Row {
                        anchors.fill: parent
                        width: parent.width
                        anchors.margins: 10
                        spacing: 8


                        Text {
                            text:  {
                                const s = modelData.name

                                if (s >= 75) return "󰤨"
                                if (s >= 50) return "󰤢"
                                if (s >= 25) return "󰤟"
                                return "󰤟"
                            }
                            font.pixelSize: 18
                            anchors.verticalCenter: parent.verticalCenter
                            color: T.Config.fg
                        }
 
                        Text {
                            text: modelData.name
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
