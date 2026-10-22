import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.commonwidgets
import qs.modules
import qs.modules.audio
import qs.modules.battery
import qs.modules.bluetooth
import qs.modules.ethernet
import qs.modules.tailscale
import qs.modules.localsend
import qs.modules.capture
import qs.modules.nix
import qs.modules.system
import qs.modules.homeassistant
import qs.modules.wifi
import qs.modules.notifications
import qs.modules.controlcenter
import qs.popups
import qs.services as S
import qs.theme as T

RowLayout {
    spacing: 0
    BarFill {}

    Item {
        id: drawer
        Layout.alignment: Qt.AlignVCenter
        property bool expanded: false
        property bool menuOpen: false
        property bool hovered: hoverHandler.hovered
        readonly property bool servicePopupOpen: drawer.shown(homeAssistantPanel) || drawer.shown(capturePanel) || drawer.shown(recordPanel) || (alertItems.item !== null && alertItems.item.panelOpen)
        function shown(panel) {
            return panel !== null && panel !== undefined && panel.open && panel.visible;
        }

        readonly property int drawerSpacing: Math.max(4, Math.round(T.Config.barModuleSpacing / 2))
        // Compact (T.Config.barCompact), no drawer at all: the alerts are a dot on the capsule and
        // a list in its menu instead (compactStatus), and the tools and tray are left out.
        readonly property bool compact: T.Config.barCompact
        readonly property bool wantsExpanded: !compact && (hovered || menuOpen || servicePopupOpen)
        // The drawer's width is measured from what is actually in it rather than counted.
        //
        // Counting items and multiplying by an icon width only holds while every item is an icon:
        // the recording indicator carries a clock beside its dot, and a tray that gains an item
        // has to be counted somewhere else again. Measuring means any number of alerts -- a
        // recording, a Taildrop and a LocalSend transfer at once -- simply sit next to each other,
        // and the drawer is as wide as they need.
        //
        // Alerts are always on show, so their width belongs to the collapsed drawer. That width is
        // animated because the set changes on expand -- Tailscale and LocalSend show themselves
        // when the drawer opens even with nothing waiting -- and a jump there reads as a glitch.
        property int alertExtent: alertItems.item && alertItems.item.implicitWidth > 0 ? alertItems.item.implicitWidth + drawerSpacing : 0
        readonly property int toolsExtent: drawerItems.implicitWidth > 0 ? drawerItems.implicitWidth + drawerSpacing : 0
        property real revealProgress: expanded ? 1 : 0

        implicitWidth: (compact ? 0 : chevron.implicitWidth) + alertExtent + toolsExtent * revealProgress

        Behavior on alertExtent {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        implicitHeight: T.Config.barHeight
        clip: true

        Behavior on revealProgress {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        function updateExpanded() {
            if (wantsExpanded) {
                collapseTimer.stop();
                expanded = true;
            } else {
                collapseTimer.restart();
            }
        }

        onWantsExpandedChanged: updateExpanded()
        onMenuOpenChanged: updateExpanded()
        onServicePopupOpenChanged: updateExpanded()

        Timer {
            id: collapseTimer
            interval: 120
            repeat: false
            onTriggered: if (!drawer.wantsExpanded) drawer.expanded = false
        }

        HoverHandler {
            id: hoverHandler
            onHoveredChanged: drawer.updateExpanded()
        }

        RowLayout {
            id: drawerItems
            anchors.right: alertItems.left
            anchors.rightMargin: drawer.alertExtent > 0 ? drawer.drawerSpacing : 0
            anchors.verticalCenter: parent.verticalCenter
            spacing: drawer.drawerSpacing
            visible: !drawer.compact

            Repeater {
                model: S.SystemTray.trayItems

                delegate: Rectangle {
                    id: trayDelegate
                    Layout.alignment: Qt.AlignVCenter
                    property var trayItem: modelData
                    property string iconSource: {
                        let icon = trayItem && trayItem.icon;
                        if (typeof icon === 'string' || icon instanceof String) {
                            if (icon === "") return "";
                            if (icon.includes("?path=")) {
                                const split = icon.split("?path=");
                                if (split.length !== 2) return icon;
                                const name = split[0];
                                const path = split[1];
                                let fileName = name.substring(name.lastIndexOf("/") + 1);
                                return `file://${path}/${fileName}`;
                            }
                            if (icon.startsWith("/") && !icon.startsWith("file://")) {
                                return `file://${icon}`;
                            }
                            return icon;
                        }
                        return "";
                    }

                    implicitWidth: T.Config.barIconSize + T.Config.barModuleHorizontalPadding
                    implicitHeight: T.Config.barIconSize + T.Config.barModuleVerticalPadding
                    color: trayMouse.containsMouse ? T.Config.onBar(T.Config.surfaceContainer) : "transparent"
                    radius: T.Config.popupRadius
                    antialiasing: true

                    QsMenuAnchor {
                        id: trayMenu
                        menu: trayDelegate.trayItem ? trayDelegate.trayItem.menu : null
                        onVisibleChanged: {
                            drawer.menuOpen = visible;
                        }
                        anchor {
                            item: trayIconImg
                            edges: Edges.Left | Edges.Bottom
                            gravity: Edges.Right | Edges.Bottom
                            adjustment: PopupAdjustment.FlipX
                        }
                    }

                    IconImage {
                        id: trayIconImg
                        width: T.Config.barIconSize
                        height: T.Config.barIconSize
                        anchors.centerIn: parent
                        source: trayDelegate.iconSource
                        asynchronous: true
                        smooth: true
                        mipmap: true
                        visible: status === Image.Ready
                    }

                    Text {
                        visible: !trayIconImg.visible
                        text: {
                            const itemId = trayDelegate.trayItem?.id || "";
                            if (!itemId) return "?";
                            return itemId.charAt(0).toUpperCase();
                        }
                        font.pixelSize: T.Config.barIconSize * 0.6
                        font.family: T.Config.fontFamily
                        anchors.centerIn: parent
                        color: T.Config.surfaceText
                    }

                    MouseArea {
                        id: trayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton && !trayDelegate.trayItem.onlyMenu) {
                                trayDelegate.trayItem.activate();
                                return;
                            }
                            if (mouse.button === Qt.RightButton && !trayDelegate.trayItem.onlyMenu) {
                                trayMenu.open();
                                return;
                            }
                        }
                    }
                }
            }
            Clipboard {
                Layout.alignment: Qt.AlignVCenter
            }
            Colorpicker {
                Layout.alignment: Qt.AlignVCenter
            }
            CaptureTrigger {
                id: capture
                Layout.alignment: Qt.AlignVCenter
                popup: capturePanel
            }
            RecordTrigger {
                id: recordTool
                Layout.alignment: Qt.AlignVCenter
                popup: recordPanel
            }
            HomeAssistantWidget {
                id: hass
                Layout.alignment: Qt.AlignVCenter
                popup: homeAssistantPanel
            }
        }

        Loader {
            id: alertItems
            anchors.right: chevron.left
            anchors.verticalCenter: parent.verticalCenter
            active: !drawer.compact
            sourceComponent: Component {
                BarAlerts {
                    spacing: drawer.drawerSpacing
                    expanded: drawer.expanded
                }
            }
        }

        Rectangle {
            id: chevron
            visible: !drawer.compact
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: chevronMouse.containsMouse ? T.Config.onBar(T.Config.surfaceContainer) : "transparent"
            radius: T.Config.popupRadius
            antialiasing: true
            implicitWidth: chevronInner.implicitWidth + T.Config.barModuleHorizontalPadding
            implicitHeight: chevronInner.implicitHeight + T.Config.barModuleVerticalPadding
            z: 1

            Rectangle {
                id: chevronInner
                implicitWidth: T.Config.barIconSize
                implicitHeight: T.Config.barIconSize
                color: "transparent"
                anchors.centerIn: parent

                Text {
                    text: "\uf053"
                    font.pixelSize: T.Config.barIconSize
                    font.family: T.Config.fontFamily
                    anchors.centerIn: parent
                    color: T.Config.surfaceText
                    rotation: drawer.expanded ? 180 : 0

                    Behavior on rotation {
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }
                }
            }

            MouseArea {
                id: chevronMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: drawer.updateExpanded()
            }
        }
    }

    // While recording, the way to stop it, just left of the status icons and outside the drawer:
    // it should be one click away, not behind a hover that slides the drawer open under the pointer.
    RecordingIndicator {
        Layout.alignment: Qt.AlignVCenter
    }

    // Connection, sound, battery and the session, in one of two styles (T.Config.statusStyle):
    //
    //   dashboard   the status capsule (compactStatus, below) -- network, battery, the time and
    //               an attention dot -- opening DashboardPanel, which holds everything else on
    //               pages of its own; the drawer, alert icons, bell and clock go (T.Config.barCompact)
    //   individual  an icon each, each opening its own panel, and a power icon for the system menu
    //
    // Only the chosen one exists. Both answer to the same panel names ("wifi", "audio", "system",
    // ...), so a keybinding opens whichever is in use -- and two at once would leave PopupManager
    // with two panels under one name.
    // A Loader keeps the size of the last thing it held after it is switched off, so the style
    // switched away from would go on taking its old width as a gap. Hidden while off, the row
    // leaves it out; while on, it is sized by what it holds.
    Loader {
        Layout.alignment: Qt.AlignVCenter
        active: !T.Config.barCompact
        visible: active
        Layout.preferredWidth: item ? item.implicitWidth : 0
        Layout.preferredHeight: item ? item.implicitHeight : 0
        sourceComponent: individualStatus
    }

    // The compact bar's (T.Config.barCompact) whole right end: the network and battery at a glance,
    // the time, and a dot on its corner when something wants attention. One click opens quick
    // settings, which holds everything else -- the alerts, the tools and the tray included.
    Loader {
        id: compactLoader
        Layout.alignment: Qt.AlignVCenter
        active: T.Config.barCompact
        visible: active
        Layout.preferredWidth: item ? item.implicitWidth : 0
        Layout.preferredHeight: item ? item.implicitHeight : 0
        sourceComponent: compactStatus
    }

    BarFill {}

    Component {
        id: compactStatus

        Rectangle {
            id: capsule
            implicitWidth: capsuleRow.implicitWidth + T.Config.barModuleHorizontalPadding
            implicitHeight: T.Config.barIconSize + T.Config.barModuleVerticalPadding
            radius: T.Config.popupRadius
            antialiasing: true
            // On the ledge, no pill: a filled chip on a shape that otherwise has none reads as a
            // stray button. Hover brightens its text instead, as the workspace numbers do, and the
            // panel itself says it is open.
            readonly property bool chipless: T.Config.barIsLedge
            readonly property bool lit: chipless && capsuleMouse.containsMouse
            color: !chipless && ((capsule.dashboard && capsule.dashboard.open) || capsuleMouse.containsMouse) ? T.Config.onBar(T.Config.surfaceContainer) : "transparent"

            SystemClock {
                id: capsuleClock
                precision: SystemClock.Minutes
            }

            RowLayout {
                id: capsuleRow
                anchors.centerIn: parent
                spacing: T.Config.barIconTextSpacing + 2

                // The status glyphs say this is the system menu and not only a clock -- and are
                // worth a glance on their own. Dimmed a little, so the time leads.
                Text {
                    text: S.Network.currentNetworkIcon
                    visible: text.length > 0
                    color: capsule.lit ? T.Config.active : T.Config.inactive
                    font.pixelSize: T.Config.barSmallIconSize
                    font.family: T.Config.fontFamily
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: S.BatteryService.batteryIcon()
                    visible: S.BatteryService.hasBattery
                    color: capsule.lit ? T.Config.active : T.Config.inactive
                    font.pixelSize: T.Config.barSmallIconSize
                    font.family: T.Config.fontFamily
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    // Unpadded, as the full bar's clock and the lock screen have it.
                    text: Qt.formatDateTime(capsuleClock.date, "h:mm AP")
                    color: capsule.lit ? T.Config.active : T.Config.surfaceText
                    font.pixelSize: T.Config.barClockSize
                    font.family: T.Config.fontFamily
                    font.weight: Font.Medium
                    Layout.alignment: Qt.AlignVCenter
                }

            }

            // Something wants attention: updates, the machine held awake, files coming in, unread
            // notifications. A badge on the capsule's corner, as on an app icon; which, and the way
            // to each, are in the menu.
            Rectangle {
                visible: capsule.dashboard !== null && capsule.dashboard.needsAttention
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 2
                anchors.topMargin: 2
                width: 7
                height: 7
                radius: 3.5
                antialiasing: true
                color: T.Config.accent
            }

            MouseArea {
                id: capsuleMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const dashboard = capsule.dashboard;
                    if (!dashboard) return;
                    if (dashboard.open) {
                        dashboard.hidePanel();
                    } else {
                        S.PopupManager.closeOthers(dashboard);
                        dashboard.page = "main";
                        dashboard.showPanel();
                    }
                }
            }

            // Quick settings.
            readonly property var dashboard: dashboardPanel
            DashboardPanel {
                id: dashboardPanel
                trigger: capsule
            }

            // The alerts' panels, opened from the menu's list, hanging from the capsule.
            BarAlerts {
                withNotifications: true
                panelTrigger: capsule
            }
        }
    }

    Component {
        id: individualStatus

        RowLayout {
            spacing: 0

            WifiNetwork {
                id: wifiNet
                popup: wifiNetworkPanel
            }
            EthernetNetwork {
                id: ethNet
                popup: ethernetNetworkPanel
            }
            Bluetooth {
                id: bluet
                popup: bluetoothPanel
            }
            Volume {
                id: vol
                popup: audioPanel
            }
            Battery {
                id: battery
                popup: batteryPanel
            }
            NotificationIndicator {
                id: notificationIndicator
                popup: notificationPanel
            }
            SystemOptions {
                id: systemOptions
                popup: systemPanelPopup
            }

            WifiPanel {
                id: wifiNetworkPanel
                trigger: wifiNet
            }
            EthernetPanel {
                id: ethernetNetworkPanel
                    trigger: ethNet
            }
            BluetoothPanel {
                id: bluetoothPanel
                trigger: bluet
            }
            AudioPanel {
                id: audioPanel
                    trigger: vol
            }
            BatteryPanel {
                id: batteryPanel
                trigger: battery
            }
            SystemMenuPanel {
                id: systemPanelPopup
                    trigger: systemOptions
            }
            NotificationPanel {
                id: notificationPanel
                trigger: notificationIndicator
            }
        }
    }

    CapturePanel {
        id: capturePanel
        // Compact, opened from quick settings and hanging from the capsule.
        trigger: compactLoader.item || capture
    }

    RecordPanel {
        id: recordPanel
        // Compact, opened from quick settings and hanging from the capsule.
        trigger: compactLoader.item || recordTool
    }

    HomeAssistantPanel {
        id: homeAssistantPanel
        // Compact, opened from quick settings and hanging from the capsule.
        trigger: compactLoader.item || hass
    }
}
