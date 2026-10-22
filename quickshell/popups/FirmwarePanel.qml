import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.services as S
import qs.theme as T

// Firmware in the Readout design, the same shape as Nix: the machine, each update waiting, and the
// actions.
HoverPopupWindow {
    id: panel

    popupWidth: 460

    Component.onDestruction: S.PopupManager.unregister(panel)
    Component.onCompleted: S.PopupManager.register(panel, "firmware")

    onVisibleChanged: {
        if (visible) {
            S.SystemInfo.refreshFirmware(false);
            S.PopupManager.closeOthers(panel);
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Keys.onEscapePressed: panel.hidePanel()

        ReadoutHeader {
            title: "firmware"
            status: !S.SystemInfo.firmwareAvailable ? "unavailable" : S.SystemInfo.hasFirmwareUpdates ? "update" : "current"
            active: S.SystemInfo.hasFirmwareUpdates
        }
        ReadoutKeyRow {
            visible: text.length > 0
            key: "machine"
            text: [S.SystemInfo.vendor, S.SystemInfo.product].filter(x => x && x.length > 0).join(" ")
        }
        ReadoutKeyRow {
            visible: S.SystemInfo.biosVersion.length > 0
            key: "bios"
            text: S.SystemInfo.biosVersion
        }
        ReadoutText {
            visible: !S.SystemInfo.firmwareAvailable
            text: "fwupd is not available"
        }

        ReadoutSection {
            visible: S.SystemInfo.firmwareUpdates.length > 0
            text: "updates"
        }
        Repeater {
            model: S.SystemInfo.firmwareUpdates
            delegate: ReadoutRow {
                required property var modelData
                icon: S.SystemInfo.firmwareIcon
                value: String(modelData.name || "")
                detail: String(modelData.current || "?") + " → " + String(modelData.available || "?")
                status: "behind"
                active: true
                interactive: false
            }
        }

        ReadoutDivider {}

        ReadoutRow {
            icon: "󰑐"
            value: "check again"
            onClicked: S.SystemInfo.refreshFirmware(true)
        }
        ReadoutRow {
            visible: S.SystemInfo.hasFirmwareUpdates
            icon: "󰚰"
            value: "install updates"
            active: true
            onClicked: {
                S.PopupManager.closeAll();
                S.SystemInfo.updateFirmware();
            }
        }
    }
}
