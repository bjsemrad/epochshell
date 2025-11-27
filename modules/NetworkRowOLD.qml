import QtQuick
import Quickshell
import Quickshell.Widgets
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: row
    width: parent ? parent.width : 260
    height: 26

    property string ssid
    property string subtitle: ""
    property bool connected: false
    property bool secure: false
    property int signalStrength: 0 // 0–100 or 0–4, you decide

    signal clicked()
    signal secondaryClicked()

    Row {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        spacing: 8

        // signal strength icon placeholder – swap to your themed icons
        IconImage {
            width: 16; height: 16
            source: {
                if (signalStrength >= 75) return Quickshell.iconPath("network-wireless-signal-excellent-symbolic")
                if (signalStrength >= 50) return Quickshell.iconPath("network-wireless-signal-good-symbolic")
                if (signalStrength >= 25) return Quickshell.iconPath("network-wireless-signal-ok-symbolic")
                if (signalStrength > 0)   return Quickshell.iconPath("network-wireless-signal-weak-symbolic")
                return Quickshell.iconPath("network-wireless-signal-none-symbolic")
            }
            // color: "white"
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            spacing: 0
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: ssid.length ? ssid : "(Hidden Network)"
                color: "white"
                font.pointSize: 10
                elide: Text.ElideRight
                width: row.width - 64
            }

            Text {
                visible: subtitle !== ""
                text: subtitle
                color: "#7b7b81"
                font.pointSize: 8
                elide: Text.ElideRight
                width: row.width - 64
            }
        }

        Item { Layout.fillWidth: true; width: 1 }

        // Lock icon
        IconImage {
            visible: secure
            width: 12; height: 12
            source: "network-wireless-encrypted-symbolic"
            // color: "#bdbdc2"
            anchors.verticalCenter: parent.verticalCenter
        }

        // Connected dot
        Rectangle {
            visible: connected
            width: 8; height: 8
            radius: 4
            color: "#4a93ff"
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onPressed: mouse => {
            if (mouse.button === Qt.RightButton)
                secondaryClicked()
        }

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)
                clicked()
        }

        // simple hover highlight
        Rectangle {
            anchors.fill: parent
            color: hovered ? "#2b2b2f" : "transparent"
            z: -1
        }
    }
}
