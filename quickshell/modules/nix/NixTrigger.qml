import qs.commonwidgets
import qs.services as S
import qs.theme as T

BarIconPopup {
    id: root
    visible: S.NixUpdates.connected && S.NixUpdates.available
    mouseEnabled: true
    hoverEnabled: false
    iconColor: S.NixUpdates.hasUpdates ? T.Config.accent : T.Config.surfaceText
    iconText: S.NixUpdates.icon
}
