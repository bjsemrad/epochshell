import QtQuick
import QtQuick.Layouts
import qs.theme as T
import qs.services as S

// The Theme row in the dashboard: what is worn now, and the way into the theme switcher.
//
// Clicking opens the full-screen switcher (ThemeOverlay) and closes the menu it sits in, as the
// Wallpaper row does with its switcher: the switcher covers the screen anyway, and a menu left open
// behind it would only be something to close afterwards. The row hides while there is nothing to
// choose between: a single theme is not a choice, and an empty list is what the shell shows for
// the moment before it has finished looking on disk.
Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: T.Config.settingsHeaderHeight
    visible: T.Config.availableThemes.length > 1

    // Told what to close, rather than reaching for it: the menu owns this row.
    property var menu

    Rectangle {
        id: rowBackground
        anchors.fill: parent
        anchors.rightMargin: T.Config.systemActionSpacing
        radius: T.Config.popupRadius
        antialiasing: true
        color: rowMouse.containsMouse ? T.Config.surfaceContainerHigh : "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: T.Config.layoutMarginSmall
            anchors.rightMargin: T.Config.layoutMarginSmall
            spacing: T.Config.layoutMarginSmall

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                Text {
                    text: "Theme"
                    color: T.Config.surfaceText
                    font.pixelSize: T.Config.fontSizeNormal
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                // The name of what is on screen, which during a preview is the theme being tried
                // rather than the one chosen -- the row should agree with the shell around it.
                Text {
                    text: T.Config.themeLoaded ? T.Config.themeName : (T.Config.themeName + " -- file missing")
                    color: T.Config.themeLoaded ? T.Config.outline : T.Config.orange
                    font.pixelSize: T.Config.fontSizeSubtext
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            // Points at where the panel comes out.
            Text {
                text: ""
                color: T.Config.outline
                font.pixelSize: T.Config.fontSizeSubtext
                font.family: T.Config.fontFamily
                Layout.alignment: Qt.AlignVCenter
            }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                const overlay = S.PopupManager.themeOverlay;
                if (!overlay) return;
                if (root.menu) root.menu.hidePanel();
                overlay.open();
            }
        }
    }
}
