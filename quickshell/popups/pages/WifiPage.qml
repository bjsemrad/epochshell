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

    function strengthIcon(s) {
        if (s >= Ui.signalStrong) return "󰤨";
        if (s >= Ui.signalFair) return "󰤢";
        if (s >= Ui.signalWeak) return "󰤟";
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

    onVisibleChanged: if (visible) S.Network.refreshAvailable()
    Component.onCompleted: if (visible) S.Network.refreshAvailable()

    PageHeader {
        showBack: page.showBack
        title: "wi-fi"
        active: S.Network.wifiEnabled
        hasSwitch: true
        checked: S.Network.wifiEnabled
        onToggled: S.Network.disableWifi(!S.Network.wifiEnabled)
        onBack: page.back()
    }

    ListRow {
        visible: page.connected
        icon: S.Network.currentWifiIcon
        value: S.Network.ssid
        status: S.Network.wifiConnectedIP
        active: true
        current: true
        hoverStatus: "settings"
        onClicked: S.Network.editNetworks()
    }

    SectionHeader {
        visible: savedRepeater.count > (page.connected ? 1 : 0)
        text: "saved"
    }

    Repeater {
        id: savedRepeater
        model: S.Network.savedAccessPoints
        delegate: ListRow {
            required property string ssid
            readonly property bool connecting: S.Network.wifiConnecting && S.Network.wifiConnectingTo === ssid
            visible: !(page.connected && ssid === S.Network.ssid)
            icon: "󰤨"
            iconColor: Ui.detail
            value: ssid
            status: connecting ? "connecting…" : ""
            hoverStatus: connecting ? "" : "connect · right-click forget"
            onClicked: S.Network.connectTo(ssid)
            onSecondaryClicked: S.Network.deleteNetwork(ssid)
        }
    }

    SectionHeader {
        text: "available"
        trailing: S.Network.wifiScanning ? "scanning…" : "scan"
        trailingClickable: !S.Network.wifiScanning
        onTrailingClicked: S.Network.refreshAvailable()
    }

    Repeater {
        model: S.Network.accessPoints.filter(ap => !ap.active && !page.isSaved(ap.ssid))
        delegate: ListRow {
            required property var modelData
            readonly property bool connecting: S.Network.wifiConnecting && S.Network.wifiConnectingTo === modelData.ssid
            icon: page.strengthIcon(modelData.strength)
            iconColor: Ui.detail
            value: modelData.ssid
            detail: modelData.strength + "%"
            status: connecting ? "connecting…" : ""
            hoverStatus: connecting ? "" : "connect"
            onClicked: S.Network.connectTo(modelData.ssid)
        }
    }

    Note {
        visible: !S.Network.wifiScanning && S.Network.accessPoints.filter(ap => !ap.active && !page.isSaved(ap.ssid)).length === 0
        text: "nothing else in range"
    }
}
