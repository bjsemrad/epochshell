import Quickshell
import Quickshell.Io
import qs.commonwidgets
import qs.services as S
import qs.theme as T

BarIcon {
    id: root
    mouseEnabled: true
    iconText: "󰨸"
    fontPixelSize: T.Config.barIconSize

    Process {
        id: clipboard
    }

    function performLeftClickAction() {
        S.PopupManager.closeAll();
        clipboard.command = ["walker", "--provider", "clipboard"];
        clipboard.running = true;
    }

    function performRightClickAction() {
        clipboard.command = ["cliphist", "wipe"];
        clipboard.running = true;
    }
}
