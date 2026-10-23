import qs.commonwidgets
import qs.services as S
import qs.theme as T

BarIconPopup {
    id: root
    visible: S.LocalSend.connected
    mouseEnabled: true
    hoverEnabled: false
    iconColor: S.LocalSend.hasIncomingFiles ? T.Config.accent : T.Config.surfaceText
    iconText: S.LocalSend.sendingFile ? "󰔟" : S.LocalSend.icon
}
