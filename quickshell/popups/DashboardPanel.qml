import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.commonwidgets
import qs.modules
import qs.modules.audio
import qs.modules.battery
import qs.modules.bluetooth
import qs.modules.ethernet
import qs.modules.system
import qs.modules.wifi
import qs.theme as T
import qs.services as S

// Quick settings: one panel for what used to be five -- Wi-Fi, Bluetooth, sound, battery and the
// system menu -- opened from the bar's status cluster.
//
// The main page is the glanceable part: a tile per thing you switch (each tile toggles; the ones
// with more behind them have a › that opens their page), the volume, what is playing, the
// battery, the look of the shell, and the power actions. The Wi-Fi, Bluetooth and sound pages are
// the panels that used to stand on their own, built from the same modules, behind a back button.
//
// It answers to the old panel names too (`epochctl panel toggle wifi` and so on), opening on the
// matching page -- so keybindings made for the separate panels still land somewhere sensible.
HoverPopupWindow {
    id: dash

    // "main", "wifi", "ethernet", "bluetooth" or "audio".
    property string page: "main"

    popupWidth: page === "audio"
        ? Math.max(T.Config.audioPopupWidth, outputs.implicitWidth, inputs.implicitWidth)
        : 420

    // Which page an old panel name opens on.
    readonly property var pageForName: ({
        "wifi": "wifi",
        "ethernet": "ethernet",
        "bluetooth": "bluetooth",
        "audio": "audio"
    })

    // Called by PopupManager for a named open, in place of showPanel.
    function showPage(name) {
        page = pageForName[name] || "main";
        showPanel();
    }

    property string username
    Process {
        command: ["whoami"]
        running: true
        stdout: SplitParser {
            onRead: data => dash.username = data.trim()
        }
    }

    onOpenChanged: {
        // The power profile changes constantly -- auto-cpufreq flips turbo as load moves -- so it
        // is polled while the dashboard is up and left alone the rest of the time.
        S.PowerProfile.watching = open;
        if (open) {
            // Asked on opening rather than left to the next poll: a battery section that fills in
            // a few seconds later reads as broken.
            S.PowerProfile.refresh();
            S.SystemInfo.refresh();
            S.NightLight.refresh();
            S.StayAwake.refresh();
            S.Network.refresh();
            S.PopupManager.closeOthers(dash);
        } else {
            // Back to the main page for the next opening: a sub-page is somewhere you went, not
            // where the dashboard lives.
            page = "main";
        }
    }

    // While a network page is up, keep it fresh, as their own panels did: the Wi-Fi lists every
    // ten seconds, a wired link -- which comes and goes with a cable -- every five.
    Timer {
        interval: dash.page === "ethernet" ? 5000 : 10000
        repeat: true
        running: dash.open && (dash.page === "wifi" || dash.page === "ethernet")
        onTriggered: S.Network.refresh()
    }

    Component.onDestruction: S.PopupManager.unregister(dash)
    Component.onCompleted: {
        for (const name of ["dashboard", "system", "wifi", "ethernet", "bluetooth", "audio", "battery"])
            S.PopupManager.register(dash, name);
    }

    // =============================================================================================
    // Main page
    // =============================================================================================

    ColumnLayout {
        visible: dash.page === "main"
        Layout.fillWidth: true
        spacing: T.Config.popupLayoutSpacing

        // Who and what: the user, and the machine underneath.
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: T.Config.layoutMarginSmall
            spacing: T.Config.layoutMarginSmall

            Text {
                text: "󱄅"
                color: T.Config.accent
                font.pixelSize: T.Config.fontSizeXLarge
                font.family: T.Config.fontFamily
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: dash.username
                    color: T.Config.surfaceText
                    font.pixelSize: T.Config.fontSizeLarge
                    font.bold: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    visible: text.length > 0
                    text: [S.SystemInfo.product, S.SystemInfo.kernel].filter(s => s && s.length > 0).join(" · ")
                    color: T.Config.inactive
                    font.pixelSize: T.Config.fontSizeSubtext
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }

        // The switches, two to a row.
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: T.Config.cardSpacing
            columnSpacing: T.Config.cardSpacing

            QuickTile {
                visible: S.Network.wifiDevice
                icon: S.Network.wifiEnabled ? S.Network.currentWifiIcon : "󰤮"
                title: "Wi-Fi"
                subtitle: !S.Network.wifiEnabled ? "Off" : S.Network.wifiConnected ? S.Network.ssid : "Not connected"
                active: S.Network.wifiEnabled
                detailPage: "wifi"
                onToggle: S.Network.disableWifi(!S.Network.wifiEnabled)
            }

            // Wired, on a machine with a wired adapter -- on a desktop, usually the only network
            // there is. Nothing to switch, so the whole tile opens its page.
            QuickTile {
                visible: S.Network.ethernetDevice
                icon: S.Network.ethernetConnected ? "󰌘" : "󰌙"
                title: "Ethernet"
                subtitle: !S.Network.ethernetConnected ? "Disconnected"
                    : (S.Network.ethernetConnectedIP || S.Network.ethernetDeviceName || "Connected")
                active: S.Network.ethernetConnected
                toggleable: false
                detailPage: "ethernet"
            }

            QuickTile {
                icon: S.Bluetooth.currentBluetoothIcon
                title: "Bluetooth"
                subtitle: {
                    if (!S.Bluetooth.enabled) return "Off";
                    const connected = (S.Bluetooth.pairedDevices || []).filter(d => d.connected);
                    if (connected.length === 0) return "On";
                    return connected.length === 1 ? (connected[0].name || connected[0].deviceName || "Connected") : connected.length + " connected";
                }
                active: S.Bluetooth.enabled
                detailPage: "bluetooth"
                onToggle: S.Bluetooth.toggle(!S.Bluetooth.enabled)
            }

            QuickTile {
                icon: "󰖔"
                title: "Night mode"
                subtitle: !S.NightLight.available ? "Unavailable" : S.NightLight.enabled ? (S.NightLight.temperature + "K") : "Off"
                active: S.NightLight.enabled
                enabled: S.NightLight.available
                onToggle: S.NightLight.set(!S.NightLight.enabled)
            }

            QuickTile {
                visible: S.StayAwake.available
                icon: "󰅶"
                title: "Stay awake"
                subtitle: S.StayAwake.enabled ? ("held for " + S.StayAwake.held) : "Off"
                active: S.StayAwake.enabled
                onToggle: S.StayAwake.set(!S.StayAwake.enabled)
            }
        }

        ComponentSplitter {}

        // Volume, with the way into the sound devices beside it.
        RowLayout {
            Layout.fillWidth: true
            spacing: T.Config.layoutMarginSmall

            AudioVolumeRow {
                Layout.fillWidth: true
            }

            ChevronButton {
                Layout.alignment: Qt.AlignBottom
                onClicked: dash.page = "audio"
            }
        }

        // What is playing, when anything is. The media panel from the title in the bar has the
        // full player; this is the glance and the three buttons.
        ComponentSplitter {
            visible: mediaRow.visible
        }

        RowLayout {
            id: mediaRow
            readonly property var player: S.AudioService.player
            visible: player !== null && player !== undefined
            Layout.fillWidth: true
            spacing: T.Config.layoutMarginSmall

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: mediaRow.player ? (mediaRow.player.trackTitle || "Nothing playing") : ""
                    color: T.Config.surfaceText
                    font.pixelSize: T.Config.fontSizeNormal
                    font.bold: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: mediaRow.player ? (mediaRow.player.trackArtist || mediaRow.player.identity || "") : ""
                    visible: text.length > 0
                    color: T.Config.inactive
                    font.pixelSize: T.Config.fontSizeSubtext
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            RoundButton {
                icon: "󰒮"
                enabled: mediaRow.player && mediaRow.player.canGoPrevious
                onClicked: S.AudioService.runAction("previous", true, S.AudioService.playerKey(mediaRow.player))
            }
            RoundButton {
                icon: mediaRow.player && mediaRow.player.isPlaying ? "󰏤" : "󰐊"
                accent: true
                onClicked: S.AudioService.runAction("playPause", true, S.AudioService.playerKey(mediaRow.player))
            }
            RoundButton {
                icon: "󰒭"
                enabled: mediaRow.player && mediaRow.player.canGoNext
                onClicked: S.AudioService.runAction("next", true, S.AudioService.playerKey(mediaRow.player))
            }
        }

        // Battery and the power profile, on a machine that has one.
        ComponentSplitter {
            visible: S.BatteryService.hasBattery
        }

        BatteryLevel {
            visible: S.BatteryService.hasBattery
        }

        PowerProfileRow {}

        ComponentSplitter {}

        // How the shell looks.
        ThemeSelector {
            menu: dash
        }

        WallpaperRow {
            menu: dash
        }

        AppearanceRow {
            menu: dash
        }

        ComponentSplitter {}

        SessionActions {}
    }

    // =============================================================================================
    // Sub-pages: the panels that used to stand alone
    // =============================================================================================

    ColumnLayout {
        visible: dash.page === "wifi"
        Layout.fillWidth: true
        spacing: T.Config.popupLayoutSpacing

        BackHeader {}
        WifiOnOff {}
        ComponentSplitter {}
        WifiConnectedNetwork {}
        ComponentSplitter {}
        WifiSavedNetworks {}
        ComponentSplitter {}
        WifiAvailableNetworks {
            attachedPanel: dash
        }
        ComponentSpacer {
            bottomMargin: 6
        }
    }

    ColumnLayout {
        visible: dash.page === "ethernet"
        Layout.fillWidth: true
        spacing: T.Config.popupLayoutSpacing

        BackHeader {}
        EthernetHeader {}
        ComponentSplitter {}
        EthernetConnectedNetwork {}
        ComponentSpacer {}
    }

    ColumnLayout {
        visible: dash.page === "bluetooth"
        Layout.fillWidth: true
        spacing: T.Config.popupLayoutSpacing

        BackHeader {}
        BluetoothOnOff {}
        ComponentSplitter {}
        BluetoothPairedDevices {}
        ComponentSplitter {}
        BluetoothAvailableDevices {}
        ComponentSpacer {
            bottomMargin: 6
        }
    }

    ColumnLayout {
        visible: dash.page === "audio"
        Layout.fillWidth: true
        spacing: T.Config.popupLayoutSpacing

        BackHeader {}
        AudioHeader {}
        ComponentSplitter {}
        AudioVolumeRow {}
        ComponentSplitter {}
        AvailableAudioOutputs {
            id: outputs
        }
        ComponentSplitter {}
        MicVolumeRow {}
        ComponentSplitter {}
        AvailableAudioInputs {
            id: inputs
        }
        ComponentSpacer {}
    }

    // =============================================================================================
    // Pieces
    // =============================================================================================

    // A switch you can see the state of at a glance: lit in the accent when on. Clicking it
    // toggles; a tile with more behind it has a › at its right end that opens its page instead.
    // A tile with nothing to switch (`toggleable` false) opens its page from anywhere on it.
    component QuickTile: Rectangle {
        id: tile
        property string icon
        property string title
        property string subtitle
        property bool active: false
        property bool toggleable: true
        property string detailPage: ""
        signal toggle()

        Layout.fillWidth: true
        Layout.preferredHeight: T.Config.cardHeight + 6
        radius: T.Config.cardRadius
        antialiasing: true
        opacity: enabled ? 1 : 0.5
        color: active ? T.Config.accentLightShade
            : tileMouse.containsMouse ? T.Config.surfaceContainerHigh : T.Config.surfaceContainer
        border.width: active ? 1 : 0
        border.color: T.Config.accent

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: tile.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (tile.toggleable) tile.toggle();
                else if (tile.detailPage.length > 0) dash.page = tile.detailPage;
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: T.Config.popupPadding
            anchors.rightMargin: tile.detailPage.length > 0 ? 0 : T.Config.popupPadding
            spacing: T.Config.layoutMarginSmall

            Text {
                text: tile.icon
                color: tile.active ? T.Config.accent : T.Config.surfaceText
                font.pixelSize: T.Config.barIconSize
                font.family: T.Config.fontFamily
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                Text {
                    text: tile.title
                    color: T.Config.surfaceText
                    font.pixelSize: T.Config.fontSizeNormal
                    font.bold: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: tile.subtitle
                    visible: text.length > 0
                    color: T.Config.inactive
                    font.pixelSize: T.Config.fontSizeSubtext + 2
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            // The way into the page, its own target so it does not toggle on the way in.
            Rectangle {
                visible: tile.detailPage.length > 0
                Layout.fillHeight: true
                Layout.preferredWidth: T.Config.barIconSize + T.Config.popupPadding * 2
                radius: T.Config.cardRadius
                color: detailMouse.containsMouse ? Qt.rgba(T.Config.outline.r, T.Config.outline.g, T.Config.outline.b, 0.15) : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: T.Config.inactive
                    font.pixelSize: T.Config.fontSizeNormal
                    font.family: T.Config.fontFamily
                }

                MouseArea {
                    id: detailMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: dash.page = tile.detailPage
                }
            }
        }
    }

    // A › on its own, for a row that is not a tile.
    component ChevronButton: Rectangle {
        id: chev
        signal clicked()
        implicitWidth: T.Config.barIconSize + T.Config.popupPadding * 2
        implicitHeight: implicitWidth
        radius: T.Config.cardRadius
        color: chevMouse.containsMouse ? T.Config.surfaceContainerHigh : "transparent"

        Text {
            anchors.centerIn: parent
            text: ""
            color: T.Config.inactive
            font.pixelSize: T.Config.fontSizeNormal
            font.family: T.Config.fontFamily
        }

        MouseArea {
            id: chevMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chev.clicked()
        }
    }

    // The top of a sub-page: the way back, small, since the page's own header right below it
    // already says where you are.
    component BackHeader: Rectangle {
        Layout.topMargin: T.Config.layoutMarginSmall
        implicitWidth: backRow.implicitWidth + T.Config.popupPadding * 2
        implicitHeight: backRow.implicitHeight + T.Config.popupPadding
        radius: T.Config.cardRadius
        color: backMouse.containsMouse ? T.Config.surfaceContainerHigh : "transparent"

        RowLayout {
            id: backRow
            anchors.centerIn: parent
            spacing: T.Config.layoutMarginSmall

            Text {
                text: ""
                color: T.Config.inactive
                font.pixelSize: T.Config.fontSizeSubtext
                font.family: T.Config.fontFamily
            }

            Text {
                text: "Quick settings"
                color: T.Config.inactive
                font.pixelSize: T.Config.fontSizeSubtext
            }
        }

        MouseArea {
            id: backMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: dash.page = "main"
        }
    }

    // A round icon button, as the media panel has.
    component RoundButton: Rectangle {
        id: rb
        property string icon
        property bool accent: false
        signal clicked()
        implicitWidth: 34
        implicitHeight: 34
        radius: width / 2
        antialiasing: true
        opacity: enabled ? 1 : 0.4
        color: accent ? T.Config.accent : rbMouse.containsMouse ? T.Config.surfaceContainerHighest : T.Config.surfaceContainer

        Text {
            anchors.centerIn: parent
            text: rb.icon
            color: rb.accent ? T.Config.background : T.Config.surfaceText
            font.pixelSize: T.Config.fontSizeLarge
            font.family: T.Config.fontFamily
        }

        MouseArea {
            id: rbMouse
            anchors.fill: parent
            enabled: rb.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: rb.clicked()
        }
    }
}
