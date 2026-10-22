import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.services as S

// The Wi-Fi page, Readout style: shared by the dashboard and the standalone Wi-Fi panel. The
// connected network once, then the saved ones, then what is in range -- each network appears in
// one place only.
ColumnLayout {
    id: page

    property bool showBack: false
    signal back()

    Layout.fillWidth: true
    spacing: 0

    function strengthIcon(s) {
        if (s >= 75) return "󰤨";
        if (s >= 50) return "󰤢";
        if (s >= 25) return "󰤟";
        return "󰤯";
    }
    function isSaved(ssid) {
        const model = S.Network.savedAccessPoints;
        for (let i = 0; i < model.count; i++) {
            if (model.get(i).ssid === ssid) return true;
        }
        return false;
    }
    readonly property bool connected: S.Network.wifiConnected && S.Network.ssid.length > 0

    // Asked for the networks in range whenever the page comes up, rather than behind a click.
    onVisibleChanged: if (visible) S.Network.refreshAvailable()
    Component.onCompleted: if (visible) S.Network.refreshAvailable()

    ReadoutHeader {
        showBack: page.showBack
        title: "wi-fi"
        active: S.Network.wifiEnabled
        hasSwitch: true
        checked: S.Network.wifiEnabled
        onToggled: S.Network.disableWifi(!S.Network.wifiEnabled)
        onBack: page.back()
    }

    ReadoutRow {
        visible: page.connected
        icon: S.Network.currentWifiIcon
        value: S.Network.ssid
        status: S.Network.wifiConnectedIP
        active: true
        hoverStatus: "settings"
        onClicked: S.Network.editNetworks()
    }

    ReadoutSection {
        visible: savedRepeater.count > (page.connected ? 1 : 0)
        text: "saved"
    }

    Repeater {
        id: savedRepeater
        model: S.Network.savedAccessPoints
        delegate: ReadoutRow {
            required property string ssid
            readonly property bool connecting: S.Network.wifiConnecting && S.Network.wifiConnectingTo === ssid
            visible: !(page.connected && ssid === S.Network.ssid)
            icon: "󰤨"
            iconColor: Readout.detail
            value: ssid
            status: connecting ? "connecting…" : ""
            hoverStatus: connecting ? "" : "connect · right-click forget"
            onClicked: S.Network.connectTo(ssid)
            onSecondaryClicked: S.Network.deleteNetwork(ssid)
        }
    }

    ReadoutSection {
        text: "available"
        trailing: S.Network.wifiScanning ? "scanning…" : "scan"
        trailingClickable: !S.Network.wifiScanning
        onTrailingClicked: S.Network.refreshAvailable()
    }

    Repeater {
        model: S.Network.accessPoints.filter(ap => !ap.active && !page.isSaved(ap.ssid))
        delegate: ReadoutRow {
            required property var modelData
            readonly property bool connecting: S.Network.wifiConnecting && S.Network.wifiConnectingTo === modelData.ssid
            icon: page.strengthIcon(modelData.strength)
            iconColor: Readout.detail
            value: modelData.ssid
            detail: modelData.strength + "%"
            status: connecting ? "connecting…" : ""
            hoverStatus: connecting ? "" : "connect"
            onClicked: S.Network.connectTo(modelData.ssid)
        }
    }

    ReadoutText {
        visible: !S.Network.wifiScanning && S.Network.accessPoints.filter(ap => !ap.active && !page.isSaved(ap.ssid)).length === 0
        text: "nothing else in range"
    }
}
