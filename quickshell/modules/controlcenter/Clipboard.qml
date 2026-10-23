import Quickshell
import Quickshell.Io
import qs.commonwidgets
import qs.services as S

BarIcon {
    id: root
    mouseEnabled: true
    iconText: "󰨸"

    Process {
        id: clipboard
    }

    function performLeftClickAction() {
        const launcher = S.PopupManager.launcher;
        if (!launcher) return;
        // Panels first, launcher second: closeAll would otherwise shut the launcher it just opened.
        S.PopupManager.closeAll();
        launcher.openProvider("clipboard");
    }

    function performRightClickAction() {
        clipboard.command = ["cliphist", "wipe"];
        clipboard.running = true;
    }
}
