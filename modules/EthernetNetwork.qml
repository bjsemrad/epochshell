import '../commonwidgets'
import '../services' as S

BarIconPopup {
    id: root
    mouseEnabled: true
    iconText:  {
        if (S.Network.ethernetConnected) {
            return "󰌗"
        }
        return "󰌙"
    }
}
