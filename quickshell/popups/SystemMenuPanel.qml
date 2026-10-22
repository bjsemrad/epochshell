import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.commonwidgets
import qs.services as S
import qs.theme as T
import qs.popups.pages

// The system menu in the Readout design, for the individual status icons' power icon: who and
// where, the night and stay-awake switches, appearance, and the session. It opens with the focus
// on its first session row, so the keyboard can take it from there.
HoverPopupWindow {
    id: menu

    // "main", "appearance", "theme".
    property string page: "main"

    popupWidth: 420

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

    // Held open through a page change, as the dashboard is (its goTo explains why).
    function goTo(name) {
        menu.stopHide = true;
        menu.page = name;
        settle.restart();
    }
    Timer {
        id: settle
        interval: 400
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
                Layout.leftMargin: 6
                Layout.bottomMargin: 4
                text: [menu.username, [menu.hostname, S.SystemInfo.kernel].filter(x => x && x.length > 0).join(" "),
                    Qt.formatDate(clock.date, "ddd d MMM").toLowerCase()].filter(x => x && x.length > 0).join(" · ")
                color: Readout.detail
                font.pixelSize: Readout.detailSize
                font.family: Readout.font
                elide: Text.ElideRight
            }

            ReadoutRow {
                icon: S.NightLight.icon
                value: "night mode"
                detail: S.NightLight.enabled ? S.NightLight.temperature + "k" : ""
                status: S.NightLight.available ? "" : "unavailable"
                active: S.NightLight.enabled
                interactive: S.NightLight.available
                toggleable: true
                onToggled: S.NightLight.set(!S.NightLight.enabled)
            }
            ReadoutRow {
                visible: S.StayAwake.available
                icon: S.StayAwake.icon
                value: "stay awake"
                detail: S.StayAwake.enabled ? "held for " + S.StayAwake.held : ""
                active: S.StayAwake.enabled
                toggleable: true
                onToggled: S.StayAwake.set(!S.StayAwake.enabled)
            }
            ReadoutRow {
                icon: "󰏘"
                value: "appearance"
                detail: [T.Config.themeName, S.Wallpaper.current.length > 0 ? S.Wallpaper.displayName(S.Wallpaper.current) : ""]
                    .filter(x => x.length > 0).join(" · ")
                hasPage: true
                onOpened: menu.goTo("appearance")
            }

            ReadoutDivider {}

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
