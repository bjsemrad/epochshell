import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.commonwidgets
import qs.services as S

ColumnLayout {
    id: page

    property bool showBack: false
    signal back()

    Layout.fillWidth: true
    spacing: 0

    // By `connected`: `state` can lag behind it.
    readonly property var connectedDevices: (S.Bluetooth.pairedDevices || []).filter(d => d.connected)
    readonly property var otherPaired: (S.Bluetooth.pairedDevices || []).filter(d => !d.connected)

    function batteryText(device) {
        return device && device.batteryAvailable ? Math.round(device.battery * 100) + "%" : "";
    }

    onVisibleChanged: if (!visible) S.Bluetooth.stopScan()

    PageHeader {
        showBack: page.showBack
        title: "bluetooth"
        active: S.Bluetooth.enabled
        hasSwitch: true
        checked: S.Bluetooth.enabled
        onToggled: S.Bluetooth.toggle(!S.Bluetooth.enabled)
        onBack: page.back()
    }

    SectionHeader {
        visible: page.connectedDevices.length > 0
        text: "connected"
    }
    Repeater {
        model: page.connectedDevices
        delegate: ListRow {
            required property var modelData
            icon: S.Bluetooth.getDeviceIcon(modelData)
            value: modelData.name || ""
            detail: page.batteryText(modelData)
            status: "active"
            active: true
            current: true
            hoverStatus: "disconnect"
            onClicked: modelData.disconnect()
        }
    }

    SectionHeader {
        visible: page.otherPaired.length > 0
        text: "paired"
    }
    Repeater {
        model: page.otherPaired
        delegate: ListRow {
            required property var modelData
            readonly property bool connecting: modelData.state === BluetoothDeviceState.Connecting
            icon: S.Bluetooth.getDeviceIcon(modelData)
            iconColor: Ui.detail
            value: modelData.name || ""
            status: connecting ? "connecting…" : ""
            hoverStatus: connecting ? "" : "connect"
            onClicked: modelData.connect()
        }
    }

    SectionHeader {
        visible: S.Bluetooth.enabled
        text: "available"
        trailing: S.Bluetooth.discovering ? "scanning… stop" : "scan"
        trailingClickable: true
        onTrailingClicked: S.Bluetooth.discovering ? S.Bluetooth.stopScan() : S.Bluetooth.scanForDevices()
    }
    Repeater {
        model: S.Bluetooth.discovering ? S.Bluetooth.devices : []
        delegate: ListRow {
            required property var modelData
            icon: S.Bluetooth.getDeviceIcon(modelData)
            iconColor: Ui.detail
            value: modelData.name || ""
            hoverStatus: "pair"
            onClicked: {
                modelData.trusted = true;
                modelData.connect();
            }
        }
    }
}
