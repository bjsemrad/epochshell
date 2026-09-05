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

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: T.Config.settingsHeaderHeight
        spacing: T.Config.layoutMarginSmall

        Text {
            text: "Now Playing"
            color: T.Config.surfaceText
            font.pixelSize: T.Config.fontSizeLarge
            font.bold: true
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
    }

    ComponentSplitter {}

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
