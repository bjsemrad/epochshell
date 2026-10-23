import QtQuick
import qs.commonwidgets
import qs.services as S

BarIcon {
    id: root
    mouseEnabled: true
    iconText: "󰀻"

    function performLeftClickAction() {
        const launcher = S.PopupManager.launcher;
        if (!launcher) return;
        if (launcher._visible) {
            launcher.close();
        } else {
            launcher.open();
        }
    }
}
