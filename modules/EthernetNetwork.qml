import '../commonwidgets'
import '../services' as S

BarIconPopup {
    id: root
    mouseEnabled: true
    hoverEnabled: false
    iconText:  {
        if (S.Network.ethernetConnected) {
            return "󰌗"
        }
        return "󰌙"
    }
}
