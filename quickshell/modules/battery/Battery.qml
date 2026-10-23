import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.commonwidgets
import qs.services as S

BarIconPopup {
    id: root

    mouseEnabled: true
    hoverEnabled: false
    visible: S.BatteryService.hasBattery
    iconText: S.BatteryService.batteryIcon()
}
