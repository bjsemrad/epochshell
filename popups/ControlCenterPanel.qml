import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Greetd
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.commonwidgets
import qs.modules
import qs.modules.audio
import qs.theme as T
import qs.services as S
import qs.modules.overview as O

HoverPopupWindow {
    id: popup
    popupWidth: 625

    Component.onCompleted: {
        if (!username) {
            whoami.running = true;
        }
        S.PopupManager.register(popup);
    }

    property string username
    property var cards: []
    onVisibleChanged: {
        if (visible) {
            S.PopupManager.closeOthers(popup);
        }

        for (let card of cards) {
            card.visible = false;
        }
    }

    function registerCard(card) {
        if (cards.indexOf(card) === -1) {
            cards.push(card);
        }
    }

    function swapToCard(newCard) {
        for (let card of cards) {
            if (card !== newCard) {
                card.visible = false;
            }
            newCard.visible = true;
        }
    }

    Process {
        id: whoami
        command: ["whoami"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                return username = data;
            }
        }
    }

    SystemClock {
        id: sysclk
        precision: SystemClock.Seconds
    }

    ColumnLayout {
        id: col
        Layout.bottomMargin: 20
        Layout.fillWidth: true
        spacing: 20

        Rectangle {
            Layout.fillWidth: true
            height: 80
            radius: 18
            color: T.Config.surfaceContainer

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                // Avatar
                Rectangle {
                    width: 40
                    height: 40
                    radius: 999
                    color: "transparent" //T.Config.bg3
                    Layout.alignment: Qt.AlignVCenter

                    // Replace with your avatar image
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: T.Config.accent
                        font.pixelSize: 32
                        font.bold: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: username
                        color: T.Config.surfaceText
                        font.pixelSize: 16
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: Qt.formatDateTime(sysclk.date, "dddd, MMM d, yyyy")
                        color: T.Config.surfaceText
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                O.SystemOptions {}
            }
        }

        // GridLayout {
        //     Layout.fillWidth: true
        //     columns: 1
        //     rowSpacing: 50
        //     O.SystemOptionsSpan {}
        // }

        // ── Grid of cards ────────────────────────
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            rowSpacing: 10
            columnSpacing: 10

            // Wi-Fi
            ControlCard {
                id: wifiCard
                title: "Wifi"
                visible: S.Network.wifiDevice && !S.Network.ethernetConnected
                subtitle: S.Network.ssid
                accent: true
                iconSource: S.Network.wifiConnected ? "󰤨" : "󰤭"
                Layout.fillWidth: true
                connectedOverview: overviewWifi
                onClicked: {
                    swapToCard(overviewWifi);
                }
            }

            ControlCard {
                id: ethernetCard
                title: "Ethernet"
                visible: S.Network.ethernetDevice && S.Network.wifiConnected
                subtitle: S.Network.ethernetConnected ? S.Network.ethernetConnectedIP : "Disconnected"
                accent: true
                iconSource: "󰌗"
                Layout.fillWidth: true
                connectedOverview: overviewEthernet
                onClicked: {
                    swapToCard(overviewEthernet);
                }
            }

            // Bluetooth
            ControlCard {
                title: "Bluetooth"
                subtitle: S.Bluetooth.connected ? "Connected Devices" : "No Devices"
                accent: true
                iconSource: "󰂯"
                Layout.fillWidth: true
                connectedOverview: overviewBluetooth
                onClicked: {
                    swapToCard(overviewBluetooth);
                }
            }

            // Speaker
            ControlCard {
                title: "Sound"
                subtitle: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink?.description : "None"
                iconSource: ""
                Layout.fillWidth: true
                connectedOverview: overviewSound
                onClicked: {
                    swapToCard(overviewSound);
                }
            }

            ControlCard {
                title: "Tailscale"
                subtitle: S.Tailscale.connected ? S.Tailscale.magicDNSSuffix : "Disconnected"
                iconSource: "󰒄"
                Layout.fillWidth: true
                connectedOverview: overviewTailscale
                onClicked: {
                    swapToCard(overviewTailscale);
                }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            O.Wifi {
                id: overviewWifi
                visible: false
                Component.onCompleted: {
                    registerCard(overviewWifi);
                }
            }
            O.Bluetooth {
                id: overviewBluetooth
                visible: false
                Component.onCompleted: {
                    registerCard(overviewBluetooth);
                }
            }
            O.Sound {
                id: overviewSound
                visible: false
                Component.onCompleted: {
                    registerCard(overviewSound);
                }
            }
            O.Tailscale {
                id: overviewTailscale
                visible: false
                Component.onCompleted: {
                    registerCard(overviewTailscale);
                }
            }
            O.Ethernet {
                id: overviewEthernet
                visible: false
                Component.onCompleted: {
                    registerCard(overviewEthernet);
                }
            }
        }
    }
}
