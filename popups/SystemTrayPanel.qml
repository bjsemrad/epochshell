import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import qs.commonwidgets
import qs.modules
import qs.modules.systemtray
import qs.theme as T
import qs.services as S

HoverPopupWindow {
    id: systemTrayPopup
    trigger: trigger

    onVisibleChanged: {
        if (visible) {
            S.PopupManager.closeOthers(systemTrayPopup)
        }
    }

    Component.onCompleted: {
        S.PopupManager.register(systemTrayPopup)
    }

    Column {
        width: trayContainer.width
        spacing: 10
        SystemTraySet{
            id: trayContainer
        }
        ComponentSpacer{}
    }
}

