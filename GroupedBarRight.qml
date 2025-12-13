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
import qs.popups

RowLayout {
    spacing: 10
    GroupedBattery {
        id: groupedBattery
        popup: batteryPanel
    }
    ControlCenter {
        id: controlCenter
        popup: systemPanel
    }
    BarFill {}

    BatteryPanel {
        id: batteryPanel
        trigger: groupedBattery
    }
    ControlCenterPanel {
        id: systemPanel
        trigger: controlCenter
    }
}
