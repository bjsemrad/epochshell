import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import QtQuick.Controls
import QtQuick.Layouts
import "../theme" as T
import "../services" as S
import "../commonwidgets"

// NetworkHeaderRow.qml
import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    width: parent.width
    height: 30
    radius: 40
    color: "transparent"

    // "wifi" or "ethernet"
    property string mode: "wifi"

    // fired when user clicks anywhere on the row (to open popup)
    signal activated()

    // derived status line
    property string subtitle: {
        if (mode === "wifi") {
            if (!S.NetworkMonitor.wifiEnabled)
                return "Off"
            if (S.NetworkMonitor.connected && S.NetworkMonitor.ssid)
                return S.NetworkMonitor.ssid
            return "Not connected"
        } else { // ethernet – you can adapt this to your own ethernet monitor later
            return S.NetworkMonitor.connected ? "Connected" : "Not connected"
        }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        Column {
            spacing: 20
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: mode === "wifi" ? "Wi-Fi" : "Ethernet"
                color: "white"
                font.bold: true
                font.pointSize: 11
            }
        }

        RoundedSwitch{
            id: wifiSwitch
            visible: mode === "wifi"
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            checked: S.NetworkMonitor.wifiEnabled
            onToggled: {
                S.NetworkMonitor.wifiEnabled = checked
            }
        }

        // Wi-Fi toggle (only for wifi mode)
        // Switch {
            // id: wifiSwitch

                // if you later add a real nmcli radio toggle in the singleton,
                // call it here (e.g. net.toggleWifi(checked))
        // }
     }

        // For ethernet mode, just show a status pill (no toggle)
        // Rectangle {
        //     visible: mode === "ethernet"
        //     anchors.verticalCenter: parent.verticalCenter
        //     radius: 8
        //     height: 20
        //     width: implicitWidth
        //     color: S.NetworkMonitor.connected ? "#2c4f2c" : "#3a3a3e"
        //     border.color: "transparent"
        //
        //     Text {
        //         anchors.centerIn: parent
        //         text: S.NetworkMonitor.connected ? "Connected" : "Not connected"
        //         color: S.NetworkMonitor.connected ? "#a6e3a1" : "#c7c7cb"
        //         font.pointSize: 9
        //     }
        // }

    // MouseArea {
    //     anchors.fill: parent
    //     hoverEnabled: true
    //     cursorShape: Qt.PointingHandCursor
    //     onClicked: root.activated()
    //
    //     Rectangle {
    //         anchors.fill: parent
    //         radius: 8
    //         color: "transparent"//hovered ? "#2b2b2f" : "transparent"
    //         z: -1
    //     }
    // }
}
