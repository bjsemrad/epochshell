import Quickshell
import Quickshell.Wayland        // for WlrLayershell + WlrLayer
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import qs.commonwidgets
import qs.modules
import qs.modules.bluetooth
import qs.theme as T
import qs.services as S

HoverPopupWindow {
    id: bluetoothPopup
    trigger: trigger

    onVisibleChanged: {
        if (visible) {
            S.PopupManager.closeOthers(bluetoothPopup)
        }
    }

    Component.onCompleted: {
        S.PopupManager.register(bluetoothPopup)
    }


    Column {
        width: T.Config.bluetoothPopupWidth
        spacing: 10
        BluetoothOnOff {}
        ComponentSplitter{}
        BluetoothPairedDevices{}
        ComponentSplitter{}
        BluetoothAvailableDevices{}
        ComponentSpacer{}
    }
}

