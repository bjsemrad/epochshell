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
import qs.modules.nix
import qs.popups
import qs.theme as T

RowLayout {
    spacing: 0
    BarFill {}
    Battery {
        id: battery
        popup: batteryPanel
    }
    // NixUpdates {
    //     id: nixUpdates
    //     popup: nixUpdatePanel
    // }
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
    SystemOptions {
        id: systemOptions
        Layout.rightMargin: 10
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
    IndividualSystemPanelPopup {
        id: systemPanelPopup
        trigger: systemOptions
    }
    ControlCenterPanel {
        id: systemPanel
        trigger: systemOptions
    }
    // NixUpdatesPanel {
    //     id: nixUpdatePanel
    //     trigger: nixUpdates
    // }
}
