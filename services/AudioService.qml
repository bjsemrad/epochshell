pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: audioService

    Process {
        id: pipewireCmd
        command: ["wpctl"]
    }

    function setDefault(id) {
        pipewireCmd.command = ["wpctl", "set-default", id]
        pipewireCmd.running = true
    }


    Process {
        id: settingsCmd
        command: ["pavucontrol"]
    }

    function openSettings() {
        settingsCmd.running = true
    }

}
