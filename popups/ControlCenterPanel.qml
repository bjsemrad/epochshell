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
    implicitWidth: 600
    // implicitHeight: col.implicitHeight //screen.height / 2   // or some fixed height if you prefer

    color: "transparent"
    focusable: false

    property bool open: false

    function showPanel() {
        open = true;
        for (let card of cards) {
            card.closeCard();
        }
    }
    function hidePanel() {
        open = false;
        // for (let card of cards) {
        //     card.resetCard();
        //     // card.visible = false;
        // }
    }

    // Attach to right edge of screen, full height
    anchors {
        right: true
        top: true
        bottom: true
    }
    margins.top: T.Config.barHeight + 10
    margins.bottom: 10

    // show on top of normal windows
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore

    HoverHandler {
        onHoveredChanged: {
            if (!stopHide) {
                if (!hovered) {
                    hidePanel();
                }
                // popup.visible = hovered;
            }
        }
    }

    property var anim_CURVE_SMOOTH_SLIDE: [0.23, 1, 0.32, 1, 1, 1]

    visible: true
    // Open/close state
    property var trigger
    property bool stopHide: false

    margins.right: open ? 10 : -implicitWidth

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
        hidePanel();
        // visible = false;
    }

    onOpenChanged: {
        if (open) {
            S.PopupManager.closeOthers(popup);
        } else {
            for (let card of cards) {
                card.visible = false;
                card.resetCard();
            }
        }
    }

    property string username
    property var cards: []

    onVisibleChanged: {
        if (visible) {
            S.PopupManager.closeOthers(popup);
        }
    }

    function registerCard(card) {
        if (cards.indexOf(card) === -1)
            cards.push(card);
    }

    function swapToCard(newCard) {
        if (newCard.expanded) {
            newCard.closeCard();
        } else {
            console.log(newCard);
            for (let card of cards) {
                if (card === newCard) {
                    card.openCard();
                } else {
                    card.closeCard();
                }
            }
        }
    }

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
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.fill: parent
        radius: T.Config.cornerRadius
        color: T.Config.background
        border.width: 2
        border.color: T.Config.outline

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
                id: header
                Layout.fillWidth: true
                height: 80
                radius: T.Config.cornerRadius
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

            O.UtilsSystemTray {
                panelRef: popup
            }

            O.Stats {
                Layout.fillWidth: true
                container: popup
            }

            ColumnLayout {
                id: tabwrapper
                spacing: 0

                // ── Cards grid ────────────────────────────
                GridLayout {
                    id: grid
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
                        iconSource: {
                            const s = S.Network.strength;
                            if (!S.Network.wifiConnected)
                                return "󰤭";
                            if (s >= 75)
                                return "󰤨";
                            if (s >= 50)
                                return "󰤢";
                            if (s >= 25)
                                return "󰤟";
                            return "󰤟";
                        }
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
                        iconSource: {
                            if (S.Network.ethernetConnected) {
                                return "󰌗";
                            }
                            return "󰌙";
                        }
                        Layout.fillWidth: true
                        connectedOverview: overviewEthernet
                        onClicked: swapToCard(overviewEthernet)
                    }

                    ControlCard {
                        title: "Bluetooth"
                        subtitle: S.Bluetooth.connected ? "Connected Devices" : "No Devices"
                        accent: true
                        iconSource: S.Bluetooth.enabled ? S.Bluetooth.connected ? "󰂱" : "󰂯" : "󰂲"
                        Layout.fillWidth: true
                        connectedOverview: overviewBluetooth
                        onClicked: swapToCard(overviewBluetooth)
                    }

                    ControlCard {
                        title: "Sound"
                        subtitle: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink?.description : "None"
                        iconSource: {
                            const vol = Pipewire.defaultAudioSink?.audio.volume * 100;
                            if (Pipewire.defaultAudioSink?.audio.muted)
                                return "󰝟";
                            if (vol >= 65)
                                return "󰕾";
                            if (vol >= 25)
                                return "󰖀";
                            return "󰕿";
                        }
                        Layout.fillWidth: true
                        connectedOverview: overviewSound
                        onClicked: swapToCard(overviewSound)
                    }

                    ControlCard {
                        title: "Tailscale"
                        subtitle: S.Tailscale.connected ? S.Tailscale.magicDNSSuffix : "Disconnected"
                        iconSource: S.Tailscale.connected ? "󰒄" : "󰅛"
                        Layout.fillWidth: true
                        connectedOverview: overviewTailscale
                        onClicked: swapToCard(overviewTailscale)
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: cardStack.implicitHeight + 5
                    color: "transparent"

                    ColumnLayout {
                        id: cardStack
                        anchors.fill: parent
                        spacing: 0
                        O.Wifi {
                            id: overviewWifi
                            visible: false
                            Component.onCompleted: registerCard(overviewWifi)
                        }
                        O.Bluetooth {
                            id: overviewBluetooth
                            visible: false
                            Component.onCompleted: registerCard(overviewBluetooth)
                        }
                        O.Sound {
                            id: overviewSound
                            visible: false
                            Component.onCompleted: registerCard(overviewSound)
                        }
                        O.Tailscale {
                            id: overviewTailscale
                            visible: false
                            Component.onCompleted: registerCard(overviewTailscale)
                        }
                        O.Ethernet {
                            id: overviewEthernet
                            visible: false
                            Component.onCompleted: registerCard(overviewEthernet)
                        }
                    }
                }
            }
            BarFill {}
        }
    }
}
