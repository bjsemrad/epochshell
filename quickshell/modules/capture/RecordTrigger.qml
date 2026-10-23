import qs.commonwidgets
import qs.services as S
import qs.theme as T

BarIconPopup {
    id: root
    visible: S.Capture.connected && !S.Capture.recording
    mouseEnabled: true
    hoverEnabled: false
    iconColor: S.Capture.recordAvailable ? T.Config.surfaceText : T.Config.outline
    iconText: "󰕧"
}
