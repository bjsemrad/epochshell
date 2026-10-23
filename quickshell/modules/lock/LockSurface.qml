import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.theme as T
import qs.services as S

WlSessionLockSurface {
    id: surface

    color: T.Config.background

    readonly property bool shown: S.Lock.locked && !S.Lock.unlocking

    readonly property bool focusedHere: {
        const focused = S.CompositorService.monitors.find(m => m.focused === true);
        const name = focused ? String(focused.name) : (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
        return !surface.screen || surface.screen.name === name;
    }

    property string hostname: ""
    FileView {
        path: "/etc/hostname"
        printErrors: false
        onLoaded: surface.hostname = text().trim()
    }

    readonly property color readableRed: {
        const red = T.Config.red;
        const lum = c => {
            const lin = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
            return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
        };
        const ground = 0.11;
        for (let t = 0; t <= 1; t += 0.1) {
            const c = Qt.rgba(red.r + (1 - red.r) * t, red.g + (1 - red.g) * t, red.b + (1 - red.b) * t, 1);
            if ((lum(c) + 0.05) / (ground + 0.05) >= 4.5) return c;
        }
        return Qt.rgba(1, 1, 1, 1);
    }

    // Ticks in seconds: SystemClock's minute timer does not count time asleep, so it woke showing
    // the time it slept at.
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Item {
        id: backdrop
        anchors.fill: parent

        Image {
            id: wallpaper
            anchors.fill: parent
            source: S.Wallpaper.current.length > 0
                ? "file://" + S.Wallpaper.current.split("/").map(encodeURIComponent).join("/")
                : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            sourceSize: Qt.size(Math.ceil(surface.width / 4), Math.ceil(surface.height / 4))
            visible: false
        }

        MultiEffect {
            anchors.fill: parent
            source: wallpaper
            visible: wallpaper.status === Image.Ready
            blurEnabled: true
            blur: 1.0
            blurMax: 48
            saturation: -0.15
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.45
        }
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: surface.shown ? 1 : 0
        scale: surface.shown ? 1 : 1.03

        Behavior on opacity {
            NumberAnimation {
                duration: S.Lock.unlocking ? S.Lock.unlockFadeMs : 220
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: S.Lock.unlocking ? S.Lock.unlockFadeMs : 220
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            onPressed: field.focusInput()
        }

        // Transparent rather than hidden, so every screen's field still takes keys.
        Item {
            id: face
            anchors.fill: parent
            opacity: surface.focusedHere ? 1 : 0

        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.verticalCenter
            anchors.bottomMargin: 40
            spacing: 10

            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                Text {
                    id: time
                    text: Qt.formatDateTime(clock.date, "h:mm AP").split(" ")[0]
                    color: "white"
                    font.family: T.Config.fontFamily
                    font.pixelSize: 96
                    font.weight: Font.Light
                    font.letterSpacing: -2
                }

                Text {
                    anchors.baseline: time.baseline
                    text: Qt.formatDateTime(clock.date, "AP").toLowerCase()
                    color: Qt.rgba(1, 1, 1, 0.7)
                    font.family: T.Config.fontFamily
                    font.pixelSize: 24
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(clock.date, "dddd · MMMM d").toLowerCase()
                color: Qt.rgba(1, 1, 1, 0.75)
                font.family: T.Config.fontFamily
                font.pixelSize: T.Config.fontSizeLarge
            }
        }

        ColumnLayout {
            id: entry
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.verticalCenter
            anchors.topMargin: 24
            spacing: 8

            PasswordField {
                id: field
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                Layout.preferredWidth: field.width
                Layout.preferredHeight: T.Config.fontSizeNormal * 1.6
                leftPadding: field.textIndent
                text: {
                    if (S.Lock.checking) return "checking…";
                    if (S.Lock.message.length > 0)
                        return S.Lock.message.toLowerCase() + (S.Lock.failures >= 2 ? " · attempt " + S.Lock.failures : "");
                    if (field.capsLock) return "caps lock is on";
                    return "";
                }
                color: {
                    if (S.Lock.messageIsError && !S.Lock.checking && S.Lock.message.length > 0) return surface.readableRed;
                    if (field.capsLock && S.Lock.message.length === 0 && !S.Lock.checking) return T.Config.orange;
                    return Qt.rgba(1, 1, 1, 0.65);
                }
                font.family: T.Config.fontFamily
                font.pixelSize: T.Config.fontSizeNormal
                elide: Text.ElideRight
            }
        }

        // $HOSTNAME is rarely exported to a session.
        Row {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 32
            Text {
                text: Quickshell.env("USER") || ""
                color: T.Config.accent
                font.family: T.Config.fontFamily
                font.pixelSize: T.Config.fontSizeNormal
            }
            Text {
                visible: surface.hostname.length > 0
                text: "@" + surface.hostname
                color: Qt.rgba(1, 1, 1, 0.65)
                font.family: T.Config.fontFamily
                font.pixelSize: T.Config.fontSizeNormal
            }
        }

        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 32
            spacing: 14

            component Pair: Row {
                property string icon
                property string value
                spacing: 6
                Text {
                    text: parent.icon
                    color: Qt.rgba(1, 1, 1, 0.65)
                    font.family: T.Config.fontFamily
                    font.pixelSize: T.Config.fontSizeNormal
                }
                Text {
                    visible: text.length > 0
                    text: parent.value
                    color: Qt.rgba(1, 1, 1, 0.85)
                    font.family: T.Config.fontFamily
                    font.pixelSize: T.Config.fontSizeNormal
                }
            }

            Pair {
                visible: S.Network.ethernetConnected || S.Network.wifiConnected
                icon: S.Network.ethernetConnected ? S.Network.currentEthernetIcon : S.Network.currentWifiIcon
                value: S.Network.ethernetConnected ? "wired" : S.Network.ssid
            }
            Pair {
                visible: S.BatteryService.hasBattery
                icon: S.BatteryService.batteryIcon()
                value: Math.round(S.BatteryService.percentage) + "%" + (S.BatteryService.charging ? " 󱐋" : "")
            }
        }
        }
    }
}
