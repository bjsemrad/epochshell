import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.theme as T
import qs.services as S

// One screen of the lock: the wallpaper, blurred and dimmed, a clock, and the password field.
//
// Every screen gets one and every one takes typing. The typed text lives in LockService, so the
// dots match on every screen and moving the pointer to another one mid-password loses nothing.
WlSessionLockSurface {
    id: surface

    // Shown under everything, and all there is if the wallpaper has not decoded yet. Opaque on
    // purpose: a lock surface that let anything through would not be one.
    color: T.Config.background

    readonly property bool shown: S.Lock.locked && !S.Lock.unlocking

    // Seconds, though only minutes are shown. SystemClock waits for the next tick on a timer that
    // does not count time asleep, so a minute clock wakes still owing the rest of the minute it
    // went to sleep in: the lock showed the time of the suspend after waking, and a fingerprint
    // unlock beat the catch-up. A second clock is out by a second at most.
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // --- Background -------------------------------------------------------------------------

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
            // A quarter of the screen is plenty for something about to be blurred this hard, and
            // it is a sixteenth of the memory and decode time of a full-size image.
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

        // Dims the picture enough that light text reads over any wallpaper.
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.45
        }
    }

    // --- Foreground -------------------------------------------------------------------------

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

        // A click anywhere leaves the field ready to type into, whichever screen it was on.
        MouseArea {
            anchors.fill: parent
            onPressed: field.focusInput()
        }

        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.verticalCenter
            anchors.bottomMargin: 40
            spacing: 4

            // Twelve-hour, like the bar's clock, with the AM/PM set small beside it so the hour
            // stays the thing that reads from across a room.
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                Text {
                    id: time
                    text: Qt.formatDateTime(clock.date, "h:mm AP").split(" ")[0]
                    color: "white"
                    font.family: T.Config.fontFamily
                    font.pixelSize: 112
                    font.weight: Font.Light
                }

                Text {
                    anchors.baseline: time.baseline
                    text: Qt.formatDateTime(clock.date, "AP")
                    color: Qt.rgba(1, 1, 1, 0.7)
                    font.family: T.Config.fontFamily
                    font.pixelSize: 32
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
                color: Qt.rgba(1, 1, 1, 0.8)
                font.family: T.Config.fontFamily
                font.pixelSize: T.Config.fontSizeXLarge
            }
        }

        ColumnLayout {
            id: entry
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.verticalCenter
            anchors.topMargin: 24
            spacing: 14

            // Who this is, as a circle with an initial: a lock screen is read at a glance, and a
            // name alone is easy to miss.
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 64
                implicitHeight: 64
                radius: 32
                color: Qt.rgba(1, 1, 1, 0.12)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.25)

                Text {
                    anchors.centerIn: parent
                    text: (Quickshell.env("USER") || "?").charAt(0).toUpperCase()
                    color: "white"
                    font.family: T.Config.fontFamily
                    font.pixelSize: 28
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Quickshell.env("USER") || ""
                color: Qt.rgba(1, 1, 1, 0.85)
                font.family: T.Config.fontFamily
                font.pixelSize: T.Config.fontSizeMedium
            }

            PasswordField {
                id: field
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
            }

            // Status: what went wrong, what PAM said, or a hint. Always takes its height, so the
            // layout does not jump when a message appears.
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: T.Config.fontSizeNormal * 1.6
                text: {
                    if (S.Lock.checking) return "Checking…";
                    if (S.Lock.message.length > 0) return S.Lock.message;
                    if (field.capsLock) return "Caps Lock is on";
                    return "";
                }
                color: {
                    if (S.Lock.messageIsError && !S.Lock.checking) return T.Config.red;
                    if (field.capsLock && S.Lock.message.length === 0) return T.Config.orange;
                    return Qt.rgba(1, 1, 1, 0.65);
                }
                font.family: T.Config.fontFamily
                font.pixelSize: T.Config.fontSizeNormal
            }
        }

        // Battery, bottom right: a laptop left locked is a laptop someone will want to know
        // about before walking away from the charger.
        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 32
            spacing: 8
            visible: S.BatteryService.hasBattery

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: S.BatteryService.batteryIcon()
                color: Qt.rgba(1, 1, 1, 0.8)
                font.family: T.Config.fontFamily
                font.pixelSize: T.Config.fontSizeXLarge
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(S.BatteryService.percentage) + "%"
                color: Qt.rgba(1, 1, 1, 0.8)
                font.family: T.Config.fontFamily
                font.pixelSize: T.Config.fontSizeMedium
            }
        }
    }
}
