import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.theme as T
import qs.services as S

// The wallpaper switcher: a full-screen grid of what is on disk.
//
// Moving the selection applies the wallpaper straight away rather than waiting for Enter. The
// switch is a single hyprctl call and the thing being chosen is the whole screen, so there is no
// preview worth showing that is smaller or more honest than the real one -- the same reasoning the
// theme picker uses. Enter keeps it, Escape puts back what was there before.
//
// One overlay for the session, owned by the shell root, like the launcher.
PanelWindow {
    id: root

    property bool _visible: false
    // What to restore if this is dismissed rather than confirmed.
    property string entryWallpaper: ""
    property int selectedIndex: 0

    // The same window setup the launcher uses, which is the one known to give a full-screen layer
    // surface here: all four anchors, no exclusive zone, focusable, pinned to the first screen.
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    visible: _visible
    color: "transparent"
    exclusiveZone: 0
    focusable: true
    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    function open() {
        if (root._visible) return;
        S.Wallpaper.refresh();
        root.entryWallpaper = S.Wallpaper.current;
        const at = S.Wallpaper.wallpapers.indexOf(S.Wallpaper.current);
        root.selectedIndex = at >= 0 ? at : 0;
        root._visible = true;
        grid.forceActiveFocus();
        grid.positionViewAtIndex(root.selectedIndex, GridView.Contain);
    }

    // Dismiss: whatever was showing when this opened goes back on.
    //
    // Every step through the grid is a real switch the backend has already remembered, so putting
    // it back is another real switch rather than an undo -- which is also why it is right that a
    // dismissed picker still leaves the state file consistent with the screen.
    function cancel() {
        if (root.entryWallpaper.length > 0 && S.Wallpaper.current !== root.entryWallpaper) {
            S.Wallpaper.set(root.entryWallpaper);
        }
        root._visible = false;
    }

    // Confirm: the selection was applied as it was reached, so this only has to close.
    function apply() {
        root._visible = false;
    }

    function toggle() {
        if (root._visible) root.cancel();
        else root.open();
    }

    function select(index) {
        const list = S.Wallpaper.wallpapers;
        if (list.length === 0) return;
        const to = Math.max(0, Math.min(list.length - 1, index));
        if (to === root.selectedIndex && S.Wallpaper.current === list[to]) return;
        root.selectedIndex = to;
        grid.positionViewAtIndex(to, GridView.Contain);
        S.Wallpaper.set(list[to]);
    }

    // Registers itself, the way the launcher does, so whoever instantiates it does not have to
    // know it needs registering.
    Component.onCompleted: S.PopupManager.registerWallpaperOverlay(root)
    Component.onDestruction: S.PopupManager.registerWallpaperOverlay(null)

    // The dimmed ground. Clicking it is the same as pressing Escape.
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)

        MouseArea {
            anchors.fill: parent
            onClicked: root.cancel()
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - 160, 1400)
        height: Math.min(parent.height - 160, 900)
        spacing: T.Config.layoutMarginSmall

        RowLayout {
            Layout.fillWidth: true
            spacing: T.Config.layoutMarginSmall

            Text {
                text: "Wallpaper"
                color: T.Config.surfaceText
                font.pixelSize: T.Config.fontSizeXLarge
                font.bold: true
                Layout.fillWidth: true
            }

            Text {
                text: S.Wallpaper.wallpapers.length + (S.Wallpaper.wallpapers.length === 1 ? " image" : " images")
                color: T.Config.outline
                font.pixelSize: T.Config.fontSizeSubtext
                Layout.alignment: Qt.AlignVCenter
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: T.Config.popupRadius
            antialiasing: true
            color: T.Config.popupBackground
            border.width: 1
            border.color: T.Config.outline
            clip: true

            // Says why the grid is empty, which is otherwise indistinguishable from "still looking".
            Text {
                anchors.centerIn: parent
                visible: S.Wallpaper.wallpapers.length === 0
                horizontalAlignment: Text.AlignHCenter
                color: T.Config.outline
                font.pixelSize: T.Config.fontSizeNormal
                text: !S.Wallpaper.connected
                      ? "EpochOxide is not reachable"
                      : "No images in\n" + S.Wallpaper.directories.join("\n")
                        + "\n\nSet wallpaper_dirs in EpochOxide's config to look elsewhere."
            }

            GridView {
                id: grid
                anchors.fill: parent
                anchors.margins: T.Config.layoutMarginSmall
                visible: S.Wallpaper.wallpapers.length > 0
                model: S.Wallpaper.wallpapers
                cellWidth: Math.floor(width / Math.max(1, Math.floor(width / 260)))
                cellHeight: Math.round(cellWidth * 0.62)
                focus: true
                clip: true
                currentIndex: root.selectedIndex

                Keys.onPressed: event => {
                    const perRow = Math.max(1, Math.floor(grid.width / grid.cellWidth));
                    if (event.key === Qt.Key_Escape) {
                        root.cancel();
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.apply();
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                        root.select(root.selectedIndex - 1);
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                        root.select(root.selectedIndex + 1);
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                        root.select(root.selectedIndex - perRow);
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                        root.select(root.selectedIndex + perRow);
                    } else if (event.key === Qt.Key_Home) {
                        root.select(0);
                    } else if (event.key === Qt.Key_End) {
                        root.select(S.Wallpaper.wallpapers.length - 1);
                    } else {
                        return;
                    }
                    event.accepted = true;
                }

                delegate: Item {
                    id: tile
                    required property string modelData
                    required property int index
                    readonly property bool selected: index === root.selectedIndex

                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: T.Config.popupRadius
                        antialiasing: true
                        color: tile.selected ? T.Config.accentLightShade : "transparent"
                        border.width: tile.selected ? 2 : 1
                        border.color: tile.selected ? T.Config.accent : T.Config.surfaceVariant

                        Image {
                            id: thumb
                            anchors.fill: parent
                            anchors.margins: 3
                            source: "file://" + tile.modelData
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            // Decode at tile size rather than full resolution: these are 4K images
                            // and a grid of them at native size is hundreds of megabytes.
                            sourceSize.width: 320
                            clip: true
                        }

                        // The name, over the bottom of the image where it stays readable.
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 3
                            height: label.implicitHeight + 8
                            color: Qt.rgba(0, 0, 0, 0.65)

                            Text {
                                id: label
                                anchors.centerIn: parent
                                width: parent.width - 12
                                text: S.Wallpaper.displayName(tile.modelData)
                                color: "#ffffff"
                                font.pixelSize: T.Config.fontSizeSubtext
                                font.family: T.Config.fontFamily
                                elide: Text.ElideMiddle
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.select(tile.index)
                            onClicked: {
                                root.select(tile.index);
                                root.apply();
                            }
                        }
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            color: T.Config.outline
            font.pixelSize: T.Config.fontSizeSubtext
            text: "↑↓←→ to browse · Enter to keep · Esc to put back"
        }
    }
}
