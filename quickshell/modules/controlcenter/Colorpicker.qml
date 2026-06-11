import Quickshell
import Quickshell.Io
import qs.commonwidgets

BarIcon {
    id: root
    mouseEnabled: true
    iconText: "󰴱"

    Process {
        id: colorpicker
        command: ["hyprpicker", "-a"]
    }

    function performLeftClickAction() {
        colorpicker.running = true;
    }
}
