import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.commonwidgets
import qs.theme as T
import qs.services as S

PanelWindow {
    id: root

    property bool _visible: false
    property string tab: "wallpaper"
    property string filter: ""
    BackgroundEffect.blurRegion: T.Config.popupBlur ? stripBlur : null
    Region {
        id: stripBlur
        item: strip
        radius: T.Config.popupRadius
    }
    property bool grid: false

    property string entryWallpaper: ""
    property string entryTheme: ""
    property bool themeTried: false

    property int wallpaperIndex: 0
    property int themeIndex: 0

    readonly property string screenName: {
        const focused = S.CompositorService.monitors.find(m => m.focused === true);
        if (focused) return String(focused.name);
        return Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "";
    }
    screen: Quickshell.screens.find(s => s.name === root.screenName) || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

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
    WlrLayershell.namespace: "epochshell-appearance"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: _visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function matches(name) {
        const q = root.filter.trim().toLowerCase();
        return q.length === 0 || String(name).toLowerCase().includes(q);
    }
    readonly property var wallpapers: S.Wallpaper.wallpapers.filter(path => root.matches(S.Wallpaper.displayName(path)))
    readonly property var themes: T.Config.availableThemes.filter(name => root.matches(name))
    readonly property int count: tab === "wallpaper" ? wallpapers.length : themes.length
    readonly property int index: tab === "wallpaper" ? wallpaperIndex : themeIndex

    function open(which) {
        root.tab = which === "theme" ? "theme" : "wallpaper";
        if (root._visible) return;
        S.Wallpaper.refresh();
        root.filter = "";
        root.grid = false;
        root.themeTried = false;
        root.entryWallpaper = S.Wallpaper.current;
        root.entryTheme = T.Config.themeName;
        root.wallpaperIndex = Math.max(0, root.wallpapers.indexOf(S.Wallpaper.current));
        root.themeIndex = Math.max(0, root.themes.indexOf(T.Config.themeName));
        root._visible = true;
        keys.forceActiveFocus();
        Qt.callLater(root.reveal);
    }
    function reveal() {
        wallpaperStrip.positionViewAtIndex(root.wallpaperIndex, ListView.Center);
        gridView.positionViewAtIndex(root.wallpaperIndex, GridView.Contain);
        themeStrip.positionViewAtIndex(root.themeIndex, ListView.Center);
    }
    onTabChanged: Qt.callLater(reveal)
    onGridChanged: Qt.callLater(reveal)
    function toggle(which) {
        if (root._visible && (which === undefined || which === root.tab)) root.cancel();
        else if (root._visible) root.tab = which;
        else root.open(which);
    }
    function cancel() {
        if (root.entryWallpaper.length > 0 && S.Wallpaper.current !== root.entryWallpaper)
            S.Wallpaper.set(root.entryWallpaper);
        T.Config.endPreview();
        root._visible = false;
    }
    function apply() {
        if (root.themeTried && root.themes[root.themeIndex]) T.Config.selectTheme(root.themes[root.themeIndex]);
        T.Config.endPreview();
        root._visible = false;
    }
    function select(to) {
        if (root.count === 0) return;
        const i = Math.max(0, Math.min(root.count - 1, to));
        if (root.tab === "wallpaper") {
            root.wallpaperIndex = i;
            const path = root.wallpapers[i];
            if (path && S.Wallpaper.current !== path) S.Wallpaper.set(path);
        } else {
            root.themeIndex = i;
            root.themeTried = true;
            T.Config.previewTheme(root.themes[i]);
        }
        root.reveal();
    }
    onFilterChanged: {
        if (!root._visible) return;
        if (root.count > 0) root.select(0);
    }

    QtObject {
        id: wallpaperFront
        readonly property bool _visible: root._visible && root.tab === "wallpaper"
        function open() { root.open("wallpaper"); }
        function toggle() { root.toggle("wallpaper"); }
        function cancel() { root.cancel(); }
    }
    QtObject {
        id: themeFront
        readonly property bool _visible: root._visible && root.tab === "theme"
        function open() { root.open("theme"); }
        function toggle() { root.toggle("theme"); }
        function cancel() { root.cancel(); }
    }
    Component.onCompleted: {
        S.PopupManager.registerWallpaperOverlay(wallpaperFront);
        S.PopupManager.registerThemeOverlay(themeFront);
    }
    Component.onDestruction: {
        S.PopupManager.registerWallpaperOverlay(null);
        S.PopupManager.registerThemeOverlay(null);
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.cancel()
    }

    Rectangle {
        id: strip
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Ui.stripMargin
        height: root.grid && root.tab === "wallpaper" ? Math.round(parent.height * Ui.stripGridFraction) : Ui.stripHeight
        radius: T.Config.popupRadius
        antialiasing: true
        color: T.Config.popupBackground
        border.width: 1
        border.color: T.Config.outline

        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onPressed: event => {
                const perRow = Math.max(1, Math.floor(gridView.width / gridView.cellWidth));
                if (event.key === Qt.Key_Escape) {
                    root.cancel();
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.apply();
                } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                    root.tab = root.tab === "wallpaper" ? "theme" : "wallpaper";
                } else if (event.key === Qt.Key_Left) {
                    root.select(root.index - 1);
                } else if (event.key === Qt.Key_Right) {
                    root.select(root.index + 1);
                } else if (event.key === Qt.Key_Up && root.grid && root.tab === "wallpaper") {
                    root.select(root.index - perRow);
                } else if (event.key === Qt.Key_Down && root.grid && root.tab === "wallpaper") {
                    root.select(root.index + perRow);
                } else if (event.key === Qt.Key_Home) {
                    root.select(0);
                } else if (event.key === Qt.Key_End) {
                    root.select(root.count - 1);
                } else if (event.key === Qt.Key_Backspace) {
                    root.filter = root.filter.slice(0, -1);
                } else if (event.key === Qt.Key_G && root.filter.length === 0 && root.tab === "wallpaper" && !(event.modifiers & Qt.ShiftModifier)) {
                    root.grid = !root.grid;
                } else if (event.text.length === 1 && event.text >= " " && !(event.modifiers & Qt.ControlModifier)) {
                    root.filter += event.text;
                } else {
                    return;
                }
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Ui.space2XL
            spacing: Ui.spaceM

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Ui.stripHeaderHeight
                spacing: Ui.stripTabGap

                Repeater {
                    model: ["wallpaper", "theme"]
                    delegate: Item {
                        required property string modelData
                        implicitWidth: tabText.implicitWidth
                        implicitHeight: Ui.stripControlHeight
                        Text {
                            id: tabText
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData
                            color: root.tab === modelData ? Ui.value : Ui.key
                            font.pixelSize: Ui.detailSize
                            font.family: Ui.font
                        }
                        Rectangle {
                            visible: root.tab === modelData
                            anchors.top: tabText.bottom
                            anchors.topMargin: 2
                            width: tabText.width
                            height: 2
                            color: T.Config.accent
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.tab = modelData
                        }
                    }
                }

                Row {
                    spacing: Ui.spaceL
                    Text {
                        text: "›"
                        color: T.Config.accent
                        font.pixelSize: Ui.detailSize
                        font.family: Ui.font
                    }
                    Text {
                        text: root.filter.length > 0 ? root.filter : "filter"
                        color: root.filter.length > 0 ? Ui.value : Ui.key
                        font.pixelSize: Ui.detailSize
                        font.family: Ui.font
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    visible: root.tab === "wallpaper" && root.wallpapers.length > 0
                    text: {
                        const path = root.wallpapers[root.wallpaperIndex] || "";
                        return S.Wallpaper.displayName(path) + " · " + (root.wallpaperIndex + 1) + " of " + root.wallpapers.length;
                    }
                    color: Ui.detail
                    font.pixelSize: Ui.detailSize
                    font.family: Ui.font
                    elide: Text.ElideMiddle
                }

                Repeater {
                    model: root.tab === "theme" ? [
                        { label: "opacity", key: "barOpacity" }
                    ] : []
                    delegate: Row {
                        required property var modelData
                        spacing: Ui.spaceL
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: strip.width < 900 ? modelData.label.charAt(0) : modelData.label
                            color: Ui.key
                            font.pixelSize: Ui.detailSize
                            font.family: Ui.font
                        }
                        LevelSlider {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitHeight: Ui.stripControlHeight
                            trackWidth: Ui.sliderTrackTiny
                            value: T.Config[modelData.key]
                            onMoved: v => T.Config[modelData.key] = v
                            onCommitted: v => T.Config.setSetting(modelData.key, v)
                        }
                    }
                }
            }

            Text {
                visible: root.tab === "wallpaper" && S.Wallpaper.wallpapers.length === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                verticalAlignment: Text.AlignVCenter
                text: !S.Wallpaper.connected ? "epochoxide is not reachable"
                    : !S.Wallpaper.available && S.Wallpaper.unavailableReason.length > 0 ? S.Wallpaper.unavailableReason
                    : "no images in " + S.Wallpaper.directories.join(", ") + " -- set wallpaper_dirs in epochoxide's config to look elsewhere"
                color: Ui.detail
                font.pixelSize: Ui.detailSize
                font.family: Ui.font
                wrapMode: Text.Wrap
            }

            component Thumb: Item {
                id: thumb
                required property string path
                required property bool selected
                width: Ui.thumbWidth
                height: Ui.thumbHeight + Ui.thumbLabel
                opacity: selected ? 1 : Ui.unselectedAlpha
                Image {
                    id: image
                    width: Ui.thumbWidth
                    height: Ui.thumbHeight
                    source: "file://" + thumb.path
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    sourceSize.width: Ui.thumbWidth * 2
                    clip: true
                }
                Rectangle {
                    visible: thumb.selected
                    anchors.top: image.bottom
                    width: image.width
                    height: Ui.tick
                    color: T.Config.accent
                }
                Text {
                    y: image.height + Ui.spaceM
                    width: image.width
                    text: S.Wallpaper.displayName(thumb.path) + (thumb.path === root.entryWallpaper ? " •" : "")
                    color: thumb.selected ? Ui.value : Ui.detail
                    font.pixelSize: Ui.detailSize
                    font.family: Ui.font
                    elide: Text.ElideMiddle
                }
            }

            ListView {
                id: wallpaperStrip
                visible: root.tab === "wallpaper" && !root.grid && root.wallpapers.length > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: ListView.Horizontal
                spacing: Ui.spaceXL
                clip: true
                model: root.wallpapers
                currentIndex: root.wallpaperIndex
                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: width / 2 - Ui.thumbWidth / 2
                preferredHighlightEnd: width / 2 + Ui.thumbWidth / 2
                highlightMoveDuration: 0
                delegate: Thumb {
                    required property string modelData
                    required property int index
                    path: modelData
                    selected: index === root.wallpaperIndex
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.select(index)
                    }
                }
            }

            GridView {
                id: gridView
                visible: root.tab === "wallpaper" && root.grid && root.wallpapers.length > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                cellWidth: Ui.gridCellWidth
                cellHeight: Ui.gridCellHeight
                clip: true
                model: root.wallpapers
                currentIndex: root.wallpaperIndex
                highlightMoveDuration: 0
                delegate: Thumb {
                    required property string modelData
                    required property int index
                    path: modelData
                    selected: index === root.wallpaperIndex
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.select(index)
                    }
                }
            }

            ListView {
                id: themeStrip
                visible: root.tab === "theme"
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: ListView.Horizontal
                spacing: Ui.spaceXL
                clip: true
                model: root.themes
                currentIndex: root.themeIndex
                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: width / 2 - Ui.thumbWidth / 2
                preferredHighlightEnd: width / 2 + Ui.thumbWidth / 2
                highlightMoveDuration: 0
                delegate: Item {
                    id: specimen
                    required property string modelData
                    required property int index
                    readonly property bool selected: index === root.themeIndex
                    function c(key) {
                        return T.Config.themeColor(specimen.modelData, key);
                    }
                    width: Ui.thumbWidth
                    height: Ui.specimenHeight + Ui.thumbLabel
                    opacity: selected ? 1 : Ui.unselectedAlpha

                    Rectangle {
                        id: card
                        width: Ui.thumbWidth
                        height: Ui.specimenHeight
                        radius: Ui.specimenRadius
                        antialiasing: true
                        color: specimen.c("background")
                        clip: true

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width * Ui.specimenLedgeWidth
                            height: Ui.specimenLedgeHeight
                            bottomLeftRadius: Ui.specimenRadius
                            bottomRightRadius: Ui.specimenRadius
                            color: specimen.c("surfaceContainer")
                        }
                        Rectangle {
                            x: Ui.specimenInset
                            y: Ui.specimenLine1Y
                            width: parent.width * Ui.specimenLineWidth
                            height: Ui.specimenLineHeight
                            color: specimen.c("surfaceText")
                        }
                        Rectangle {
                            x: Ui.specimenInset
                            y: Ui.specimenLine2Y
                            width: parent.width * 0.5
                            height: Ui.specimenLineHeight
                            color: specimen.c("inactive")
                        }
                        Row {
                            x: Ui.specimenInset
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: Ui.specimenInset
                            spacing: Ui.spaceS
                            Repeater {
                                model: ["accent", "green", "red"]
                                delegate: Rectangle {
                                    required property string modelData
                                    width: Ui.swatchSize
                                    height: Ui.swatchSize
                                    color: specimen.c(modelData)
                                }
                            }
                        }
                    }
                    Rectangle {
                        visible: specimen.selected
                        anchors.top: card.bottom
                        width: card.width
                        height: Ui.tick
                        color: T.Config.accent
                    }
                    Text {
                        y: card.height + Ui.spaceM
                        width: card.width
                        text: specimen.modelData + (specimen.modelData === root.entryTheme ? " •" : "")
                        color: specimen.selected ? Ui.value : Ui.detail
                        font.pixelSize: Ui.detailSize
                        font.family: Ui.font
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.select(index)
                    }
                }
            }
        }
    }
}
