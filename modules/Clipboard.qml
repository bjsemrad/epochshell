import "../commonwidgets"
import Quickshell
import Quickshell.Io
BarIcon {
    id: root
    mouseEnabled: true
    iconText: "󰨸"

    Process {
        id: clipboard
    }

    function performLeftClickAction(){
        clipboard.command = ["uwsm", "app", "--", "walker", "--provider", "clipboard"]
        clipboard.running = true
    }

    function performRightClickAction(){
        clipboard.command = ["cliphist", "wipe"]
        clipboard.running = true
    }
}
