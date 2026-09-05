import QtQuick
import Quickshell
import qs.commonwidgets
import qs.services as S

BarIconPopup {
    id: root
    mouseEnabled: true
    hoverEnabled: false
    iconText: S.Notifications.doNotDisturb ? "󰂛" : S.Notifications.unreadCount > 0 ? "󰂚" : "󰂜"

    onRightClicked: S.Notifications.toggleDoNotDisturb()
}
