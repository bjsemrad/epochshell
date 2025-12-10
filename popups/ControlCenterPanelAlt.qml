import Quickshell
import QtQuick
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

PanelWindow {
    id: popup

    // width of the panel
    implicitWidth: 625
    implicitHeight: col.implicitHeight //screen.height / 2   // or some fixed height if you prefer

    color: "transparent"
    focusable: false

    // Attach to right edge of screen, full height
    anchors {
        right: true
        top: true
        // bottom: true
    }
    margins.top: T.Config.barHeight + 10

    // show on top of normal windows
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore

    HoverHandler {
        onHoveredChanged: {
            popup.visible = hovered;
        }
    }

    // Open/close state
    property var trigger

    // Slide in/out using rightMargin:
    //   open  -> margin 0      (flush with right edge)
    //   closed -> margin -width (off-screen to the right)
    margins.right: visible ? 10 : -implicitWidth

    Behavior on margins.right {
        NumberAnimation {
            duration: 300
            easing.type: Easing.InOutQuad
        }
    }

    Component.onCompleted: {
        if (!username) {
            whoami.running = true;
        }
        S.PopupManager.register(popup);
        visible = false;
    }

    property string username
    property var cards: []

    onVisibleChanged: {
        if (visible) {
            S.PopupManager.closeOthers(popup);
        }
        cardStack.currentIndex = -1;
        // for (let card of cards)
        //     card.visible = false;
    }

    function registerCard(card) {
        if (cards.indexOf(card) === -1)
            cards.push(card);
    }

    function swapToCard(newCard) {
        cardStack.currentIndex = cardStack.children.indexOf(newCard);
    }
    // for (let /card of cards)
    // card.visible = (card === newCard);
    // }

    Process {
        id: whoami
        command: ["whoami"]
        running: true

        stdout: SplitParser {
            onRead: data => username = data.trim()
        }
    }

    SystemClock {
        id: sysclk
        precision: SystemClock.Seconds
    }

    // ─ rounded “card” that looks like the screenshot ─
    ClippingRectangle {
        id: content
        anchors.fill: parent
        radius: 18                          // round the corners
        color: T.Config.background
        border.width: 1
        border.color: T.Config.outline

        // // concave cut-out
        // Rectangle {
        //     width: 32
        //     height: 32
        //     radius: 999
        //     color: T.Config.background   // match your bar color
        //     x: -10
        //     y: -10
        // }

        // Content goes inside the window like before
        ColumnLayout {
            id: col
            anchors {
                fill: parent
                margins: 16
            }
            spacing: 20

            // ── Header card ───────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 80
                radius: 18
                color: T.Config.surfaceContainer

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    Rectangle {
                        width: 40
                        height: 40
                        radius: 999
                        color: "transparent"
                        Layout.alignment: Qt.AlignVCenter

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

            // ── Cards grid ────────────────────────────
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 10
                columnSpacing: 10

                ControlCard {
                    id: wifiCard
                    title: "Wifi"
                    visible: S.Network.wifiDevice && !S.Network.ethernetConnected
                    subtitle: S.Network.ssid
                    accent: true
                    iconSource: S.Network.wifiConnected ? "󰤨" : "󰤭"
                    Layout.fillWidth: true
                    connectedOverview: overviewWifi
                    onClicked: swapToCard(overviewWifi)
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
                    onClicked: swapToCard(overviewEthernet)
                }

                ControlCard {
                    title: "Bluetooth"
                    subtitle: S.Bluetooth.connected ? "Connected Devices" : "No Devices"
                    accent: true
                    iconSource: "󰂯"
                    Layout.fillWidth: true
                    connectedOverview: overviewBluetooth
                    onClicked: swapToCard(overviewBluetooth)
                }

                ControlCard {
                    title: "Sound"
                    subtitle: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink?.description : "None"
                    iconSource: ""
                    Layout.fillWidth: true
                    connectedOverview: overviewSound
                    onClicked: swapToCard(overviewSound)
                }

                ControlCard {
                    title: "Tailscale"
                    subtitle: S.Tailscale.connected ? S.Tailscale.magicDNSSuffix : "Disconnected"
                    iconSource: "󰒄"
                    Layout.fillWidth: true
                    connectedOverview: overviewTailscale
                    onClicked: swapToCard(overviewTailscale)
                }
            }

            StackLayout {
                id: cardStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                // clip: true
                O.Wifi {
                    id: overviewWifi
                    // visible: false
                    Component.onCompleted: registerCard(overviewWifi)
                }
                O.Bluetooth {
                    id: overviewBluetooth
                    // visible: false
                    Component.onCompleted: registerCard(overviewBluetooth)
                }
                O.Sound {
                    id: overviewSound
                    // visible: false
                    Component.onCompleted: registerCard(overviewSound)
                }
                O.Tailscale {
                    id: overviewTailscale
                    // visible: false
                    Component.onCompleted: registerCard(overviewTailscale)
                }
                O.Ethernet {
                    id: overviewEthernet
                    // visible: false
                    Component.onCompleted: registerCard(overviewEthernet)
                }
            }
        }
    }
}
