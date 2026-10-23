import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.services as S
import qs.theme as T
import qs.popups.pages

HoverPopupWindow {
    id: panel

    popupWidth: 480

    Component.onDestruction: S.PopupManager.unregister(panel)
    Component.onCompleted: S.PopupManager.register(panel, "ethernet")

    onVisibleChanged: {
        if (visible) {
            S.Network.refresh();
            S.PopupManager.closeOthers(panel);
        }
    }

    EthernetPage {
        Keys.onEscapePressed: panel.hidePanel()
    }
}
