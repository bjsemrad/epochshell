import '../commonwidgets'
import '../services' as S

BarIconPopup {
    id: root
    mouseEnabled: true
    hoverEnabled: false
    iconText:  {
        const s = S.Network.strength
        if (!S.Network.wifiConnected) return "󰤭"
        if (s >= 75) return "󰤨"
        if (s >= 50) return "󰤢"
        if (s >= 25) return "󰤟"
        return "󰤟"
    }
}
