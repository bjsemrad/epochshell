import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Pipewire
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
// The main page is the glanceable part: a tile per thing you switch, sound and the microphone
// among them (each tile toggles; the ones with more behind them have a › that opens their page),
// the look of the shell, and the power actions. What is playing is not here: the bar's media
// indicator has the player. The Wi-Fi, Bluetooth and sound pages are
// the panels that used to stand on their own, built from the same modules, behind a back button.
//
// It answers to the old panel names too (`epochctl panel toggle wifi` and so on), opening on the
// matching page -- so keybindings made for the separate panels still land somewhere sensible.
HoverPopupWindow {
    id: dash

    // "main", "wifi", "ethernet", "bluetooth", "audio" or "battery".
    property string page: "main"

    // What wants attention, for the compact bar, which has no alert icons: its capsule shows a dot
    // while this is set, and the main page lists each one (the Attention section).
    readonly property bool needsAttention: S.NixUpdates.hasUpdates || S.SystemInfo.hasFirmwareUpdates
        || S.StayAwake.enabled || S.LocalSend.hasIncomingFiles || S.Tailscale.hasIncomingFiles
        || S.Notifications.unreadCount > 0

    popupWidth: page === "audio"
        ? Math.max(T.Config.audioPopupWidth, outputs.implicitWidth, inputs.implicitWidth)
        : 420

    // Which page an old panel name opens on.
    readonly property var pageForName: ({
        "wifi": "wifi",
        "ethernet": "ethernet",
        "bluetooth": "bluetooth",
        "audio": "audio",
        "battery": "battery"
    })

    // Moving between pages from a click. A page can be much shorter than the one it replaces --
    // the battery page against the main one -- and the panel shrinks out from under the pointer,
    // which reads as the pointer leaving and would close it on the spot. So the panel holds open
    // through the switch; it closes as usual the next time the pointer leaves it.
    function goTo(name) {
        dash.stopHide = true;
        dash.page = name;
        pageSettle.restart();
    }

    Timer {
        id: pageSettle
        interval: 400
        onTriggered: dash.stopHide = false
    }

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

            // The compact bar shows the time but not the day; the date is here.
            SystemClock {
                id: dashClock
                precision: SystemClock.Minutes
            }

            Text {
                visible: T.Config.barCompact
                Layout.alignment: Qt.AlignVCenter
                text: Qt.formatDateTime(dashClock.date, "ddd, MMM d")
                color: T.Config.inactive
                font.pixelSize: T.Config.fontSizeNormal
                font.family: T.Config.fontFamily
            }
        }

        // What wants attention, one row each, for the compact bar, where these have no icons of
        // their own. A row opens the panel the icon would have; Stay awake's turns it off.
        ColumnLayout {
            visible: T.Config.barCompact && dash.needsAttention
            Layout.fillWidth: true
            spacing: 4

            AttentionRow {
                visible: S.Notifications.unreadCount > 0
                icon: "󰂚"
                title: S.Notifications.unreadCount === 1 ? "1 new notification" : S.Notifications.unreadCount + " new notifications"
                onActivated: S.PopupManager.openPanel("notifications")
            }
            AttentionRow {
                visible: S.NixUpdates.hasUpdates
                icon: S.NixUpdates.icon
                title: S.NixUpdates.updates === 1 ? "1 flake input can be updated" : S.NixUpdates.updates + " flake inputs can be updated"
                onActivated: S.PopupManager.openPanel("nix")
            }
            AttentionRow {
                visible: S.SystemInfo.hasFirmwareUpdates
                icon: S.SystemInfo.firmwareIcon
                title: "Firmware update available"
                onActivated: S.PopupManager.openPanel("firmware")
            }
            AttentionRow {
                visible: S.LocalSend.hasIncomingFiles
                icon: S.LocalSend.icon
                title: "Incoming files over LocalSend"
                onActivated: S.PopupManager.openPanel("localsend")
            }
            AttentionRow {
                visible: S.Tailscale.hasIncomingFiles
                icon: "󰒄"
                title: "Incoming files over Taildrop"
                onActivated: S.PopupManager.openPanel("tailscale")
            }
            AttentionRow {
                visible: S.StayAwake.enabled
                icon: "󰒳"
                title: "Held awake" + (S.StayAwake.held ? " for " + S.StayAwake.held : "")
                action: "Turn off"
                onActivated: S.StayAwake.set(false)
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

            // Sound and the microphone as switches like the rest: the tile mutes and unmutes, the
            // › opens the sound page with the devices and the sliders. Scrolling over the sound
            // tile turns the volume, so the level is still a gesture away without a slider here.
            QuickTile {
                readonly property var sink: Pipewire.defaultAudioSink
                visible: sink !== null
                icon: S.AudioService.currentAudioIcon
                title: "Sound"
                subtitle: !sink || !sink.audio ? "" : sink.audio.muted ? "Muted"
                    : Math.round(sink.audio.volume * 100) + "%" + (sink.description ? " · " + sink.description : "")
                active: sink !== null && sink.audio !== null && !sink.audio.muted
                detailPage: "audio"
                onToggle: if (sink && sink.audio) sink.audio.muted = !sink.audio.muted

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        const audio = parent.sink ? parent.sink.audio : null;
                        if (!audio) return;
                        const step = event.angleDelta.y > 0 ? 0.05 : event.angleDelta.y < 0 ? -0.05 : 0;
                        audio.volume = Math.max(0, Math.min(1, Math.round((audio.volume + step) * 20) / 20));
                        if (step > 0 && audio.muted) audio.muted = false;
                    }
                }
            }

            QuickTile {
                readonly property var source: Pipewire.defaultAudioSource
                visible: source !== null
                icon: source && source.audio && source.audio.muted ? "󰍭" : "󰍬"
                title: "Microphone"
                subtitle: !source || !source.audio ? "" : source.audio.muted ? "Muted"
                    : (source.description || "On")
                active: source !== null && source.audio !== null && !source.audio.muted
                detailPage: "audio"
                onToggle: if (source && source.audio) source.audio.muted = !source.audio.muted
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

            // The battery: the level and what it is doing at a glance, the details and the power
            // profile on its page. Nothing to switch, so the whole tile opens it. Across both
            // columns, as the odd one out after three pairs.
            QuickTile {
                visible: S.BatteryService.hasBattery
                Layout.columnSpan: 2
                icon: S.BatteryService.batteryIcon()
                title: "Battery"
                subtitle: {
                    const state = S.BatteryService.stateText();
                    return Math.round(S.BatteryService.percentage) + "%" + (state.length > 0 ? " · " + state : "");
                }
                toggleable: false
                detailPage: "battery"
            }
        }

        // The compact bar has no drawer, so its tools and services are here: one button each,
        // opening the panel the drawer's icon would have (hanging from the bar's capsule) or doing
        // the thing. Only what this machine has.
        ComponentSplitter {
            visible: T.Config.barCompact
        }

        GridLayout {
            visible: T.Config.barCompact
            Layout.fillWidth: true
            columns: 4
            rowSpacing: T.Config.cardSpacing
            columnSpacing: T.Config.cardSpacing

            ToolButton {
                visible: S.Capture.connected
                icon: S.Capture.icon
                label: "Capture"
                onActivated: S.PopupManager.openPanel("capture")
            }
            ToolButton {
                visible: S.Capture.connected && S.Capture.recordAvailable && !S.Capture.recording
                icon: "󰕧"
                label: "Record"
                onActivated: S.PopupManager.openPanel("record")
            }
            ToolButton {
                icon: "󰨸"
                label: "Clipboard"
                onActivated: {
                    const launcher = S.PopupManager.launcher;
                    if (!launcher) return;
                    S.PopupManager.closeAll();
                    launcher.openProvider("clipboard");
                }
            }
            ToolButton {
                icon: "󰴱"
                label: "Pick color"
                onActivated: {
                    dash.hidePanel();
                    colorPicker.running = true;
                }
            }
            ToolButton {
                visible: S.LocalSend.connected
                icon: S.LocalSend.icon
                label: "LocalSend"
                active: S.LocalSend.hasIncomingFiles
                onActivated: S.PopupManager.openPanel("localsend")
            }
            ToolButton {
                visible: S.Tailscale.available
                icon: S.Tailscale.connected ? "󰒄" : "󰅛"
                label: "Tailscale"
                active: S.Tailscale.hasIncomingFiles
                onActivated: S.PopupManager.openPanel("tailscale")
            }
            ToolButton {
                visible: S.HomeAssistant.configured
                icon: S.HomeAssistant.connected ? "󰟐" : "󰟑"
                label: "Home"
                onActivated: S.PopupManager.openPanel("homeassistant")
            }
            ToolButton {
                visible: S.NixUpdates.connected && S.NixUpdates.available
                icon: S.NixUpdates.icon
                label: "Nix"
                active: S.NixUpdates.hasUpdates
                onActivated: S.PopupManager.openPanel("nix")
            }
        }

        // The tray, for the same reason: apps that live there have nowhere else to be.
        Flow {
            visible: T.Config.barCompact && S.SystemTray.trayItems.length > 0
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: S.SystemTray.trayItems

                delegate: Rectangle {
                    id: trayButton
                    required property var modelData
                    readonly property var trayItem: modelData
                    width: 34
                    height: 34
                    radius: T.Config.cardRadius
                    antialiasing: true
                    color: trayMouse.containsMouse ? T.Config.onPanel(T.Config.surfaceContainerHigh) : "transparent"

                    IconImage {
                        id: trayIcon
                        anchors.centerIn: parent
                        implicitSize: T.Config.barIconSize
                        source: dash.trayIconSource(trayButton.trayItem)
                        visible: status === Image.Ready
                    }
                    Text {
                        visible: !trayIcon.visible
                        anchors.centerIn: parent
                        text: String(trayButton.trayItem?.id || "?").charAt(0).toUpperCase()
                        color: T.Config.surfaceText
                        font.pixelSize: T.Config.fontSizeSubtext
                    }

                    QsMenuAnchor {
                        id: trayMenu
                        menu: trayButton.trayItem ? trayButton.trayItem.menu : null
                        onVisibleChanged: dash.stopHide = visible
                        anchor {
                            item: trayButton
                            edges: Edges.Left | Edges.Bottom
                            gravity: Edges.Right | Edges.Bottom
                            adjustment: PopupAdjustment.FlipX
                        }
                    }

                    MouseArea {
                        id: trayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            const item = trayButton.trayItem;
                            if (mouse.button === Qt.LeftButton && !item.onlyMenu) item.activate();
                            else if (item.hasMenu) trayMenu.open();
                        }
                    }
                }
            }
        }

        // Bound, so the sound and microphone tiles can read and set their volume and mute.
        PwObjectTracker {
            objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource].filter(node => node !== null)
        }

        // Without a battery there is no battery page, so the power profile stays out here.
        ComponentSplitter {
            visible: desktopProfile.visible
        }

        PowerProfileRow {
            id: desktopProfile
            visible: !S.BatteryService.hasBattery && S.PowerProfile.available
        }

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

    // The battery's tile opens this: the level in full, and the power profile.
    ColumnLayout {
        visible: dash.page === "battery"
        Layout.fillWidth: true
        spacing: T.Config.popupLayoutSpacing

        BackHeader {}
        BatteryLevel {
            visible: S.BatteryService.hasBattery
        }
        ComponentSplitter {}
        PowerProfileRow {}
        ComponentSpacer {}
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
    Process {
        id: colorPicker
        command: ["hyprpicker", "-a"]
    }

    // A tray item's icon as a URL IconImage can load. The same unpicking the drawer does: an icon
    // name with a ?path= appended is a file in that directory.
    function trayIconSource(item) {
        const icon = item && item.icon;
        if (typeof icon !== "string" && !(icon instanceof String)) return "";
        if (icon === "") return "";
        if (icon.includes("?path=")) {
            const split = icon.split("?path=");
            if (split.length !== 2) return icon;
            const name = split[0];
            return `file://${split[1]}/${name.substring(name.lastIndexOf("/") + 1)}`;
        }
        if (icon.startsWith("/")) return `file://${icon}`;
        return icon;
    }

    // A tool or service in the compact bar's menu: an icon over a word, lit like a tile while it
    // has something waiting.
    component ToolButton: Rectangle {
        id: tool
        property string icon
        property string label
        property bool active: false
        signal activated()

        Layout.fillWidth: true
        implicitHeight: 58
        radius: T.Config.cardRadius
        antialiasing: true
        color: active ? T.Config.accentLightShade
            : toolMouse.containsMouse ? T.Config.onPanel(T.Config.surfaceContainerHigh) : T.Config.onPanel(T.Config.surfaceContainer)
        border.width: active ? 1 : 0
        border.color: T.Config.accent

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: tool.icon
                color: tool.active ? T.Config.accent : T.Config.surfaceText
                font.pixelSize: T.Config.barIconSize
                font.family: T.Config.fontFamily
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: tool.label
                color: T.Config.inactive
                font.pixelSize: T.Config.fontSizeSubtext
            }
        }

        MouseArea {
            id: toolMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tool.activated()
        }
    }

    // A line in the Attention section: what it is, and a click to deal with it.
    component AttentionRow: Rectangle {
        id: row
        property string icon
        property string title
        property string action: "Open"
        signal activated()

        Layout.fillWidth: true
        implicitHeight: 36
        radius: T.Config.cardRadius
        antialiasing: true
        color: rowMouse.containsMouse ? T.Config.onPanel(T.Config.surfaceContainerHigh) : T.Config.accentLightShade

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: T.Config.popupPadding
            anchors.rightMargin: T.Config.popupPadding
            spacing: T.Config.layoutMarginSmall

            Text {
                text: row.icon
                color: T.Config.accent
                font.pixelSize: T.Config.barIconSize
                font.family: T.Config.fontFamily
            }
            Text {
                Layout.fillWidth: true
                text: row.title
                color: T.Config.surfaceText
                font.pixelSize: T.Config.fontSizeNormal
                elide: Text.ElideRight
            }
            Text {
                text: row.action + "  ›"
                color: T.Config.inactive
                font.pixelSize: T.Config.fontSizeSubtext
            }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.activated()
        }
    }

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
            : tileMouse.containsMouse ? T.Config.onPanel(T.Config.surfaceContainerHigh) : T.Config.onPanel(T.Config.surfaceContainer)
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
                else if (tile.detailPage.length > 0) dash.goTo(tile.detailPage);
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
                    onClicked: dash.goTo(tile.detailPage)
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
        color: chevMouse.containsMouse ? T.Config.onPanel(T.Config.surfaceContainerHigh) : "transparent"

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
        color: backMouse.containsMouse ? T.Config.onPanel(T.Config.surfaceContainerHigh) : "transparent"

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
            onClicked: dash.goTo("main")
        }
    }
}
