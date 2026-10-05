import qs.commonwidgets
import qs.services as S

BarIconPopup {
    id: root
    mouseEnabled: true
    hoverEnabled: false
    // Only on a machine with Home Assistant set up: `programs.epochshell.homeAssistant.enable`
    // off removes the config file, and a bar icon for a service that is not there is just noise.
    visible: S.HomeAssistant.configured
    iconText: S.HomeAssistant.connected ? "󰟐" : "󰟑"
}
