import QtQuick
import qs.commonwidgets
import qs.services as S

// A saved Wi-Fi network: click to connect. Lit when it is the one you are on.
ListRow {
    id: root
    property string ssid: ""

    readonly property bool current: S.Network.wifiConnected && S.Network.ssid === root.ssid
    readonly property bool connecting: S.Network.wifiConnecting && S.Network.wifiConnectingTo === root.ssid

    icon: root.current ? S.Network.currentWifiIcon : "󰤨"
    title: root.ssid
    subtitle: root.current ? "Connected" : root.connecting ? "Connecting…" : ""
    active: root.current
    onClicked: S.Network.connectTo(root.ssid)

    Spinner {
        running: root.connecting
        visible: running
    }
}
