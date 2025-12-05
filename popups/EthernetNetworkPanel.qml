import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import qs.commonwidgets
import qs.modules
import qs.modules.ethernet
import qs.theme as T
import qs.services as S

HoverPopupWindow {
    id: networkPopup
    trigger: trigger
    
    function refresh() {
        S.Network.refresh()
    }

    Timer {
        id: refreshTimer
        interval: 5000  
        repeat: true
        running: networkPopup.visible

        onTriggered: {
            refresh()
        }
    }

    onVisibleChanged: {
        if (visible) {
            refresh()
            S.PopupManager.closeOthers(networkPopup)
        }
    }

    Component.onCompleted: {
        S.PopupManager.register(networkPopup)
    }


    Column {
        width: T.Config.networkPopupWidth
        spacing: 10
        EthernetHeader {}
        ComponentSplitter{}
        EthernetConnectedNetwork{}
        ComponentSpacer{}
    }
}

