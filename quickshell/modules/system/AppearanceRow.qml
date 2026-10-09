import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.theme as T
import qs.services as S

// The way into the appearance settings, in the system menu beside Theme and Wallpaper. Closes the
// menu, as they do, so the bar is clear to judge.
ListRow {
    id: root

    property var menu

    title: "Appearance"
    subtitle: "Bar, panels and workspaces"
    onClicked: {
        const overlay = S.PopupManager.settingsOverlay;
        if (!overlay) return;
        if (root.menu) root.menu.hidePanel();
        overlay.open();
    }

    Text {
        text: ""
        color: T.Config.outline
        font.pixelSize: T.Config.fontSizeSubtext
        font.family: T.Config.fontFamily
    }
}
