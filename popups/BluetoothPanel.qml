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
    id: bluetoothPopup
    trigger: trigger

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
        id: bluetoothContent
        spacing: 10
        Column {
            width: T.Config.bluetoothPopupWidth
            spacing: 10
            BluetoothOnOff {}
            ComponentSplitter{}
            // WifiConnectedNetwork{}
            ComponentSplitter{}
            // WifiAvailableNetworks{}
            ComponentSpacer{}
        }
    }
}

