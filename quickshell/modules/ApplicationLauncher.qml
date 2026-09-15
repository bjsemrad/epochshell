import QtQuick
import qs.commonwidgets
import qs.services as S

// The launcher button, top left.
//
// It opens the launcher on its provider list -- the view typing ";" reaches -- rather than on an
// empty query, so that clicking it lands in the same place SUPER+SPACE does. A button and a
// keybinding for the same thing that open two different views is just two things to learn.
//
// The overlay itself is owned by the shell root: this icon exists once per screen, and every copy
// drives the one shared launcher window.
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
            launcher.openProviders();
        }
    }
}
