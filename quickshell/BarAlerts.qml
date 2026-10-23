import QtQuick
import QtQuick.Layouts
import qs.modules.localsend
import qs.modules.nix
import qs.modules.notifications
import qs.modules.system
import qs.modules.tailscale
import qs.popups
import qs.services as S

RowLayout {
    id: alerts

    property bool expanded: false
    property bool withNotifications: false
    property Item panelTrigger: null
    visible: panelTrigger === null

    readonly property bool panelOpen: shown(localSendPanel) || shown(tailscaleNetworkPanel)
        || shown(nixPanel) || shown(firmwarePanel)
    function shown(panel) {
        return panel !== null && panel !== undefined && panel.open && panel.visible;
    }

    readonly property bool showIdleAlert: S.StayAwake.enabled
    readonly property bool showNixAlert: S.NixUpdates.hasUpdates || (expanded && S.NixUpdates.available)
    readonly property bool showTailscaleAlert: S.Tailscale.hasIncomingFiles || (expanded && S.Tailscale.available)
    readonly property bool showLocalSendAlert: S.LocalSend.hasIncomingFiles || (expanded && S.LocalSend.connected)

    NixTrigger {
        id: nixUpdates
        Layout.alignment: Qt.AlignVCenter
        visible: S.NixUpdates.connected && alerts.showNixAlert
        popup: nixPanel
    }
    FirmwareTrigger {
        id: firmwareUpdates
        Layout.alignment: Qt.AlignVCenter
        popup: firmwarePanel
    }
    IdleInhibitorToggle {
        Layout.alignment: Qt.AlignVCenter
        visible: S.StayAwake.connected && alerts.showIdleAlert
    }
    LocalSendNetwork {
        id: localSend
        Layout.alignment: Qt.AlignVCenter
        visible: alerts.showLocalSendAlert
        popup: localSendPanel
    }
    TailscaleNetwork {
        id: tailNet
        Layout.alignment: Qt.AlignVCenter
        visible: alerts.showTailscaleAlert
        popup: tailscaleNetworkPanel
    }

    Loader {
        Layout.alignment: Qt.AlignVCenter
        active: alerts.withNotifications
        visible: active && item !== null && item.implicitWidth > 0
        Layout.preferredWidth: item ? item.implicitWidth : 0
        Layout.preferredHeight: item ? item.implicitHeight : 0
        sourceComponent: Component {
            RowLayout {
                spacing: 0
                NotificationIndicator {
                    id: notificationIndicator
                    popup: notificationPanel
                }
                NotificationPanel {
                    id: notificationPanel
                    trigger: alerts.panelTrigger || notificationIndicator
                }
            }
        }
    }

    TailscalePanel {
        id: tailscaleNetworkPanel
        trigger: alerts.panelTrigger || tailNet
    }
    LocalSendPanel {
        id: localSendPanel
            trigger: alerts.panelTrigger || localSend
    }
    NixPanel {
        id: nixPanel
        trigger: alerts.panelTrigger || nixUpdates
    }
    FirmwarePanel {
        id: firmwarePanel
            trigger: alerts.panelTrigger || firmwareUpdates
    }
}
