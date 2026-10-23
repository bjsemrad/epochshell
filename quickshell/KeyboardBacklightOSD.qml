import QtQuick
import qs.commonwidgets
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import qs.services as S

Scope {
    id: root

    property string device: ""
    property int maxBrightness: 0
    property real level: 0.0
    property bool initialized: false

    readonly property bool available: device.length > 0 && maxBrightness > 0

    Process {
        id: findDevice
        running: true
        command: ["sh", "-c", "for d in /sys/class/leds/*kbd_backlight*; do [ -r \"$d/brightness\" ] && printf %s \"$d\" && break; done"]
        stdout: StdioCollector {
            id: deviceOut
            waitForEnd: true
        }
        onExited: root.device = String(deviceOut.text || "").trim()
    }

    FileView {
        id: maxFile
        path: root.device.length > 0 ? root.device + "/max_brightness" : ""
        printErrors: false
        onLoaded: root.maxBrightness = parseInt(text()) || 0
    }

    FileView {
        id: brightnessFile
        path: root.device.length > 0 ? root.device + "/brightness" : ""
        printErrors: false
        onLoaded: root.apply(parseInt(text()))
    }

    Timer {
        interval: Ui.osdPollMs
        running: root.available
        repeat: true
        onTriggered: brightnessFile.reload()
    }

    function apply(value) {
        if (!root.available || isNaN(value)) return;
        const next = Math.max(0, Math.min(1, value / root.maxBrightness));
        if (!root.initialized) {
            root.initialized = true;
            root.level = next;
            return;
        }
        if (Math.abs(next - root.level) < 0.001) return;
        root.level = next;
        root.triggerOSD();
    }

    function triggerOSD() {
        const level = Math.round(root.level * root.maxBrightness);
        S.OsdService.show({
            kind: "kbd",
            icon: "󰌌",
            value: root.level,
            steps: root.maxBrightness + 1,
            label: level + "/" + root.maxBrightness
        });
    }
}
