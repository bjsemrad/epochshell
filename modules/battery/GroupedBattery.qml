import qs.commonwidgets
import qs.services as S

BarGroupIconPopup {
    id: root
    mouseEnabled: true
    hoverEnabled: true
    iconSet:  [S.BatteryService.batteryIcon()]
}
