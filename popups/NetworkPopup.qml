// popups/NetworkPopup.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import "./../theme" as T

PanelWindow {
    id: popup
    visible: false
    exclusiveZone: 0

    // --- anchor under bar ---
    anchors.top: true
    anchors.left: true
    anchors.right: true
    property int barHeight: 40       // overridden from bar
    margins.top: barHeight

    color: "transparent"
    implicitHeight: bg.implicitHeight + 10

    //--------------------------------
    // Public open/close
    //--------------------------------
    function openPopup() {
        visible = true
        refresh()
        autoRefresh.start()
        showAnim.start()
    }

    function closePopup() {
        hideAnim.start()
        autoRefresh.stop()
    }

    //--------------------------------
    // Auto refresh
    //--------------------------------
    Timer {
        id: autoRefresh
        interval: 6000
        repeat: true
        onTriggered: refresh()
    }

    //--------------------------------
    // WiFi scan
    //--------------------------------
    property var networks: []

    function refresh() {
        scanProc.running = true
    }

    Process {
        id: scanProc
        running: false
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                popup.networks = text.trim()
                    .split("\n")
                    .filter(x=>x.length)
                    .map(line => {
                        let [active, ssid, signal, security] = line.split(":")
                        return {
                            active: active === "yes",
                            ssid,
                            signal: parseInt(signal),
                            secure: security.length > 0
                        }
                    })
            }
        }
    }

    //--------------------------------
    // UI
    //--------------------------------
    Rectangle {
        id: bg
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 6
        radius: 10
        color: "#1e2329"
        border.width: 1
        border.color: "#333"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            Text {
                text: "Wi-Fi"
                font.pixelSize: 15
                font.bold: true
                color: "white"
            }

            Repeater {
                model: popup.networks

                Rectangle {
                    Layout.fillWidth: true
                    height: 26
                    radius: 6
                    color: modelData.active ? "#284060" : "#30363f"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 6

                        IconImage {
                            implicitSize: 16
                            source: Quickshell.iconPath(
                                modelData.signal >= 75
                                ? "network-wireless-signal-excellent-symbolic"
                                : modelData.signal >= 50
                                ? "network-wireless-signal-good-symbolic"
                                : modelData.signal >= 25
                                ? "network-wireless-signal-ok-symbolic"
                                : "network-wireless-signal-weak-symbolic"
                            )
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.ssid.length ? modelData.ssid : "(Hidden)"
                            color: modelData.active ? "#cceeff" : "#ddd"
                        }

                        Text {
                            visible: modelData.secure
                            text: "🔒"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (modelData.ssid.length) {
                                Process.execDetached([
                                    "nmcli", "device", "wifi", "connect", modelData.ssid
                                ])
                                popup.closePopup()
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 28
                radius: 6
                color: "#30363f"

                Text {
                    anchors.centerIn: parent
                    text: "Network Settings"
                    color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Process.execDetached(["nm-connection-editor"])
                }
            }
        }
    }

    // ======================
    // Animation
    // ======================
    property real animVal: 0
    // scale: animVal
    // opacity: animVal

    NumberAnimation {
        id: showAnim
        target: popup
        property: "animVal"
        from: 0
        to: 1
        duration: 150
    }
    NumberAnimation {
        id: hideAnim
        target: popup
        property: "animVal"
        from: 1
        to: 0
        duration: 120
        onStopped: popup.visible = false
    }
}

