import qs.commonwidgets
import qs.services as S
import qs.theme as T

BarIconPopup {
    id: root
    visible: S.SystemInfo.connected && S.SystemInfo.hasFirmwareUpdates
    mouseEnabled: true
    hoverEnabled: false
    iconColor: T.Config.accent
    iconText: S.SystemInfo.firmwareIcon
}
