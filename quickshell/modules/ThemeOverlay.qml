import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.commonwidgets
import qs.theme as T
import qs.services as S

// The theme switcher: a full-screen grid of every theme, each drawn in its own colours, with the
// shell's opacity beside it.
//
// The same shape as the wallpaper switcher, for the same reason: the thing being chosen is how the
// whole shell looks, so the honest preview is the shell itself. Moving the selection -- arrow keys
// or the pointer -- wears that theme at once, overlay and all; Enter or a click keeps it, Escape
// puts back the one that was on. Nothing is written until a theme is kept.
//
// The opacity sliders are not part of that try-then-keep: each one applies as it moves and is
// saved when let go, exactly as it was in the old picker. Escape puts back the theme, not them.
//
// One overlay for the session, owned by the shell root, like the launcher and the wallpaper switcher.
PanelWindow {
    id: root

    property bool _visible: false
    property int selectedIndex: 0

    // The same window setup as the wallpaper switcher: full screen, no exclusive zone, focusable,
    // on the first screen.
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

    readonly property var themes: T.Config.availableThemes

    // Type to search: the grid narrows to the themes whose name holds what has been typed, and the
    // first of them is selected -- so a few letters and Enter is the whole of choosing one.
    property string query: ""
    readonly property var shown: {
        const q = root.query.trim().toLowerCase();
        return q.length === 0 ? root.themes : root.themes.filter(name => name.toLowerCase().includes(q));
    }
    onQueryChanged: {
        if (!root._visible) return;
        if (root.shown.length > 0) root.select(0);
        else T.Config.endPreview();
    }

    function open() {
        if (root._visible) return;
        root.query = "";
        const at = root.themes.indexOf(T.Config.themeName);
        root.selectedIndex = at >= 0 ? at : 0;
        root._visible = true;
        grid.forceActiveFocus();
        grid.positionViewAtIndex(root.selectedIndex, GridView.Contain);
    }

    // Dismiss: drop the preview, and the theme that was on is what shows again.
    function cancel() {
        T.Config.endPreview();
        root._visible = false;
    }

    // Keep: the selected theme becomes the chosen one and is written down.
    function apply() {
        const name = root.shown[root.selectedIndex];
        if (name) T.Config.selectTheme(name);
        T.Config.endPreview();
        root._visible = false;
    }

    function toggle() {
        if (root._visible) root.cancel();
        else root.open();
    }

    function select(index) {
        if (root.shown.length === 0) return;
        const to = Math.max(0, Math.min(root.shown.length - 1, index));
        root.selectedIndex = to;
        grid.positionViewAtIndex(to, GridView.Contain);
        T.Config.previewTheme(root.shown[to]);
    }

    Component.onCompleted: S.PopupManager.registerThemeOverlay(root)
    Component.onDestruction: S.PopupManager.registerThemeOverlay(null)

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
        width: Math.min(parent.width - 160, 1200)
        height: Math.min(parent.height - 160, 760)
        spacing: T.Config.layoutMarginSmall

        RowLayout {
            Layout.fillWidth: true
            spacing: T.Config.layoutMarginSmall

            Text {
                text: "Theme"
                color: T.Config.surfaceText
                font.pixelSize: T.Config.fontSizeXLarge
                font.bold: true
            }

            // The search, which typing fills; there is no field to click into, because typing
            // anywhere in the switcher already lands here.
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: T.Config.layoutSpacingSmall
                Layout.preferredHeight: searchRow.implicitHeight + T.Config.popupPadding
                radius: T.Config.popupRadius
                color: T.Config.popupBackground
                border.width: 1
                border.color: root.query.length > 0 ? T.Config.accent : T.Config.surfaceVariant

                RowLayout {
                    id: searchRow
                    anchors.fill: parent
                    anchors.leftMargin: T.Config.popupPadding
                    anchors.rightMargin: T.Config.popupPadding
                    spacing: T.Config.layoutMarginSmall

                    Text {
                        text: "\uf002"
                        color: T.Config.outline
                        font.pixelSize: T.Config.fontSizeNormal
                        font.family: T.Config.fontFamily
                    }

                    Text {
                        text: root.query.length > 0 ? root.query : "Type to search"
                        color: root.query.length > 0 ? T.Config.surfaceText : T.Config.outline
                        font.pixelSize: T.Config.fontSizeNormal
                        font.family: T.Config.fontFamily
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }

            Text {
                text: root.query.length > 0
                    ? root.shown.length + " of " + root.themes.length
                    : root.themes.length + (root.themes.length === 1 ? " theme" : " themes")
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

            // Swallows clicks on the card, so only the dimmed ground around it dismisses.
            MouseArea {
                anchors.fill: parent
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: T.Config.layoutMarginSmall
                spacing: T.Config.layoutSpacingSmall

                // --- The themes ------------------------------------------------------------------

                GridView {
                    id: grid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: root.shown
                    cellWidth: Math.floor(width / Math.max(1, Math.floor(width / 220)))
                    cellHeight: Math.round(cellWidth * 0.72)
                    focus: true
                    clip: true
                    currentIndex: root.selectedIndex

                    Keys.onPressed: event => {
                        const perRow = Math.max(1, Math.floor(grid.width / grid.cellWidth));
                        // Letters go to the search, so the selection moves by arrow keys only.
                        if (event.key === Qt.Key_Escape) {
                            // A search first, then the switcher.
                            if (root.query.length > 0) root.query = "";
                            else root.cancel();
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.apply();
                        } else if (event.key === Qt.Key_Left) {
                            root.select(root.selectedIndex - 1);
                        } else if (event.key === Qt.Key_Right) {
                            root.select(root.selectedIndex + 1);
                        } else if (event.key === Qt.Key_Up) {
                            root.select(root.selectedIndex - perRow);
                        } else if (event.key === Qt.Key_Down) {
                            root.select(root.selectedIndex + perRow);
                        } else if (event.key === Qt.Key_Home) {
                            root.select(0);
                        } else if (event.key === Qt.Key_End) {
                            root.select(root.shown.length - 1);
                        } else if (event.key === Qt.Key_Backspace) {
                            root.query = root.query.slice(0, -1);
                        } else if (event.text.length === 1 && event.text >= " " && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
                            root.query += event.text;
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
                        readonly property bool current: modelData === T.Config.selectedThemeName
                            || (T.Config.selectedThemeName === "" && modelData === T.Config.themeName)

                        width: grid.cellWidth
                        height: grid.cellHeight

                        function c(key) {
                            return T.Config.themeColor(tile.modelData, key);
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 6
                            radius: T.Config.popupRadius
                            antialiasing: true
                            color: tile.selected ? T.Config.accentLightShade : "transparent"
                            border.width: tile.selected ? 2 : 1
                            border.color: tile.selected ? T.Config.accent : T.Config.surfaceVariant

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 6

                                // The theme, drawn in itself: its ground, a bar along the top, a
                                // panel hanging from it with an accent switch, and its colours.
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: T.Config.popupRadius - 2
                                    antialiasing: true
                                    color: tile.c("background")
                                    border.width: 1
                                    border.color: tile.c("surfaceVariant")
                                    clip: true

                                    // The bar.
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 1
                                        height: 14
                                        color: tile.c("surface")

                                        Row {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            spacing: 4
                                            Repeater {
                                                model: 4
                                                delegate: Rectangle {
                                                    required property int index
                                                    width: 6
                                                    height: 6
                                                    radius: 3
                                                    color: index === 1 ? tile.c("accent") : tile.c("surfaceText")
                                                    opacity: index === 1 ? 1 : 0.6
                                                }
                                            }
                                        }
                                    }

                                    // A panel hanging from it.
                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.topMargin: 15
                                        anchors.rightMargin: 10
                                        width: parent.width * 0.48
                                        height: parent.height * 0.62
                                        radius: 4
                                        color: tile.c("surface")

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            spacing: 4

                                            // Two lines of "text".
                                            Rectangle {
                                                Layout.preferredWidth: parent.width * 0.7
                                                Layout.preferredHeight: 4
                                                radius: 2
                                                color: tile.c("surfaceText")
                                            }
                                            Rectangle {
                                                Layout.preferredWidth: parent.width * 0.45
                                                Layout.preferredHeight: 3
                                                radius: 1.5
                                                color: tile.c("outline")
                                            }

                                            // An accent switch, on.
                                            Rectangle {
                                                Layout.topMargin: 2
                                                Layout.preferredWidth: 18
                                                Layout.preferredHeight: 9
                                                radius: 4.5
                                                color: tile.c("accent")

                                                Rectangle {
                                                    anchors.right: parent.right
                                                    anchors.rightMargin: 1.5
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: 6
                                                    height: 6
                                                    radius: 3
                                                    color: tile.c("background")
                                                }
                                            }
                                        }
                                    }

                                    // Its colours, along the bottom left.
                                    Row {
                                        anchors.left: parent.left
                                        anchors.bottom: parent.bottom
                                        anchors.margins: 8
                                        spacing: 3

                                        Repeater {
                                            model: ["accent", "green", "orange", "red", "purple", "cyan"]
                                            delegate: Rectangle {
                                                required property string modelData
                                                width: 8
                                                height: 8
                                                radius: 4
                                                antialiasing: true
                                                color: tile.c(modelData)
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Text {
                                        text: tile.modelData
                                        color: T.Config.surfaceText
                                        font.pixelSize: T.Config.fontSizeSubtext
                                        font.family: T.Config.fontFamily
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: "󰄬"
                                        visible: tile.current
                                        color: T.Config.accent
                                        font.pixelSize: T.Config.fontSizeSubtext
                                        font.family: T.Config.fontFamily
                                    }
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

                // --- Opacity -------------------------------------------------------------------

                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    color: T.Config.surfaceVariant
                }

                // Held to its width: the sliders inside ask for all the width going, and would
                // otherwise take it from the grid.
                ColumnLayout {
                    Layout.fillWidth: false
                    Layout.preferredWidth: 280
                    Layout.maximumWidth: 280
                    Layout.fillHeight: true
                    Layout.margins: T.Config.layoutMarginSmall
                    spacing: T.Config.popupLayoutSpacing

                    Text {
                        text: "Opacity"
                        color: T.Config.surfaceText
                        font.pixelSize: T.Config.fontSizeLarge
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    // Moving a handle applies the value at once and writes nothing; letting go
                    // writes it. Called opacity, and counted that way: 100% is solid.
                    SettingSlider {
                        label: "Bar"
                        hint: "100% is solid"
                        // All the way down: a bar of icons straight over the wallpaper is a look of
                        // its own. The others keep the slider's 30% floor, below which a panel's
                        // text stops being readable.
                        from: 0
                        settingValue: T.Config.barOpacity
                        onMoved: value => T.Config.barOpacity = value
                        onCommitted: value => T.Config.setSetting("barOpacity", value)
                    }

                    SettingSlider {
                        label: "Panels"
                        hint: "Opened from the bar"
                        settingValue: T.Config.panelOpacity
                        onMoved: value => T.Config.panelOpacity = value
                        onCommitted: value => T.Config.setSetting("panelOpacity", value)
                    }

                    SettingSlider {
                        label: "Overlays"
                        hint: "OSDs, notifications, launcher"
                        settingValue: T.Config.popupOpacity
                        onMoved: value => T.Config.popupOpacity = value
                        onCommitted: value => T.Config.setSetting("popupOpacity", value)
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            color: T.Config.outline
            font.pixelSize: T.Config.fontSizeSubtext
            text: "Type to search · ↑↓←→ or hover to try · Enter or click to keep · Esc to put back"
        }
    }
}
