import qs.commonwidgets
import qs.services as S
import qs.theme as T

BarIconPopup {
    id: root
    visible: S.Capture.connected
    mouseEnabled: true
    hoverEnabled: false
    iconColor: S.Capture.busy ? T.Config.accent : T.Config.surfaceText
    iconText: S.Capture.busy ? "󰔟" : S.Capture.icon
}
