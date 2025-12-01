import Quickshell
import Quickshell.Wayland        // for WlrLayershell + WlrLayer
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import "../commonwidgets"
import "../modules"
import "../theme" as T
import "../services" as S

HoverPopupWindow {
    id: networkPopup
    trigger: trigger
    
    function refresh() {
        S.Network.refresh()
    }

    Timer {
        id: refreshTimer
        interval: 10000  
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


    Row {
        id: networkContent
        spacing: 10
        Column {
            width: T.Config.networkPopupWidth
            spacing: 10
            WifiOnOff {}
            ComponentSplitter{}
            WifiConnectedNetwork{}
            ComponentSplitter{}
            WifiSavedNetworks{}
            ComponentSplitter{}
            WifiAvailableNetworks{}
            ComponentSpacer{}
        }
    }
}

