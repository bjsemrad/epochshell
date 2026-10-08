import QtQuick
import Quickshell.Bluetooth
import qs.commonwidgets
import qs.services as S

// A paired device: click to connect, or to disconnect when it already is. Lit while connected.
ListRow {
    id: root
    property BluetoothDevice device

    readonly property bool connected: device && device.state === BluetoothDeviceState.Connected
    readonly property bool connecting: device && device.state === BluetoothDeviceState.Connecting

    icon: device ? S.Bluetooth.getDeviceIcon(device) : ""
    title: device ? device.name : ""
    subtitle: root.connected ? "Connected" : root.connecting ? "Connecting…" : "Click to connect"
    active: root.connected
    onClicked: {
        if (root.connected) device.disconnect();
        else device.connect();
    }

    Spinner {
        running: root.connecting
        visible: running
    }
}
