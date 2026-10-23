import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.services as S

Scope {
    id: root

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink?.audio : null

        function onVolumeChanged() {
            if (!root.initialized) {
                root.initialized = true;
                return;
            }
            root.show();
        }

        function onMutedChanged() {
            let audio = Pipewire.defaultAudioSink.audio;
            let muted = audio.muted ?? false;

            if (!root.initialized) {
                root.initialized = true;
                root.lastMuted = muted;
                return;
            }

            if (muted !== lastMuted) {
                root.lastMuted = muted;
                root.show();
            }
        }
    }

    property bool initialized: false
    property bool lastMuted: false

    function show() {
        const audio = Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null;
        if (!audio) return;
        S.OsdService.show({
            kind: "volume",
            icon: audio.muted ? "󰝟" : "󰕾",
            value: audio.volume,
            label: audio.muted ? "muted" : Math.round(audio.volume * 100) + "%",
            muted: audio.muted
        });
    }
}
