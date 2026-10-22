import QtQuick
import QtQuick.Layouts
import qs.modules.localsend
import qs.modules.nix
import qs.modules.notifications
import qs.modules.system
import qs.modules.tailscale
import qs.popups
import qs.services as S

// The bar's alerts: icons that are only there when something wants attention -- updates waiting,
// the machine held awake, files coming in -- each with its own panel.
//
// Lives in the right-hand drawer (IndividualBarRight), or out of sight in the compact bar's
// capsule (see panelTrigger). Only one of the two is ever built: the panels register under fixed names
// ("nix", "localsend", ...), and two copies would leave PopupManager with two panels per name.
RowLayout {
    id: alerts

    // The drawer is open: Tailscale, LocalSend and Nix show themselves even with nothing waiting.
    property bool expanded: false
    // The bell too, for the compact bar, where it is not in the status cluster.
    property bool withNotifications: false
    // Set, the icons are not shown and every panel hangs from this instead: the compact bar's
    // capsule, whose dot stands in for them all and whose menu opens them (DashboardPanel).
    property Item panelTrigger: null
    visible: panelTrigger === null

    // One of these panels is open, which holds the drawer open while it is.
    readonly property bool panelOpen: (localSendPanel.open && localSendPanel.visible)
        || (tailscaleNetworkPanel.open && tailscaleNetworkPanel.visible)
        || (nixPanel.open && nixPanel.visible)
        || (firmwarePanel.open && firmwarePanel.visible)

    // Updates waiting are worth seeing with the drawer shut; a system that is up to date is only
    // worth a look when the drawer is open anyway.
    // Stay awake is an alert and nothing else: it says the machine is being held awake, which has
    // consequences you cannot see -- a laptop that never sleeps in a bag -- and is not worth an
    // icon saying it is not happening. Night mode has no alert: a warm screen is its own indicator.
    // Neither joins the drawer on expand; the system menu is where you go to turn them on.
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

    // A Loader for the same reason the alerts are built once: the bell's panel registers as
    // "notifications", and the status cluster has its own bell outside the compact bar.
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

    TailscaleNetworkPanel {
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
