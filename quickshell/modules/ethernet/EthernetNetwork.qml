import qs.commonwidgets
import qs.services as S
import qs.theme as T

BarIconPopup {
    id: root
    visible: T.Config.showIndividualIcons && S.Network.ethernetDevice
    mouseEnabled: true
    hoverEnabled: false
    iconText: {
        if (S.Network.ethernetConnected) {
            return "󰌘";
        }
        return "󰌙";
    }
}
