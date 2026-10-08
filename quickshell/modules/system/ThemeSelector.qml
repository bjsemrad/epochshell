import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.theme as T
import qs.services as S

// The Theme row in the dashboard: what is worn now, and the way into the theme switcher.
//
// Clicking opens the full-screen switcher (ThemeOverlay) and closes the menu it sits in, as the
// Wallpaper row does with its switcher: the switcher covers the screen anyway, and a menu left open
// behind it would only be something to close afterwards. The row hides while there is nothing to
// choose between: a single theme is not a choice, and an empty list is what the shell shows for
// the moment before it has finished looking on disk.
ListRow {
    id: root
    visible: T.Config.availableThemes.length > 1

    // Told what to close, rather than reaching for it: the menu owns this row.
    property var menu

    title: "Theme"
    subtitle: T.Config.themeLoaded ? T.Config.themeName : (T.Config.themeName + " -- file missing")
    onClicked: {
        const overlay = S.PopupManager.themeOverlay;
        if (!overlay) return;
        if (root.menu) root.menu.hidePanel();
        overlay.open();
    }

    // Opens something, as the dashboard's chevrons do.
    Text {
        text: "\uf054"
        color: T.Config.outline
        font.pixelSize: T.Config.fontSizeSubtext
        font.family: T.Config.fontFamily
    }
}
