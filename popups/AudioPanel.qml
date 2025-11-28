import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import "../commonwidgets"
import "../modules"
import "../theme" as T
import "../services" as S

HoverPopupWindow {
    id: audioPopup
    trigger: trigger
    
    Row {
        id: audioContent
        spacing: 10
        Column {
            width: T.Config.networkPopupWidth
            spacing: 10
            AudioVolumeRow {}
            ComponentSplitter{}
            AvailableAudioOutputs{}
            ComponentSplitter{}
            MicVolumeRow{}
            ComponentSpacer{}
        }
    }

    onVisibleChanged: {
        if (visible){
            S.PopupManager.closeOthers(audioPopup)
        }
    }
    
    Component.onCompleted: {
        S.PopupManager.register(audioPopup)
    }
}

