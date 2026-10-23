import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.services as S
import qs.theme as T

HoverPopupWindow {
    id: panel

    popupWidth: Ui.panelWidthWide

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

        PageHeader {
            title: "firmware"
            status: !S.SystemInfo.firmwareAvailable ? "unavailable" : S.SystemInfo.hasFirmwareUpdates ? "update" : "current"
            active: S.SystemInfo.hasFirmwareUpdates
        }
        KeyRow {
            visible: text.length > 0
            key: "machine"
            text: [S.SystemInfo.vendor, S.SystemInfo.product].filter(x => x && x.length > 0).join(" ")
        }
        KeyRow {
            visible: S.SystemInfo.biosVersion.length > 0
            key: "bios"
            text: S.SystemInfo.biosVersion
        }
        Note {
            visible: !S.SystemInfo.firmwareAvailable
            text: "fwupd is not available"
        }

        SectionHeader {
            visible: S.SystemInfo.firmwareUpdates.length > 0
            text: "updates"
        }
        Repeater {
            model: S.SystemInfo.firmwareUpdates
            delegate: ListRow {
                required property var modelData
                icon: S.SystemInfo.firmwareIcon
                value: String(modelData.name || "")
                detail: String(modelData.current || "?") + " → " + String(modelData.available || "?")
                status: "behind"
                active: true
                interactive: false
            }
        }

        Divider {}

        ListRow {
            icon: "󰑐"
            value: "check again"
            onClicked: S.SystemInfo.refreshFirmware(true)
        }
        ListRow {
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
