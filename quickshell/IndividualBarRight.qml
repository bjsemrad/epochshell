import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules
import qs.modules.audio
import qs.modules.battery
import qs.modules.bluetooth
import qs.modules.ethernet
import qs.modules.systemtray
import qs.modules.tailscale
import qs.modules.wifi
import qs.modules.notifications
import qs.modules.controlcenter
import qs.modules.nix
import qs.popups
import qs.theme as T

RowLayout {
    spacing: 0
    BarFill {}
    Clipboard {}
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
    TailscaleNetwork {
        id: tailNet
        popup: tailscaleNetworkPanel
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
        popup: T.Config.popupControlCenter ? systemPanelPopup : systemPanel
    }
    BarFill {}

    WifiNetworkPanel {
        id: wifiNetworkPanel
        trigger: wifiNet
    }

    EthernetNetworkPanel {
        id: ethernetNetworkPanel
        trigger: ethNet
    }

    TailscaleNetworkPanel {
        id: tailscaleNetworkPanel
        trigger: tailNet
    }

    AudioPanel {
        id: audioPanel
        trigger: vol
    }

    BatteryPanel {
        id: batteryPanel
        trigger: battery
    }

    BluetoothPanel {
        id: bluetoothPanel
        trigger: bluet
    }

    NotificationPanel {
        id: notificationPanel
        trigger: notificationIndicator
    }

    SystemMenuPanel {
        id: systemPanelPopup
        trigger: systemOptions
    }
    ControlCenterPanel {
        id: systemPanel
        trigger: systemOptions
    }
}
