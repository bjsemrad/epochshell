import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import qs.commonwidgets
import qs.modules.audio
import qs.theme as T
import qs.services as S

HoverPopupWindow {
    id: audioPopup
    trigger: trigger
    Column {
        width: T.Config.audioPopupWidth
        spacing: 10
        AudioHeader{}
        ComponentSplitter{}
        AudioVolumeRow {}
        ComponentSplitter{}
        AvailableAudioOutputs{}
        ComponentSplitter{}
        MicVolumeRow{}
        ComponentSplitter{}
        AvailableAudioInputs{}
        ComponentSpacer{}
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

