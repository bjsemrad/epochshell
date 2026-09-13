import Quickshell
import Quickshell.Io
import qs.commonwidgets
import qs.services as S

// Clipboard history, in the bar drawer.
//
// It opens the shell's own launcher scoped to the clipboard provider rather than spawning one:
// the history lives in EpochOxide now, and the launcher is the thing that reads it. This used to
// run `walker --provider clipboard`, which since the move off walker has been launching nothing.
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
