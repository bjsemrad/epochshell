import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.theme as T
import qs.services as S

// Firmware waiting to be installed.
//
// The panel lists what fwupd is offering and hands the job to fwupd: "Install updates" opens
// `fwupdmgr update` in a terminal, because it asks for a password, prints what it is about to
// write, and often ends by asking for a reboot. A shell panel is the wrong place for any of that.
HoverPopupWindow {
    id: firmwarePopup
    trigger: trigger
    popupWidth: T.Config.nixPopupWidth

    onVisibleChanged: {
        if (visible) {
            S.SystemInfo.refreshFirmware(false);
            S.PopupManager.closeOthers(firmwarePopup);
        }
    }

    Component.onDestruction: S.PopupManager.unregister(firmwarePopup)
    Component.onCompleted: S.PopupManager.register(firmwarePopup, "firmware")

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: T.Config.settingsHeaderHeight
        spacing: T.Config.layoutMarginSmall

        Text {
            text: "Firmware"
            color: T.Config.surfaceText
            font.pixelSize: T.Config.fontSizeLarge
            font.bold: true
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
    }

    StatusCard {
        icon: S.SystemInfo.firmwareIcon
        active: S.SystemInfo.hasFirmwareUpdates
        problem: !S.SystemInfo.firmwareAvailable
        title: {
            const count = S.SystemInfo.firmwareUpdates.length;
            if (!S.SystemInfo.firmwareAvailable) return "fwupd is not available";
            if (count === 0) return "Everything is up to date";
            return count === 1 ? "1 update waiting" : (count + " updates waiting");
        }
        subtitle: [S.SystemInfo.vendor, S.SystemInfo.product].filter(x => x && x.length > 0).join(" ")
        detail: S.SystemInfo.biosVersion.length > 0 ? "BIOS " + S.SystemInfo.biosVersion : ""
    }

    ComponentSplitter {}

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        SectionLabel {
            visible: S.SystemInfo.firmwareUpdates.length > 0
            text: "Updates"
        }

        Repeater {
            model: S.SystemInfo.firmwareUpdates

            delegate: ListRow {
                required property var modelData
                icon: "󰍛"
                title: String(modelData.name || "")
                subtitle: String(modelData.current || "?") + " → " + String(modelData.available || "?")
                clickable: false
            }
        }
    }

    ComponentSplitter {}

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        SystemAction {
            icon: "󰑐"
            description: "Check again"
            function onClick() {
                S.SystemInfo.refreshFirmware(true);
            }
        }

        SystemAction {
            icon: "󰚰"
            description: "Install updates"
            visible: S.SystemInfo.hasFirmwareUpdates
            function onClick() {
                S.PopupManager.closeAll();
                S.SystemInfo.updateFirmware();
            }
        }
    }

    ComponentSpacer { bottomMargin: 6; Layout.preferredHeight: 1 }
}
