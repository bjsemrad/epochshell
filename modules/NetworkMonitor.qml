// NetworkMonitor.qml
import QtQuick
import Quickshell.Io

Item {
    id: net

    //
    // === PUBLIC PROPERTIES ===
    //
    property bool wifiEnabled: true      // no direct nmcli output — assume true
    property bool connected: false
    property string ssid: ""
    property int strength: 0
    property var accessPoints: []        // array of { ssid, strength, active }

    //
    // === TIMED REFRESH ===
    //
    Timer {
        id: refreshTimer
        interval: 4000    // 4 seconds
        running: true
        repeat: true
        onTriggered: net.refresh()
    }

    Component.onCompleted: net.refresh()

    //
    // === Command Objects ===
    //

    Process {
        id: wifiStatusCmd
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL", "dev", "wifi" ]

        stdout: StdioCollector {
            onStreamFinished: {
                net._parseWifiStatus(text)
            }
        }
    }

    Process {
        id: scanCmd
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL", "dev", "wifi" ]
        stdout: StdioCollector {
            onStreamFinished: {
                net._parseScan(text)
            }
        }
    }

    Process {
        id: connectCmd
        command: "nmcli"
        stdout: StdioCollector {
            onStreamFinished: {
               net.refresh()
                // net._parseScan(text)
            }
        }


        //onExited: {
            // trigger refresh after connect attempt
        //}
    }

    //
    // === API ===
    //
    function refresh() {
        wifiStatusCmd.running = true
        scanCmd.running = true
    }

    function connectTo(ssidName) {
        connectCmd.arguments = [ "dev", "wifi", "connect", ssidName ]
        connectCmd.running = true
    }

    //
    // === PARSING ===
    //
    function _parseWifiStatus(text) {
        let lines = text.trim().split("\n")
        if (lines.length === 0) {
            connected = false
            ssid = ""
            strength = 0
            return
        }

        // Find the active entry (ACTIVE=yes)
        let activeLine = lines.find(l => l.startsWith("yes:"))
        if (!activeLine) {
            connected = false
            ssid = ""
            strength = 0
            return
        }

        let p = activeLine.split(":")
        connected = (p[0] === "yes")
        ssid = p[1] ?? ""
        strength = parseInt(p[2] ?? "0") || 0
    }

    function _parseScan(text) {
        let lines = text.trim().split("\n")
        let aps = []

        for (let line of lines) {
            let p = line.split(":")
            aps.push({
                active: p[0] === "yes",
                ssid: p[1],
                strength: parseInt(p[2] ?? "0") || 0
            })
        }
        
        // ✅ Dedupe by SSID
        let map = {}
        for (let ap of aps) {
            if (!ap.ssid) continue
            let key = ap.ssid
            if (!map[key] || ap.active || ap.strength > map[key].strength)
                map[key] = ap
        }

        accessPoints = Object.values(map).sort((a, b) => b.strength - a.strength)
    }

    // function _parseScan(text) {
    //     let lines = text.trim().split("\n")
    //     let aps = []
    //
    //     for (let line of lines) {
    //         if (!line.length) continue
    //         let p = line.split(":")
    //         aps.push({
    //             active: (p[0] === "yes"),
    //             ssid: p[1],
    //             strength: parseInt(p[2] ?? "0") || 0,
    //         })
    //     }
    //     accessPoints = aps
    // }
}

