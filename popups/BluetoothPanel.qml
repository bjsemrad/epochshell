import Quickshell
import Quickshell.Wayland
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

    Row {
        width: T.Config.bluetoothPopupWidth
        height: inner.implicitHeight
        Column {
            id: inner
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10
            BluetoothOnOff {}
            ComponentSplitter{}
            BluetoothPairedDevices{}
            ComponentSplitter{}
            BluetoothAvailableDevices{}
            ComponentSpacer{}
        }
    }
}

