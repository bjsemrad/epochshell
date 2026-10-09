import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.commonwidgets
import qs.theme as T
import qs.services as S

// Appearance settings: how the bar, its panels and the workspaces are drawn, in one window over the
// desktop.
//
// Nothing behind it is dimmed, on purpose. Which bar style and opacity look right depends on the
// wallpaper under it, so the bar and wallpaper have to stay in view while choosing -- and the
// wallpaper can be stepped from here, to try a setting against more than one. Every control
// applies at once and is saved as it is chosen (sliders when let go), into settings.toml like the
// theme switcher's opacity sliders; there is nothing to confirm and nothing to put back.
//
// One for the session, owned by the shell root, like the theme and wallpaper switchers.
PanelWindow {
    id: root

    property bool _visible: false

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
    WlrLayershell.layer: WlrLayer.Overlay
    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    // Clicks reach the card only; everywhere else, the desktop keeps them -- so the bar can still
    // be used to open a panel and see how it looks.
    mask: Region {
        item: card
    }

    function open() {
        if (root._visible) return;
        S.PopupManager.closeAll();
        root._visible = true;
        card.forceActiveFocus();
    }

    function close() {
        root._visible = false;
    }

    function toggle() {
        if (root._visible) root.close();
        else root.open();
    }

    // Apply now, and keep.
    function choose(key, value) {
        T.Config[key] = value;
        T.Config.setSetting(key, value);
    }

    Component.onCompleted: S.PopupManager.registerSettingsOverlay(root)
    Component.onDestruction: S.PopupManager.registerSettingsOverlay(null)

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 760)
        height: content.implicitHeight + T.Config.popupPadding * 3
        radius: T.Config.popupRadius * 1.5
        antialiasing: true
        color: T.Config.popupBackground
        border.width: 1
        border.color: T.Config.surfaceVariant
        focus: true

        Keys.onEscapePressed: root.close()

        // Taken here so a click on the card's ground does not fall through to anything.
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: T.Config.popupPadding * 1.5
            spacing: T.Config.popupLayoutSpacing

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Appearance"
                    color: T.Config.surfaceText
                    font.pixelSize: T.Config.fontSizeXLarge
                    font.bold: true
                    Layout.fillWidth: true
                }

                IconButton {
                    icon: ""
                    onClicked: root.close()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: T.Config.popupPadding * 2

                // --- Bar, workspaces, wallpaper ---------------------------------------------
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    spacing: T.Config.popupLayoutSpacing

                    SectionLabel { text: "Bar" }

                    SegmentedSetting {
                        label: "Style"
                        current: T.Config.barStyle === "floating" || T.Config.barStyle === "islands" ? T.Config.barStyle : "full"
                        options: [
                            { value: "full", label: "Full" },
                            { value: "floating", label: "Floating" },
                            { value: "islands", label: "Islands" }
                        ]
                        onPicked: value => root.choose("barStyle", value)
                    }

                    SettingSlider {
                        visible: T.Config.barFloating
                        label: "Top gap"
                        hint: "From the top of the screen"
                        from: 0
                        to: 24
                        stepSize: 1
                        formatValue: value => Math.round(value) + " px"
                        settingValue: T.Config.barFloatingGap
                        onMoved: value => T.Config.barFloatingGap = Math.round(value)
                        onCommitted: value => T.Config.setSetting("barFloatingGap", Math.round(value))
                    }

                    SettingSlider {
                        visible: T.Config.barFloating
                        label: "Side gap"
                        hint: "Match your window gaps to line up"
                        from: 0
                        to: 48
                        stepSize: 1
                        formatValue: value => Math.round(value) + " px"
                        settingValue: T.Config.barFloatingSideGap
                        onMoved: value => T.Config.barFloatingSideGap = Math.round(value)
                        onCommitted: value => T.Config.setSetting("barFloatingSideGap", Math.round(value))
                    }

                    SettingSlider {
                        label: "Opacity"
                        hint: "100% is solid"
                        from: 0
                        settingValue: T.Config.barOpacity
                        onMoved: value => T.Config.barOpacity = value
                        onCommitted: value => T.Config.setSetting("barOpacity", value)
                    }

                    SegmentedSetting {
                        label: "Workspaces"
                        current: T.Config.workspaceStyle === "plain" || T.Config.workspaceStyle === "bubble" ? T.Config.workspaceStyle : "pill"
                        options: [
                            { value: "pill", label: "Pills" },
                            { value: "bubble", label: "Bubbles" },
                            { value: "plain", label: "Plain" }
                        ]
                        onPicked: value => root.choose("workspaceStyle", value)
                    }

                    SegmentedSetting {
                        label: "Status icons"
                        current: T.Config.statusStyle === "dashboard" ? "dashboard" : "individual"
                        options: [
                            { value: "individual", label: "Individual" },
                            { value: "dashboard", label: "Dashboard" }
                        ]
                        onPicked: value => root.choose("statusStyle", value)
                    }
                }

                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    color: T.Config.surfaceVariant
                }

                // --- Panels, overlays -------------------------------------------------------
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    spacing: T.Config.popupLayoutSpacing

                    SectionLabel { text: "Panels" }

                    SegmentedSetting {
                        label: "Style"
                        hint: T.Config.barOpacity < 0.5 ? "Attached panels float while the bar is under 50%" : ""
                        current: T.Config.panelStyle === "floating" ? "floating" : "attached"
                        options: [
                            { value: "attached", label: "Attached" },
                            { value: "floating", label: "Floating" }
                        ]
                        onPicked: value => root.choose("panelStyle", value)
                    }

                    SegmentedSetting {
                        label: "Outline"
                        current: ["none", "panel", "fade", "bar"].indexOf(T.Config.panelOutline) >= 0 ? T.Config.panelOutline : "fade"
                        options: [
                            { value: "fade", label: "Fade" },
                            { value: "panel", label: "Panel" },
                            { value: "bar", label: "Bar" },
                            { value: "none", label: "None" }
                        ]
                        onPicked: value => root.choose("panelOutline", value)
                    }

                    SettingSlider {
                        label: "Opacity"
                        hint: "Opened from the bar"
                        settingValue: T.Config.panelOpacity
                        onMoved: value => T.Config.panelOpacity = value
                        onCommitted: value => T.Config.setSetting("panelOpacity", value)
                    }

                    // Blur only shows while something is see-through, so it says so rather than
                    // looking broken at 100%.
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: T.Config.layoutMarginSmall

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: "Blur"
                                color: T.Config.surfaceText
                                font.pixelSize: T.Config.fontSizeNormal
                            }

                            Text {
                                text: T.Config.barOpacity >= 0.99 && T.Config.panelOpacity >= 0.99
                                    ? "Shows when the bar or panels are below 100%"
                                    : "Behind the bar and panels"
                                color: T.Config.outline
                                font.pixelSize: T.Config.fontSizeSubtext
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        RoundedSwitch {
                            checked: T.Config.blur
                            onToggled: requested => root.choose("blur", requested)
                        }
                    }

                    SettingSlider {
                        label: "Overlay opacity"
                        hint: "OSDs, notifications, launcher, this window"
                        settingValue: T.Config.popupOpacity
                        onMoved: value => T.Config.popupOpacity = value
                        onCommitted: value => T.Config.setSetting("popupOpacity", value)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: T.Config.surfaceVariant
            }

            // Settings are judged against the wallpaper, so it can be changed without leaving.
            RowLayout {
                Layout.fillWidth: true
                spacing: T.Config.layoutMarginSmall

                Text {
                    text: "Wallpaper"
                    color: T.Config.surfaceText
                    font.pixelSize: T.Config.fontSizeNormal
                }

                IconButton {
                    icon: ""
                    enabled: S.Wallpaper.wallpapers.length > 1
                    onClicked: S.Wallpaper.step(-1)
                }

                IconButton {
                    icon: ""
                    enabled: S.Wallpaper.wallpapers.length > 1
                    onClicked: S.Wallpaper.step(1)
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Theme: " + T.Config.themeName
                    color: T.Config.outline
                    font.pixelSize: T.Config.fontSizeSubtext + 2
                }

                IconButton {
                    icon: ""
                    visible: T.Config.availableThemes.length > 1
                    onClicked: {
                        const overlay = S.PopupManager.themeOverlay;
                        if (!overlay) return;
                        root.close();
                        overlay.open();
                    }
                }
            }
        }
    }
}
