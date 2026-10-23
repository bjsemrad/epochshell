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
    Component.onCompleted: S.PopupManager.register(panel, "battery")

    onVisibleChanged: {
        S.PowerProfile.watching = visible;
        if (visible) {
            S.PowerProfile.refresh();
            S.SystemInfo.refresh();
            S.StayAwake.refresh();
            S.PopupManager.closeOthers(panel);
        }
    }

    BatteryPage {
        Keys.onEscapePressed: panel.hidePanel()
    }
}
