import Quickshell
import Quickshell.Wayland        // for WlrLayershell + WlrLayer
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import "../commonwidgets"
import "../modules"
import "../theme" as T
HoverPopupWindow {
    id: networkPopup
    trigger: trigger

    // NetworkMonitor {
    //     id: netMon
    // }

    Row {
        spacing: 10
        width: parent.width
        Column {
            width: T.Config.controlCenterWidth * 0.5 //Math.min(networkPopup.implicitWidth + 20,  parent.width / 2)
            spacing: 20
            AudioVolumePill {}
            NetworkPill{}
        }
        Column {
            width: T.Config.controlCenterWidth * 0.5 //Math.min(networkPopup.implicitWidth + 20,  parent.width / 2)
            spacing: 20
            MicVolumeSlider {}
            BluetoothPill{}
        }
    }
    // Column {
    //     spacing: 10
    //     width: parent.width
    //
    //     // HEADER
    //     Label {
    //         text: "Network"
    //         font.bold: true
    //         font.pixelSize: 15
    //         color: "white"
    //     }
    //
    //     // WIFI SUMMARY + SWITCH
    //     Rectangle {
    //         implicitWidth: parent.width
    //         height: 42
    //         radius: 10
    //         color: T.Config.bg0
    //         // color: net.wifi.enabled ? "#222" : "#333"
    //         border.width: 1
    //         border.color: "#333"
    //         RowLayout {
    //             anchors.fill: parent
    //             anchors.margins: 8
    //             spacing: 10
    //
    //             IconImage {
    //                 source:  Quickshell.iconPath(netMon.connected
    //                         ? "network-wireless-signal-excellent-symbolic"
    //                         : "network-offline-symbolic")
    //                 implicitWidth: 18
    //                 implicitHeight: 18
    //             }
    //
    //             Label {
    //                 text: netMon.connected
    //                       ? `${netMon.ssid}`
    //                       : "Wi-Fi Disabled"
    //                 color: "white"
    //                 Layout.fillWidth: true
    //             }
    //         }
    //     }
    // }

}

