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
        readonly property bool servicePopupOpen: (homeAssistantPanel.open && homeAssistantPanel.visible) || (localSendPanel.open && localSendPanel.visible) || (tailscaleNetworkPanel.open && tailscaleNetworkPanel.visible) || (capturePanel.open && capturePanel.visible) || (recordPanel.open && recordPanel.visible) || (nixPanel.open && nixPanel.visible) || (firmwarePanel.open && firmwarePanel.visible)

        readonly property int drawerSpacing: Math.max(4, Math.round(T.Config.barModuleSpacing / 2))
        readonly property bool wantsExpanded: hovered || menuOpen || servicePopupOpen
        readonly property bool showLocalSendAlert: S.LocalSend.hasIncomingFiles || (expanded && S.LocalSend.connected)
        // Updates waiting are worth seeing with the drawer shut; a system that is up to date is
        // only worth a look when the drawer is open anyway.
        // Stay awake is an alert and nothing else: it says the machine is being held awake, which
        // has consequences you cannot see -- a laptop that never sleeps in a bag -- and is not
        // worth an icon saying it is not happening. Night mode has no alert: a warm screen is its
        // own indicator. Neither joins the drawer on expand; the system menu is where you go to
        // turn them on.
        readonly property bool showIdleAlert: S.StayAwake.enabled
        readonly property bool showNixAlert: S.NixUpdates.hasUpdates || (expanded && S.NixUpdates.available)
        readonly property bool showTailscaleAlert: S.Tailscale.hasIncomingFiles || (expanded && S.Tailscale.available)
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
        property int alertExtent: alertItems.implicitWidth > 0 ? alertItems.implicitWidth + drawerSpacing : 0
        readonly property int toolsExtent: drawerItems.implicitWidth > 0 ? drawerItems.implicitWidth + drawerSpacing : 0
        property real revealProgress: expanded ? 1 : 0

        implicitWidth: chevron.implicitWidth + alertExtent + toolsExtent * revealProgress

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
            anchors.rightMargin: alertItems.width > 0 ? drawer.drawerSpacing : 0
            anchors.verticalCenter: parent.verticalCenter
            spacing: drawer.drawerSpacing

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

        RowLayout {
            id: alertItems
            anchors.right: chevron.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: drawer.drawerSpacing

            NixTrigger {
                id: nixUpdates
                Layout.alignment: Qt.AlignVCenter
                visible: S.NixUpdates.connected && drawer.showNixAlert
                popup: nixPanel
            }
            FirmwareTrigger {
                id: firmwareUpdates
                Layout.alignment: Qt.AlignVCenter
                popup: firmwarePanel
            }
            IdleInhibitorToggle {
                Layout.alignment: Qt.AlignVCenter
                visible: S.StayAwake.connected && drawer.showIdleAlert
            }
            LocalSendNetwork {
                id: localSend
                Layout.alignment: Qt.AlignVCenter
                visible: drawer.showLocalSendAlert
                popup: localSendPanel
            }
            TailscaleNetwork {
                id: tailNet
                Layout.alignment: Qt.AlignVCenter
                visible: drawer.showTailscaleAlert
                popup: tailscaleNetworkPanel
            }
        }

        Rectangle {
            id: chevron
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
    //   dashboard   one status cluster -- one pill, one click -- opening DashboardPanel, which
    //               holds everything below on pages of its own, and the power actions
    //   individual  an icon each, each opening its own panel, and a power icon for the system menu
    //
    // Only the chosen one exists. Both answer to the same panel names ("wifi", "audio", "system",
    // ...), so a keybinding opens whichever is in use -- and two at once would leave PopupManager
    // with two panels under one name.
    Loader {
        Layout.alignment: Qt.AlignVCenter
        active: T.Config.statusStyle === "dashboard"
        sourceComponent: dashboardStatus
    }

    Loader {
        Layout.alignment: Qt.AlignVCenter
        active: T.Config.statusStyle !== "dashboard"
        sourceComponent: individualStatus
    }

    BarFill {}

    Component {
        id: dashboardStatus

        // The bell, in front of the cluster: notifications are not part of quick settings, and
        // keep their own panel.
        RowLayout {
            spacing: 0

            NotificationIndicator {
                id: clusterNotificationIndicator
                popup: clusterNotificationPanel
            }
            NotificationPanel {
                id: clusterNotificationPanel
                trigger: clusterNotificationIndicator
            }

            // The icons inside are the same modules as the individual style's, made inert: no pill,
            // no click. The cluster draws one pill round all of them and takes the click itself.
            Rectangle {
                id: statusCluster
                implicitWidth: clusterRow.implicitWidth
                implicitHeight: clusterRow.implicitHeight
                radius: T.Config.popupRadius
                antialiasing: true
                color: dashboardPanel.open || clusterMouse.containsMouse ? T.Config.onBar(T.Config.surfaceContainer) : "transparent"

                RowLayout {
                    id: clusterRow
                    spacing: 0

                    WifiNetwork {
                        mouseEnabled: false
                        color: "transparent"
                        popup: dashboardPanel
                    }
                    EthernetNetwork {
                        mouseEnabled: false
                        color: "transparent"
                        popup: dashboardPanel
                    }
                    Bluetooth {
                        mouseEnabled: false
                        color: "transparent"
                        popup: dashboardPanel
                    }
                    Volume {
                        mouseEnabled: false
                        color: "transparent"
                        popup: dashboardPanel
                    }
                    Battery {
                        mouseEnabled: false
                        color: "transparent"
                        popup: dashboardPanel
                    }
                }

                MouseArea {
                    id: clusterMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (dashboardPanel.open) {
                            dashboardPanel.hidePanel();
                        } else {
                            S.PopupManager.closeOthers(dashboardPanel);
                            dashboardPanel.page = "main";
                            dashboardPanel.showPanel();
                        }
                    }
                }

                DashboardPanel {
                    id: dashboardPanel
                    trigger: statusCluster
                }
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

            WifiNetworkPanel {
                id: wifiNetworkPanel
                trigger: wifiNet
            }
            EthernetNetworkPanel {
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

    TailscaleNetworkPanel {
        id: tailscaleNetworkPanel
        trigger: tailNet
    }

    LocalSendPanel {
        id: localSendPanel
        trigger: localSend
    }

    CapturePanel {
        id: capturePanel
        trigger: capture
    }

    RecordPanel {
        id: recordPanel
        trigger: recordTool
    }

    NixPanel {
        id: nixPanel
        trigger: nixUpdates
    }

    FirmwarePanel {
        id: firmwarePanel
        trigger: firmwareUpdates
    }

    HomeAssistantPanel {
        id: homeAssistantPanel
        trigger: hass
    }
}
