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
import qs.modules.overview
import qs.modules.nix
import qs.modules.controlcenter
import qs.modules.notifications
import qs.popups
import qs.theme as T

RowLayout {
    spacing: T.Config.barGroupedModuleSpacing
    // MusicControl {
    //     id: musicControl
    //     popup: musicPanel
    // }
    // GroupedNixUpdates {
    //     id: nixUpdates
    //     popup: nixUpdatePanel
    // }
    Clipboard {}
    ControlCenter {
        id: controlCenter
        popup: T.Config.popupControlCenter ? systemPanelPopup : systemPanel
    }
    GroupedBattery {
        id: groupedBattery
        popup: batteryPanel
    }
    NotificationIndicator {
        id: notificationIndicator
        popup: notificationPanel
    }
    BarFill {}

    BatteryPanel {
        id: batteryPanel
        trigger: groupedBattery
    }
    NotificationPanel {
        id: notificationPanel
        trigger: notificationIndicator
    }
    ControlCenterPanelPopup {
        id: systemPanelPopup
        trigger: controlCenter
    }
    ControlCenterPanel {
        id: systemPanel
        trigger: controlCenter
    }
    // NixUpdatesPanel {
    //     id: nixUpdatePanel
    //     trigger: nixUpdates
    // }
    // MusicPanel {
    //     id: musicPanel
    //     trigger: musicControl
    // }
}
