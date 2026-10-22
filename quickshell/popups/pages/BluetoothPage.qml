import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.commonwidgets
import qs.services as S

// Bluetooth, Readout style: what is connected, what is paired, and -- while scanning -- what is
// in range.
ColumnLayout {
    id: page

    property bool showBack: false
    signal back()

    Layout.fillWidth: true
    spacing: 0

    // By `connected`, as the dashboard's Bluetooth row counts them: `state` can lag behind it.
    readonly property var connectedDevices: (S.Bluetooth.pairedDevices || []).filter(d => d.connected)
    readonly property var otherPaired: (S.Bluetooth.pairedDevices || []).filter(d => !d.connected)

    function batteryText(device) {
        return device && device.batteryAvailable ? Math.round(device.battery * 100) + "%" : "";
    }

    // A scan is for the page while it is up, not left running behind it.
    onVisibleChanged: if (!visible) S.Bluetooth.stopScan()

    ReadoutHeader {
        showBack: page.showBack
        title: "bluetooth"
        active: S.Bluetooth.enabled
        hasSwitch: true
        checked: S.Bluetooth.enabled
        onToggled: S.Bluetooth.toggle(!S.Bluetooth.enabled)
        onBack: page.back()
    }

    ReadoutSection {
        visible: page.connectedDevices.length > 0
        text: "connected"
    }
    Repeater {
        model: page.connectedDevices
        delegate: ReadoutRow {
            required property var modelData
            icon: S.Bluetooth.getDeviceIcon(modelData)
            value: modelData.name || ""
            detail: page.batteryText(modelData)
            status: "active"
            active: true
            hoverStatus: "disconnect"
            onClicked: modelData.disconnect()
        }
    }

    ReadoutSection {
        visible: page.otherPaired.length > 0
        text: "paired"
    }
    Repeater {
        model: page.otherPaired
        delegate: ReadoutRow {
            required property var modelData
            readonly property bool connecting: modelData.state === BluetoothDeviceState.Connecting
            icon: S.Bluetooth.getDeviceIcon(modelData)
            iconColor: Readout.detail
            value: modelData.name || ""
            status: connecting ? "connecting…" : ""
            hoverStatus: connecting ? "" : "connect"
            onClicked: modelData.connect()
        }
    }

    ReadoutSection {
        visible: S.Bluetooth.enabled
        text: "available"
        trailing: S.Bluetooth.discovering ? "scanning… stop" : "scan"
        trailingClickable: true
        onTrailingClicked: S.Bluetooth.discovering ? S.Bluetooth.stopScan() : S.Bluetooth.scanForDevices()
    }
    Repeater {
        model: S.Bluetooth.discovering ? S.Bluetooth.devices : []
        delegate: ReadoutRow {
            required property var modelData
            icon: S.Bluetooth.getDeviceIcon(modelData)
            iconColor: Readout.detail
            value: modelData.name || ""
            hoverStatus: "pair"
            onClicked: {
                modelData.trusted = true;
                modelData.connect();
            }
        }
    }
}
