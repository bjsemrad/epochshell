
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Hyprland
import "./theme" as T
Scope {
    id: root

    //
    // ==== BRIGHTNESS STATE ====
    //
    property real brightness: 0.0      // 0‒1 normalized
    property bool initialized: false
    property bool shouldShowOsd: false

    //
    // ==== CHECK IF BACKLIGHT EXISTS ====
    //
    property bool hasBacklight: false

    Process {
        id: backlightListProc
        running: true
        command: ["brightnessctl", "--list"]

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                root.hasBacklight = data.indexOf("class 'backlight'") !== -1
                if (root.hasBacklight)
                    backlightGetValueProc.running = true
            }
        }
    }

    //
    // ==== GET BRIGHTNESS VALUE ====
    // brightnessctl g → current
    // brightnessctl m → max
    //
    Process {
        id: backlightGetValueProc
        running: false
        command: ["sh", "-c", "echo \"$(brightnessctl g) $(brightnessctl m)\""]

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                const s = data.trim().split(" ")
                if (s.length >= 2) {
                    let pct = (parseInt(s[0]) / parseInt(s[1]))
                    if (!root.initialized) {
                        root.initialized = true
                        root.brightness = pct
                        return
                    }

                    if (Math.abs(pct - root.brightness) > 0.001) {
                        root.brightness = pct
                        root.triggerOSD()
                    }
                }
            }
        }
    }

    //
    // ==== POLLING TIMER ====
    //
    Timer {
        id: pollTimer
        interval: 250
        running: true
        repeat: true
        onTriggered: {
            if (root.hasBacklight)
                backlightGetValueProc.running = true
        }
    }

    function triggerOSD() {
        root.shouldShowOsd = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 1000
        onTriggered: root.shouldShowOsd = false
    }

    //
    // ==== UI ====
    //
    LazyLoader {
        active: root.shouldShowOsd

        PanelWindow {
            anchors.top: true
            margins.top: 50
            exclusiveZone: 0

            implicitWidth: 400
            implicitHeight: 75
            color: "transparent"
            mask: Region { }

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: T.Config.osdBg

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 15
                    }

                    IconImage {
			    implicitSize: 30
			    source: Quickshell.iconPath("weather-clear-symbolic")
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 10
                        radius: 20
                        color: "#50ffffff"

                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }

                            implicitWidth: parent.width * root.brightness
                            radius: parent.radius
                            color: "#ffffff"
                        }
                    }
                }
            }
        }
    }
}
