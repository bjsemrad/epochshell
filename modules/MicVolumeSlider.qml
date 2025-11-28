import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import "../theme" as T
import "../commonwidgets"
VolumeSlider {
    audioInterface: Pipewire.defaultAudioSource
    iconText: {
        if (audioInterface?.audio.muted) return ""
        return ""
    }
}
