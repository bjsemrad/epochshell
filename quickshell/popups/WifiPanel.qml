import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.services as S
import qs.theme as T
import qs.popups.pages

// The Wi-Fi panel in the Readout design, for the individual status icons: the same page as the
// dashboard's (WifiPage), on its own.
HoverPopupWindow {
    id: panel

    popupWidth: 420

    Component.onDestruction: S.PopupManager.unregister(panel)
    Component.onCompleted: S.PopupManager.register(panel, "wifi")

    onVisibleChanged: {
        if (visible) {
            S.Network.refresh();
            S.PopupManager.closeOthers(panel);
        }
    }

    WifiPage {
        Keys.onEscapePressed: panel.hidePanel()
    }
}
