import qs.commonwidgets
import qs.services as S

BarIconPopup {
    id: root
    mouseEnabled: true
    hoverEnabled: false
    visible: S.HomeAssistant.configured
    iconText: S.HomeAssistant.connected ? "󰟐" : "󰟑"
}
