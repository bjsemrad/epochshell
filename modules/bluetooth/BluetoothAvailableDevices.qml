import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import qs.services as S
import qs.theme as T
import qs.commonwidgets

Item {
    id: bluetoothSection
    Layout.fillWidth: true
    Layout.preferredHeight: col.implicitHeight

    property bool expanded: false

    Connections {
        target:  bluetoothPanel
        function onVisibleChanged() {
            if (!bluetoothPanel.visible) {
                bluetoothSection.expanded = false
                S.Bluetooth.stopScan()
            }
        }
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: 15
        Rectangle {
            id: header
            Layout.preferredHeight: 20
            Layout.fillWidth: true
            color: "transparent"
            RowLayout {
                width: parent.width
                spacing: 10
                Text {
                    id: avText
                    Layout.alignment: Qt.AlignVCenter
                    text: "Available Devices"
                    color: T.Config.fg
                    font.pixelSize: 13
                    Layout.leftMargin: 4
                }

                RowLayout {
                   spacing: 10

                   Rectangle {
                        Layout.preferredWidth: 100
                        Layout.preferredHeight: 25
                        radius: 10
                        color: S.Bluetooth.discovering ? T.Config.green : T.Config.bg2
                        Text {
                            anchors.centerIn: parent
                            color: S.Bluetooth.discovering ? T.Config.black : T.Config.fg
                            font.pixelSize: 13
                            text: S.Bluetooth.discovering ? "Stop Scan" : "Start Scan"
                        }

                        MouseArea {

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: function() {
                                if (!S.Bluetooth.adapter) return;
                                if (!S.Bluetooth.discovering) {
                                    S.Bluetooth.scanForDevices()
                                    bluetoothSection.expanded = true

                                } else {
                                    S.Bluetooth.stopScan()
                                }
                            }
                        }
                    }

                    Spinner {
                        id: bluetoothSpinner
                        running: S.Bluetooth.discovering
                    }
                }
            }
        }

        Rectangle {
            id: listContainer
            radius: 6
            color: T.Config.bg
            clip: true
            border.width: 2
            border.color: T.Config.bg2
            Layout.fillWidth: true
            Layout.preferredHeight: bluetoothSection.expanded
                    ? Math.min(bluetoothList.contentHeight, 300)
                    : 0

            Behavior on height {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.InOutQuad
                }
            }

            ListView {
                id: bluetoothList
                anchors.fill: parent
                implicitHeight: Math.min(listContainer.implicitHeight,  100)
                model: S.Bluetooth.devices
                interactive: true

                delegate: Rectangle {
                    width: ListView.view.width*.9
                    implicitHeight: 30
                    radius: 6
                    anchors.margins: 10
                    color: mouseArea.containsMouse ? T.Config.activeSelection : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        width: parent.width
                        anchors.margins: 10
                        spacing: 8


                        Text {
                            text: S.Bluetooth.getDeviceIcon(modelData)
                            font.pixelSize: 18
                            Layout.alignment: Qt.AlignVCenter
                            color: T.Config.fg
                        }

                        Text {
                            text: modelData.name
                            Layout.alignment: Qt.AlignVCenter
                            color: T.Config.fg
                            font.pixelSize: 13
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !S.Bluetooth.discovering
                        cursorShape: !S.Bluetooth.discovering ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            modelData.trusted = true
                            modelData.connect()
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
