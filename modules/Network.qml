import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import "../theme" as T

Item {
    implicitWidth: 26
    implicitHeight: 26

    property bool connected: false
    property bool wired: false
    property string iconName: "network-offline-symbolic"


    Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: update()
    }

    Process {
        id: nm
        running: false
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device", "status"]

        stdout: StdioCollector {
            onTextChanged: {
                let rows = text.trim().split("\n")

                let isWifi = false
                let isWired = false

                for (let row of rows) {
                    if (!row) continue
                    const p = row.split(":")
                    if (p.length < 3) continue

                    const type = p[1]
                    const state = p[2]

                    if (state === "connected") {
                        if (type === "wifi") isWifi = true
                        if (type === "ethernet") isWired = true
                    }
                }

                if (isWifi) {
                    connected = true
                    wired = false
                } else if (isWired) {
                    connected = true
                    wired = true
                } else {
                    connected = false
                    wired = false
                }

                updateIcon()
            }
        }
    }

    function update() { nm.running = true }

    function updateIcon() {
        if (!connected)
            iconName = "network-offline-symbolic"
        else if (wired)
            iconName = "network-wired-symbolic"
        else
            iconName = "network-wireless-signal-excellent-symbolic"
    }

    IconImage {
        anchors.centerIn: parent
        implicitSize: 20
        source: Quickshell.iconPath(iconName)
    }

    Component.onCompleted: update()
}

