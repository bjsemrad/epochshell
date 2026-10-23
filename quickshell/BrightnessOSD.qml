import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import qs.services as S

Scope {
    id: root

    property real brightness: 0.0
    property bool initialized: false

    property bool hasBacklight: false

    Process {
        id: backlightListProc
        running: true
        command: ["brightnessctl", "--list"]

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                root.hasBacklight = data.indexOf("class 'backlight'") !== -1;
                if (root.hasBacklight)
                    backlightGetValueProc.running = true;
            }
        }
    }

    Process {
        id: backlightGetValueProc
        running: false
        command: ["sh", "-c", "echo \"$(brightnessctl g) $(brightnessctl m)\""]

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                const s = data.trim().split(" ");
                if (s.length >= 2) {
                    let pct = (parseInt(s[0]) / parseInt(s[1]));
                    if (!root.initialized) {
                        root.initialized = true;
                        root.brightness = pct;
                        return;
                    }

                    if (Math.abs(pct - root.brightness) > 0.001) {
                        root.brightness = pct;
                        root.triggerOSD();
                    }
                }
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 250
        running: true
        repeat: true
        onTriggered: {
            if (root.hasBacklight)
                backlightGetValueProc.running = true;
        }
    }

    function triggerOSD() {
        S.OsdService.show({
            kind: "brightness",
            icon: "󰃠",
            value: root.brightness,
            label: Math.round(root.brightness * 100) + "%"
        });
    }
}
