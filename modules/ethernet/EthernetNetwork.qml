import qs.commonwidgets
import qs.services as S

BarIconPopup {
    id: root
    visible: S.Network.ethernetDevice && !S.Network.wifiConnected
    mouseEnabled: true
    hoverEnabled: false
    iconText:  {
        if (S.Network.ethernetConnected) {
            return "󰌗"
        }
        return "󰌙"
    }
}
