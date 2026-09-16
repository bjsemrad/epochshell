import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Io
import qs.commonwidgets
import qs.modules
import qs.modules.system
import qs.theme as T
import qs.services as S

HoverPopupWindow {
    id: systemMenuPopup
    trigger: trigger
    popupWidth: T.Config.systemPopupWidth

    property string username

    Process {
        id: whoami
        command: ["whoami"]
        running: true

        stdout: SplitParser {
            onRead: data => username = data.trim()
        }
    }

    Component.onDestruction: S.PopupManager.unregister(systemMenuPopup)
    Component.onCompleted: S.PopupManager.register(systemMenuPopup, "system")

    onVisibleChanged: {
        if (visible) {
            S.SystemInfo.refresh();
            S.NightLight.refresh();
            S.StayAwake.refresh();
            S.PopupManager.closeOthers(systemMenuPopup);
        }
    }

    // Header
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: T.Config.settingsHeaderHeight
        spacing: T.Config.layoutMarginSmall

        Text {
            text: "System"
            color: T.Config.surfaceText
            font.pixelSize: T.Config.fontSizeLarge
            font.bold: true
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: "󱄅"
            color: T.Config.accent
            font.pixelSize: T.Config.fontSizeLarge
            font.bold: true
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: systemMenuPopup.username
            color: T.Config.surfaceText
            font.pixelSize: T.Config.fontSizeLarge
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // What this machine is. Three facts people look up and never remember: the model, the firmware
    // it is running, and the kernel. Laid out as label/value pairs so the values line up rather
    // than running together in a sentence.
    GridLayout {
        Layout.fillWidth: true
        Layout.topMargin: 2
        columns: 2
        columnSpacing: T.Config.layoutMarginSmall
        rowSpacing: 1
        visible: S.SystemInfo.machine.length > 0 || S.SystemInfo.kernel.length > 0

        Text {
            text: "model"
            visible: S.SystemInfo.machine.length > 0
            color: T.Config.outline
            font.pixelSize: T.Config.fontSizeSubtext
        }
        Text {
            text: S.SystemInfo.machine
            visible: S.SystemInfo.machine.length > 0
            color: T.Config.surfaceText
            font.pixelSize: T.Config.fontSizeSubtext
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        Text {
            text: "bios"
            visible: S.SystemInfo.biosVersion.length > 0
            color: T.Config.outline
            font.pixelSize: T.Config.fontSizeSubtext
        }
        Text {
            text: S.SystemInfo.biosVersion
            visible: S.SystemInfo.biosVersion.length > 0
            color: T.Config.surfaceText
            font.pixelSize: T.Config.fontSizeSubtext
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        Text {
            text: "kernel"
            visible: S.SystemInfo.kernel.length > 0
            color: T.Config.outline
            font.pixelSize: T.Config.fontSizeSubtext
        }
        Text {
            text: S.SystemInfo.kernel
            visible: S.SystemInfo.kernel.length > 0
            color: T.Config.surfaceText
            font.pixelSize: T.Config.fontSizeSubtext
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
    }

    ComponentSplitter {}

    // How the screen looks and what the session is doing, above the power actions: things you set,
    // rather than things that end the session. Night mode and stay awake also have a toggle in the
    // bar drawer, which is the quick way to reach them; these rows are the ones that say what the
    // state actually is -- the temperature the screen is held at, how long the machine has been
    // held awake, which palette is on. Every one reads its service rather than its own last click,
    // so the views never disagree.
    ColumnLayout {
        Layout.fillWidth: true
        spacing: T.Config.popupLayoutSpacing

        ToggleRow {
            label: "Night mode"
            hint: S.NightLight.available
                  ? (S.NightLight.enabled ? (S.NightLight.temperature + "K") : "Warm the screen")
                  : S.NightLight.unavailableReason
            checkedValue: S.NightLight.enabled
            enableToggle: S.NightLight.available

            function handleToggled(checked) {
                S.NightLight.set(checked);
            }
        }

        ToggleRow {
            label: "Stay awake"
            hint: S.StayAwake.enabled ? ("held for " + S.StayAwake.held) : "Prevent idle lock and sleep"
            checkedValue: S.StayAwake.enabled
            visible: S.StayAwake.available

            function handleToggled(checked) {
                S.StayAwake.set(checked);
            }
        }

        ThemeSelector {
            id: themeRow
            popup: themePanel
        }

        WallpaperRow {
            menu: systemMenuPopup
        }
    }

    ComponentSplitter {}

    // Power actions
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Process {
            id: lock
            command: ["hyprlock"]
        }

        SystemAction {
            icon: "󰌾"
            description: "Lock"
            function onClick() {
                lock.running = true;
            }
        }

        Process {
            id: sleep
            command: ["systemctl", "suspend"]
        }

        SystemAction {
            icon: "󰤄"
            description: "Sleep"
            function onClick() {
                sleep.running = true;
            }
        }

        Process {
            id: reboot
            command: ["systemctl", "reboot"]
        }

        SystemAction {
            icon: "󰜉"
            description: "Restart"
            function onClick() {
                reboot.running = true;
            }
        }

        Process {
            id: poweroff
            command: ["systemctl", "poweroff"]
        }

        SystemAction {
            icon: "⏻"
            description: "Shutdown"
            function onClick() {
                poweroff.running = true;
            }
        }

        Process {
            id: logout
            command: ["sh", "/home/" + systemMenuPopup.username + "/.config/wmscripts/logout.sh"]
        }

        SystemAction {
            icon: "󰗽"
            description: "Logout"
            function onClick() {
                logout.running = true;
            }
        }
    }

    ComponentSpacer {
        bottomMargin: 6
    }

    // The picker hangs off the Theme row, so while it is up this menu must not close itself when
    // the pointer leaves -- the pointer has gone into the picker, and closing would take the
    // window the picker is anchored to out from under it.
    ThemePanel {
        id: themePanel
        trigger: themeRow
        parentPanel: systemMenuPopup
        onOpenChanged: {
            systemMenuPopup.stopHide = open;
            if (!open) systemMenuPopup._updateHover();
        }
    }
}
