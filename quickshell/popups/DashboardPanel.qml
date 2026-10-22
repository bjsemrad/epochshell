import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.commonwidgets
import qs.services as S
import qs.theme as T
import qs.popups.pages

// Quick settings, opened from the bar's status capsule: one column of rows. Every switch is a row;
// what needs attention is a row with the tick; the tools and the tray are a line of icons;
// everything with more behind it opens a page in place. It answers to the names of the panels it
// stands in for ("wifi", "audio", ...), opening on the matching page, so keybindings made for the
// individual panels still land somewhere sensible.
HoverPopupWindow {
    id: dash

    // "main", "wifi", "ethernet", "bluetooth", "audio", "battery", "power", "appearance", "theme".
    property string page: "main"

    popupWidth: 480

    readonly property var pageForName: ({
        "wifi": "wifi",
        "ethernet": "ethernet",
        "bluetooth": "bluetooth",
        "audio": "audio",
        "battery": "battery"
    })

    // Called by PopupManager for a named open, in place of showPanel.
    function showPage(name) {
        page = pageForName[name] || "main";
        showPanel();
    }

    // What wants attention, for the capsule's dot and the rows below.
    readonly property bool needsAttention: S.NixUpdates.hasUpdates || S.SystemInfo.hasFirmwareUpdates
        || S.StayAwake.enabled || S.LocalSend.hasIncomingFiles || S.Tailscale.hasIncomingFiles
        || S.Notifications.unreadCount > 0

    // Moving between pages from a click. A page can be much shorter than the one it replaces, and
    // the panel shrinks out from under the pointer, which reads as the pointer leaving and would
    // close it on the spot; so the panel holds open through the switch.
    function goTo(name) {
        dash.stopHide = true;
        dash.page = name;
        pageSettle.restart();
        if (name === "power") Qt.callLater(powerPage.focusFirst);
    }
    function back() {
        goTo(page === "theme" ? "appearance" : "main");
    }

    Timer {
        id: pageSettle
        interval: 400
        onTriggered: dash.stopHide = false
    }

    // Opening another panel by name from a row here: this one gives way to it.
    function openOther(name) {
        S.PopupManager.openPanel(name);
    }

    property string username: ""
    property string hostname: ""
    Process {
        command: ["whoami"]
        running: true
        stdout: SplitParser { onRead: data => dash.username = data.trim() }
    }
    Process {
        command: ["hostname"]
        running: true
        stdout: SplitParser { onRead: data => dash.hostname = data.trim() }
    }
    Process {
        id: colorPicker
        command: ["hyprpicker", "-a"]
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    onOpenChanged: {
        S.PowerProfile.watching = open;
        if (open) {
            S.PowerProfile.refresh();
            S.SystemInfo.refresh();
            S.NightLight.refresh();
            S.StayAwake.refresh();
            S.Network.refresh();
            S.PopupManager.closeOthers(dash);
        } else {
            page = "main";
        }
    }

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

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource].filter(node => node !== null)
    }

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

    // The main page's rows as a table: every name in a column this wide, so the gauges and the
    // details after them start at the same place.
    TextMetrics {
        id: longestName
        font.family: Readout.font
        font.pixelSize: Readout.valueSize
        text: "notifications"
    }
    readonly property real valueColumn: Math.ceil(longestName.width) + 10

    readonly property bool wired: S.Network.ethernetConnected || (!S.Network.wifiDevice && S.Network.ethernetDevice)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    ColumnLayout {
        id: pages
        Layout.fillWidth: true
        spacing: 0

        // Left or Escape: back a page, or close from the main one. Rows pass what they do not
        // use up to here.
        Keys.onEscapePressed: dash.page === "main" ? dash.hidePanel() : dash.back()
        Keys.onLeftPressed: if (dash.page !== "main") dash.back()

        // ===========================================================================================
        // Main page
        // ===========================================================================================

        ColumnLayout {
            visible: dash.page === "main"
            Layout.fillWidth: true
            spacing: 0

            // Who, where, when -- and the way out.
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 4
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    text: [dash.username, [dash.hostname, S.SystemInfo.kernel].filter(x => x && x.length > 0).join(" "),
                        Qt.formatDate(clock.date, "ddd d MMM").toLowerCase()].filter(x => x && x.length > 0).join(" · ")
                    color: Readout.detail
                    font.pixelSize: Readout.detailSize
                    font.family: Readout.font
                    elide: Text.ElideRight
                }
                ReadoutIcon {
                    icon: "󰌾"
                    name: "lock"
                    onClicked: {
                        S.PopupManager.closeAll();
                        S.Lock.lock();
                    }
                }
                ReadoutIcon {
                    icon: "⏻"
                    name: "power"
                    onClicked: dash.goTo("power")
                }
            }

            // Notifications first: the thing most often opened from here. Always a row -- "none" when
            // there is nothing -- with the tick and the count while any are unread.
            ReadoutRow {
                icon: S.Notifications.doNotDisturb ? "󰂛" : S.Notifications.unreadCount > 0 ? "󰂚" : "󰂜"
                value: "notifications"
                valueWidth: dash.valueColumn
                detail: S.Notifications.doNotDisturb ? "do not disturb" : ""
                status: S.Notifications.unreadCount > 0 ? S.Notifications.unreadCount + " new"
                    : S.Notifications.historyModel.count > 0 ? S.Notifications.historyModel.count + "" : "none"
                active: S.Notifications.unreadCount > 0
                hasPage: true
                onOpened: dash.openOther("notifications")
            }

            // --- Connections ---
            // A click opens the connection's page, where its header switches it on and off: these
            // have a network to pick, so the page is what a click is usually after.
            ReadoutRow {
                visible: dash.wired
                icon: S.Network.currentEthernetIcon
                value: "ethernet"
                valueWidth: dash.valueColumn
                detail: S.Network.ethernetConnectedIP
                status: S.Network.ethernetConnected ? "up" : "down"
                active: S.Network.ethernetConnected
                hasPage: true
                onOpened: dash.goTo("ethernet")
            }
            ReadoutRow {
                visible: !dash.wired && S.Network.wifiDevice
                icon: S.Network.wifiEnabled ? S.Network.currentWifiIcon : "󰤮"
                value: "wi-fi"
                valueWidth: dash.valueColumn
                detail: S.Network.wifiConnected ? S.Network.ssid : ""
                active: S.Network.wifiEnabled
                hasSwitch: true
                onToggled: S.Network.disableWifi(!S.Network.wifiEnabled)
                hasPage: true
                onOpened: dash.goTo("wifi")
            }
            ReadoutRow {
                icon: S.Bluetooth.currentBluetoothIcon
                value: "bluetooth"
                valueWidth: dash.valueColumn
                detail: {
                    const connected = (S.Bluetooth.pairedDevices || []).filter(d => d.connected);
                    if (connected.length === 0) return "";
                    return connected.length === 1 ? (connected[0].name || connected[0].deviceName || "") : connected.length + " connected";
                }
                active: S.Bluetooth.enabled
                hasSwitch: true
                onToggled: S.Bluetooth.toggle(!S.Bluetooth.enabled)
                hasPage: true
                onOpened: dash.goTo("bluetooth")
            }
            // A network, not a tool: it is a connection you are on or off (switched in its panel).
            ReadoutRow {
                visible: S.Tailscale.available
                icon: S.Tailscale.currentTailscaleIcon
                value: "tailscale"
                valueWidth: dash.valueColumn
                detail: S.Tailscale.connected ? S.Tailscale.connectedIP : ""
                active: S.Tailscale.connected
                hasSwitch: true
                onToggled: S.Tailscale.toggle(!S.Tailscale.connected)
                hasPage: true
                onOpened: dash.openOther("tailscale")
            }

            // --- Sound ---
            ReadoutRow {
                visible: dash.sink !== null
                readonly property bool muted: dash.sink && dash.sink.audio ? dash.sink.audio.muted : false
                icon: S.AudioService.currentAudioIcon
                value: "sound"
                valueWidth: dash.valueColumn
                detail: dash.sink ? (dash.sink.description || "") : ""
                active: !muted
                toggleable: true
                hasPage: true
                onToggled: if (dash.sink && dash.sink.audio) dash.sink.audio.muted = !dash.sink.audio.muted
                onOpened: dash.goTo("audio")

                ReadoutGauge {
                    value: dash.sink && dash.sink.audio ? dash.sink.audio.volume : 0
                    muted: dash.sink !== null && dash.sink.audio !== null && dash.sink.audio.muted
                    onMoved: v => { if (dash.sink && dash.sink.audio) dash.sink.audio.volume = v; }
                }
            }
            ReadoutRow {
                visible: dash.source !== null
                readonly property bool muted: dash.source && dash.source.audio ? dash.source.audio.muted : false
                icon: muted ? "󰍭" : "󰍬"
                value: "mic"
                valueWidth: dash.valueColumn
                detail: dash.source ? (dash.source.description || "") : ""
                active: !muted
                toggleable: true
                hasPage: true
                onToggled: if (dash.source && dash.source.audio) dash.source.audio.muted = !dash.source.audio.muted
                onOpened: dash.goTo("audio")
            }

            // --- The machine ---
            ReadoutRow {
                icon: S.NightLight.icon
                value: "night mode"
                valueWidth: dash.valueColumn
                detail: S.NightLight.enabled ? S.NightLight.temperature + "k" : ""
                status: S.NightLight.available ? "" : "unavailable"
                active: S.NightLight.enabled
                interactive: S.NightLight.available
                toggleable: true
                onToggled: S.NightLight.set(!S.NightLight.enabled)
            }
            ReadoutRow {
                visible: S.StayAwake.available
                icon: S.StayAwake.icon
                value: "stay awake"
                valueWidth: dash.valueColumn
                detail: S.StayAwake.enabled ? "held for " + S.StayAwake.held : ""
                active: S.StayAwake.enabled
                toggleable: true
                onToggled: S.StayAwake.set(!S.StayAwake.enabled)
            }
            ReadoutRow {
                visible: S.BatteryService.hasBattery || S.PowerProfile.available
                icon: S.BatteryService.hasBattery ? S.BatteryService.batteryIcon() : "󰓅"
                value: S.BatteryService.hasBattery ? "battery" : "power"
                valueWidth: dash.valueColumn
                detail: S.BatteryService.hasBattery ? S.BatteryService.stateText().toLowerCase() : ""
                status: S.PowerProfile.available ? S.PowerProfile.profileLabel.toLowerCase() : ""
                hasPage: true
                onOpened: dash.goTo("battery")

                ReadoutGauge {
                    visible: S.BatteryService.hasBattery
                    interactive: false
                    value: S.BatteryService.percentage / 100
                }
            }

            // --- What wants attention: only when there is something, each with the tick ---
            ReadoutRow {
                visible: S.NixUpdates.hasUpdates
                icon: S.NixUpdates.icon
                value: "nix"
                valueWidth: dash.valueColumn
                detail: S.NixUpdates.updates === 1 ? "1 input behind" : S.NixUpdates.updates + " inputs behind"
                status: "update"
                active: true
                hasPage: true
                onOpened: dash.openOther("nix")
            }
            ReadoutRow {
                visible: S.SystemInfo.hasFirmwareUpdates
                icon: S.SystemInfo.firmwareIcon
                value: "firmware"
                valueWidth: dash.valueColumn
                detail: S.SystemInfo.firmwareUpdates.length === 1 ? "1 update" : S.SystemInfo.firmwareUpdates.length + " updates"
                status: "update"
                active: true
                hasPage: true
                onOpened: dash.openOther("firmware")
            }
            ReadoutRow {
                visible: S.LocalSend.hasIncomingFiles
                icon: S.LocalSend.icon
                value: "localsend"
                valueWidth: dash.valueColumn
                detail: "incoming files"
                status: "review"
                active: true
                hasPage: true
                onOpened: dash.openOther("localsend")
            }
            ReadoutRow {
                visible: S.Tailscale.hasIncomingFiles
                icon: "󰒄"
                value: "taildrop"
                valueWidth: dash.valueColumn
                detail: "incoming files"
                status: "review"
                active: true
                hasPage: true
                onOpened: dash.openOther("tailscale")
            }

            ReadoutDivider {}

            // Tools on the left -- one-shot actions only -- and the tray on the right.
            RowLayout {
                Layout.fillWidth: true
                spacing: 2

                ReadoutIcon {
                    visible: S.Capture.connected
                    icon: S.Capture.icon
                    name: "capture"
                    onClicked: dash.openOther("capture")
                }
                ReadoutIcon {
                    visible: S.Capture.connected && S.Capture.recordAvailable
                    icon: S.Capture.recording ? "󰙧" : "󰕧"
                    name: S.Capture.recording ? "stop recording" : "record"
                    active: S.Capture.recording
                    onClicked: S.Capture.recording ? S.Capture.stopRecording() : dash.openOther("record")
                }
                ReadoutIcon {
                    icon: "󰨸"
                    name: "clipboard"
                    onClicked: {
                        const launcher = S.PopupManager.launcher;
                        if (!launcher) return;
                        S.PopupManager.closeAll();
                        launcher.openProvider("clipboard");
                    }
                }
                ReadoutIcon {
                    icon: "󰴱"
                    name: "pick colour"
                    onClicked: {
                        dash.hidePanel();
                        colorPicker.running = true;
                    }
                }
                ReadoutIcon {
                    visible: S.LocalSend.connected
                    icon: S.LocalSend.icon
                    name: "send with localsend"
                    onClicked: dash.openOther("localsend")
                }

                Item { Layout.fillWidth: true }

                Repeater {
                    model: S.SystemTray.trayItems
                    delegate: ReadoutIcon {
                        id: trayIcon
                        required property var modelData
                        source: dash.trayIconSource(modelData)
                        icon: String(modelData.id || "?").charAt(0).toUpperCase()
                        name: String(modelData.tooltipTitle || modelData.title || modelData.id || "")
                        onClicked: if (!modelData.onlyMenu) modelData.activate()
                        onSecondaryClicked: if (modelData.hasMenu) trayMenu.open()

                        QsMenuAnchor {
                            id: trayMenu
                            menu: trayIcon.modelData.menu
                            onVisibleChanged: dash.stopHide = visible
                            anchor {
                                item: trayIcon
                                edges: Edges.Left | Edges.Bottom
                                gravity: Edges.Right | Edges.Bottom
                                adjustment: PopupAdjustment.FlipX
                            }
                        }
                    }
                }
            }

            ReadoutDivider {}

            ReadoutRow {
                icon: "󰏘"
                value: "appearance"
                valueWidth: dash.valueColumn
                detail: [T.Config.themeName, S.Wallpaper.current.length > 0 ? S.Wallpaper.displayName(S.Wallpaper.current) : ""]
                    .filter(x => x.length > 0).join(" · ")
                hasPage: true
                onOpened: dash.goTo("appearance")
            }
        }

        // ===========================================================================================
        // Pages
        // ===========================================================================================

        WifiPage {
            visible: dash.page === "wifi"
            showBack: true
            onBack: dash.back()
        }
        EthernetPage {
            visible: dash.page === "ethernet"
            showBack: true
            onBack: dash.back()
        }
        BluetoothPage {
            visible: dash.page === "bluetooth"
            showBack: true
            onBack: dash.back()
        }
        AudioPage {
            visible: dash.page === "audio"
            showBack: true
            onBack: dash.back()
        }
        BatteryPage {
            visible: dash.page === "battery"
            showBack: true
            onBack: dash.back()
        }
        PowerPage {
            id: powerPage
            visible: dash.page === "power"
            showBack: true
            onBack: dash.back()
        }
        AppearancePage {
            visible: dash.page === "appearance"
            showBack: true
            panel: dash
            onBack: dash.back()
            onOpenTheme: dash.goTo("theme")
        }
        ThemePage {
            visible: dash.page === "theme"
            showBack: true
            onBack: dash.back()
        }
    }
}
