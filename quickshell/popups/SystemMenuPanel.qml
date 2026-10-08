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

    // Who and what: the user, and the machine underneath -- the dashboard's header, so the two
    // read as the same thing.
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: T.Config.layoutMarginSmall
        spacing: T.Config.layoutMarginSmall

        Text {
            text: "󱄅"
            color: T.Config.accent
            font.pixelSize: T.Config.fontSizeXLarge
            font.family: T.Config.fontFamily
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: systemMenuPopup.username
                color: T.Config.surfaceText
                font.pixelSize: T.Config.fontSizeLarge
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                visible: text.length > 0
                text: [S.SystemInfo.product, S.SystemInfo.kernel].filter(x => x && x.length > 0).join(" · ")
                color: T.Config.inactive
                font.pixelSize: T.Config.fontSizeSubtext
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
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
            menu: systemMenuPopup
        }

        WallpaperRow {
            menu: systemMenuPopup
        }
    }

    ComponentSplitter {}

    SessionActions {}

    ComponentSpacer {
        bottomMargin: 6
    }
}
