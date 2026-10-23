import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.services as S

ColumnLayout {
    id: page

    property bool showBack: false
    signal back()

    Layout.fillWidth: true
    spacing: 0

    PageHeader {
        showBack: page.showBack
        title: "ethernet"
        status: S.Network.ethernetConnected ? "up" : "down"
        active: S.Network.ethernetConnected
        onBack: page.back()
    }

    KeyRow {
        key: "device"
        text: S.Network.ethernetDeviceName.length > 0 ? S.Network.ethernetDeviceName : "—"
    }
    KeyRow {
        key: "ip"
        text: S.Network.ethernetConnectedIP.length > 0 ? S.Network.ethernetConnectedIP : "—"
    }

    Divider {}

    ListRow {
        icon: "󰒓"
        value: "network settings"
        onClicked: S.Network.editNetworks()
    }
}
