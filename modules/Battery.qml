import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../commonwidgets"

BarIconPopup {
    id: root
    property real percentage: 0
    property bool charging: false

    mouseEnabled: false

    iconText: {
      let pct = Math.round(root.percentage > 0 ? root.percentage * 100 : 1)
      if (pct > 95) return root.charging ? "󰂋" : "󰁹"
      if (pct > 70) return root.charging ? "󰢞" : "󰂀"
      if (pct > 45) return root.charging ? "󰂈" : "󰁽"
      if (pct > 20) return root.charging ? "󰂆" : "󰁻"
      return root.charging ? "󰢜" : "󰁺"
    }

    Component.onCompleted: {
        if (UPower.displayDevice) {
            percentage = UPower.displayDevice.percentage
            charging   = (UPower.displayDevice.state === UPowerDeviceState.Charging)
        }
    }

    Connections {
        target: UPower.displayDevice

        function onPercentageChanged() {
            root.percentage = UPower.displayDevice.percentage
        }

        function onStateChanged() {
            root.charging = (UPower.displayDevice.state === UPowerDeviceState.Charging)
        }
    }
}
