import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.services as S
import qs.theme as T
import qs.popups.pages

// Bluetooth in the Readout design, for the individual status icons (BluetoothPage).
HoverPopupWindow {
    id: panel

    popupWidth: 420

    Component.onDestruction: S.PopupManager.unregister(panel)
    Component.onCompleted: S.PopupManager.register(panel, "bluetooth")

    onVisibleChanged: {
        if (visible) {
            S.PopupManager.closeOthers(panel);
        }
    }

    BluetoothPage {
        Keys.onEscapePressed: panel.hidePanel()
    }
}
