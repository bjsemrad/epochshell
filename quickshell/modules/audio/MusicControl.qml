import qs.commonwidgets
import qs.services as S

BarGroupIconPopup {
    id: root
    mouseEnabled: true
    hoverEnabled: false
    visible: S.AudioService.player ? S.AudioService.player?.canPlay : false
    iconSet: [""]
}
