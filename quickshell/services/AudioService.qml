pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris

Singleton {
    id: audioService

    property var player: {
        for (let i = 0; i < Mpris.players.values.length; i++) {
            const p = Mpris.players.values[i];
            if (p && p.canControl) {
                return p;
            }
        }
        return null;
    }

    Process {
        id: pipewireCmd
        command: ["wpctl"]
    }

    function setDefault(id) {
        pipewireCmd.command = ["wpctl", "set-default", id];
        pipewireCmd.running = true;
    }

    Process {
        id: settingsCmd
        command: ["pavucontrol"]
    }

    function openSettings() {
        settingsCmd.running = true;
    }

    readonly property string currentAudioIcon: {
        const vol = Pipewire.defaultAudioSink?.audio.volume * 100;
        if (Pipewire.defaultAudioSink?.audio.muted)
            return "󰝟";
        if (vol >= 65)
            return "󰕾";
        if (vol >= 25)
            return "󰖀";
        return "󰕿";
    }
}
