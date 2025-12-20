import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import qs.commonwidgets
import qs.modules
import qs.modules.battery
import qs.theme as T
import qs.services as S
import qs.modules.overview as O

HoverPopupWindow {
    id: musicPopup
    trigger: trigger
    popupWidth: T.Config.musicPlayerWidth

    O.MusicPlayer {}

    onVisibleChanged: {
        if (visible) {
            S.PopupManager.closeOthers(musicPopup);
        }
    }

    Component.onCompleted: {
        S.PopupManager.register(musicPopup);
    }
}
