import qs.theme as T
import qs.services as S
import qs.commonwidgets

BarIconPopup {
    id: root
    visible: S.Network.wifiDevice
    mouseEnabled: true
    hoverEnabled: false
    iconText:  {
        const s = S.Network.strength
        if (!S.Network.wifiConnected) return "󰤭"
        if (s >= Ui.signalStrong) return "󰤨"
        if (s >= Ui.signalFair) return "󰤢"
        if (s >= Ui.signalWeak) return "󰤟"
        return "󰤟"
    }
}
