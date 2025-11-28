import '../commonwidgets'
import '../services' as S

BarIconPopup {
    id: root
    mouseEnabled: true
    iconText:  {
        if (S.NetworkMonitor.ethernetConnected) {
            return "󰈀"
        }
        return "󰌙"
    }
}
