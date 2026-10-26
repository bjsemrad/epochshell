import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.commonwidgets
import qs.popups.pages
import qs.theme as T
import qs.services as S

// The appearance settings as a window of their own (`epochctl settings`): the same page the
// dashboard opens, on a floating card. Nothing behind it is dimmed and clicks off the card reach
// the desktop, so the bar can be tried while choosing.
PanelWindow {
    id: root

    property bool _visible: false
    property string page: "appearance"

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
    WlrLayershell.namespace: "epochshell-settings"
    WlrLayershell.keyboardFocus: _visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    screen: Quickshell.screens.find(s => s.name === S.OsdService.screenName) || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

    BackgroundEffect.blurRegion: T.Config.popupBlur ? cardBlur : null
    Region {
        id: cardBlur
        item: card
        radius: T.Config.popupRadius
    }

    mask: Region {
        item: card
    }

    function open() {
        if (root._visible) return;
        S.PopupManager.closeAll();
        root.page = "appearance";
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

    // AppearancePage closes its host before opening the wallpaper strip.
    function hidePanel() {
        root.close();
    }

    Component.onCompleted: S.PopupManager.registerSettingsOverlay(root)
    Component.onDestruction: S.PopupManager.registerSettingsOverlay(null)

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Ui.settingsWidth
        height: Math.min(content.implicitHeight + T.Config.popupPadding * 3, parent.height - Ui.screenMarginV)
        radius: T.Config.popupRadius
        antialiasing: true
        color: T.Config.popupBackground
        border.width: 1
        border.color: T.Config.outline
        clip: true
        focus: true

        Keys.onEscapePressed: {
            if (root.page !== "appearance") root.page = "appearance";
            else root.close();
        }

        MouseArea {
            anchors.fill: parent
        }

        Flickable {
            anchors.fill: parent
            anchors.leftMargin: T.Config.popupPadding * 2
            anchors.rightMargin: T.Config.popupPadding * 2
            anchors.topMargin: T.Config.popupPadding
            anchors.bottomMargin: T.Config.popupPadding * 2
            contentHeight: content.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            ColumnLayout {
                id: content
                width: parent.width
                spacing: 0

                AppearancePage {
                    visible: root.page === "appearance"
                    panel: root
                    onOpenTheme: root.page = "theme"
                }
                ThemePage {
                    visible: root.page === "theme"
                    showBack: true
                    onBack: root.page = "appearance"
                }
            }
        }
    }
}
