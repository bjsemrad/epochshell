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
    // Shown whenever EpochOxide is answering at all, even with nothing to pick from.
    //
    // Hiding the row when the list is empty was the first version, and it was wrong: a daemon older
    // than this shell has no wallpaper group, so the row silently disappeared and looked like a
    // feature that had never been built. A row that says why it cannot be used is worth more than
    // no row at all.
    visible: S.Wallpaper.connected

    readonly property bool usable: S.Wallpaper.wallpapers.length > 0

    // Told what to close, rather than reaching for it: the menu owns this row, not the other way
    // round.
    property var menu

    Rectangle {
        anchors.fill: parent
        anchors.rightMargin: T.Config.systemActionSpacing
        radius: T.Config.popupRadius
        antialiasing: true
        color: root.usable && rowMouse.containsMouse ? T.Config.surfaceContainerHigh : "transparent"
        opacity: root.usable ? 1 : 0.6

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

                // Three things this line has to say, in order of how much the reader needs them:
                // why it will not work, what is set, or how much there is to choose from. The file
                // name goes without its extension or path -- a full path elides to nothing useful
                // in a row this narrow.
                Text {
                    text: !root.usable
                          ? (S.Wallpaper.unavailableReason.length > 0
                             ? S.Wallpaper.unavailableReason
                             : "no images found")
                          : S.Wallpaper.current.length > 0
                            ? S.Wallpaper.displayName(S.Wallpaper.current)
                            : S.Wallpaper.wallpapers.length + " available"
                    color: root.usable ? T.Config.outline : T.Config.orange
                    font.pixelSize: T.Config.fontSizeSubtext
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            Text {
                visible: root.usable
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
            cursorShape: root.usable ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (!root.usable) return;
                const overlay = S.PopupManager.wallpaperOverlay;
                if (!overlay) return;
                if (root.menu) root.menu.hidePanel();
                overlay.open();
            }
        }
    }
}
