import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.services as S

// The wired connection as a spec sheet. Only what the network service knows: the device and the
// address.
ColumnLayout {
    id: page

    property bool showBack: false
    signal back()

    Layout.fillWidth: true
    spacing: 0

    ReadoutHeader {
        showBack: page.showBack
        title: "ethernet"
        status: S.Network.ethernetConnected ? "up" : "down"
        active: S.Network.ethernetConnected
        onBack: page.back()
    }

    ReadoutKeyRow {
        key: "device"
        text: S.Network.ethernetDeviceName.length > 0 ? S.Network.ethernetDeviceName : "—"
    }
    ReadoutKeyRow {
        key: "ip"
        text: S.Network.ethernetConnectedIP.length > 0 ? S.Network.ethernetConnectedIP : "—"
    }

    ReadoutDivider {}

    ReadoutRow {
        icon: "󰒓"
        value: "network settings"
        onClicked: S.Network.editNetworks()
    }
}
