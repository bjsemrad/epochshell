import QtQuick
import QtQuick.Layouts
import qs.theme as T
import qs.services as S

// The wallpaper, in the system menu: what is set, and the way into the picker.
//
// Shaped like the Theme row beside it, because it is the same kind of thing -- a look setting whose
// chooser is too big to live in a 300px menu. Clicking opens the full-screen picker and closes the
// menu, since the picker covers it anyway and leaving it open behind would only be something to
// dismiss afterwards.
Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: T.Config.settingsHeaderHeight
    // Nothing to pick from means nothing to open. The backend answers with an empty list when the
    // configured directories hold no images, or when hyprctl is missing.
    visible: S.Wallpaper.wallpapers.length > 0

    // Told what to close, rather than reaching for it: the menu owns this row, not the other way
    // round.
    property var menu

    Rectangle {
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
                    text: "Wallpaper"
                    color: T.Config.surfaceText
                    font.pixelSize: T.Config.fontSizeNormal
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                // The file name without its extension or path -- the whole path would elide to
                // nothing useful in a row this narrow.
                Text {
                    text: S.Wallpaper.current.length > 0
                          ? S.Wallpaper.displayName(S.Wallpaper.current)
                          : S.Wallpaper.wallpapers.length + " available"
                    color: T.Config.outline
                    font.pixelSize: T.Config.fontSizeSubtext
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

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
                const overlay = S.PopupManager.wallpaperOverlay;
                if (!overlay) return;
                if (root.menu) root.menu.hidePanel();
                overlay.open();
            }
        }
    }
}
