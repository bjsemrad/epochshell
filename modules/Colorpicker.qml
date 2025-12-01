import "../commonwidgets"
import Quickshell
import Quickshell.Io
BarIcon {
    id: root
    mouseEnabled: true
    iconText: "󰴱"

    Process {
        id: colorpicker
        command: ["uwsm", "app", "--", "hyprpicker", "-a"]
    }

    function performLeftClickAction(){
        colorpicker.running = true
    }
}
