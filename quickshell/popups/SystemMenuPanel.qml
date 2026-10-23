import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.commonwidgets
import qs.services as S
import qs.theme as T
import qs.popups.pages

HoverPopupWindow {
    id: menu

    property string page: "main"

    popupWidth: Ui.panelWidth

    Component.onDestruction: S.PopupManager.unregister(menu)
    Component.onCompleted: S.PopupManager.register(menu, "system")

    onVisibleChanged: {
        if (visible) {
            S.SystemInfo.refresh();
            S.NightLight.refresh();
            S.StayAwake.refresh();
            S.PopupManager.closeOthers(menu);
            Qt.callLater(power.focusFirst);
        } else {
            page = "main";
        }
    }

    function goTo(name) {
        menu.stopHide = true;
        menu.page = name;
        settle.restart();
    }
    Timer {
        id: settle
        interval: Ui.pageSettleMs
        onTriggered: menu.stopHide = false
    }

    property string username: ""
    property string hostname: ""
    Process {
        command: ["whoami"]
        running: true
        stdout: SplitParser { onRead: data => menu.username = data.trim() }
    }
    Process {
        command: ["hostname"]
        running: true
        stdout: SplitParser { onRead: data => menu.hostname = data.trim() }
    }
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Keys.onEscapePressed: menu.page === "main" ? menu.hidePanel() : menu.goTo(menu.page === "theme" ? "appearance" : "main")
        Keys.onLeftPressed: if (menu.page !== "main") menu.goTo(menu.page === "theme" ? "appearance" : "main")

        ColumnLayout {
            visible: menu.page === "main"
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: Ui.spaceM
                Layout.bottomMargin: Ui.spaceS
                text: [menu.username, [menu.hostname, S.SystemInfo.kernel].filter(x => x && x.length > 0).join(" "),
                    Qt.formatDate(clock.date, "ddd d MMM").toLowerCase()].filter(x => x && x.length > 0).join(" · ")
                color: Ui.detail
                font.pixelSize: Ui.detailSize
                font.family: Ui.font
                elide: Text.ElideRight
            }

            ListRow {
                icon: S.NightLight.icon
                value: "night mode"
                detail: S.NightLight.enabled ? S.NightLight.temperature + "k" : ""
                status: S.NightLight.available ? "" : "unavailable"
                active: S.NightLight.enabled
                interactive: S.NightLight.available
                toggleable: true
                onToggled: S.NightLight.set(!S.NightLight.enabled)
            }
            ListRow {
                visible: S.StayAwake.available
                icon: S.StayAwake.icon
                value: "stay awake"
                detail: S.StayAwake.enabled ? "held for " + S.StayAwake.held : ""
                active: S.StayAwake.enabled
                toggleable: true
                onToggled: S.StayAwake.set(!S.StayAwake.enabled)
            }
            ListRow {
                icon: "󰏘"
                value: "appearance"
                detail: [T.Config.themeName, S.Wallpaper.current.length > 0 ? S.Wallpaper.displayName(S.Wallpaper.current) : ""]
                    .filter(x => x.length > 0).join(" · ")
                hasPage: true
                onOpened: menu.goTo("appearance")
            }

            Divider {}

            PowerPage {
                id: power
                showHeader: false
            }
        }

        AppearancePage {
            visible: menu.page === "appearance"
            showBack: true
            panel: menu
            onBack: menu.goTo("main")
            onOpenTheme: menu.goTo("theme")
        }
        ThemePage {
            visible: menu.page === "theme"
            showBack: true
            onBack: menu.goTo("appearance")
        }
    }
}
