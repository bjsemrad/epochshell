import qs.commonwidgets
import qs.services as S
import qs.theme as T

BarIcon {
    id: root
    visible: S.StayAwake.connected && S.StayAwake.enabled
    mouseEnabled: true
    iconText: "󰒳"
    iconColor: T.Config.accent

    function performLeftClickAction() {
        S.StayAwake.toggle();
    }
}
