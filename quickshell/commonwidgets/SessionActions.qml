import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.theme as T
import qs.services as S

// Ending or pausing the session, in one row: lock, sleep, restart, shut down, log out. Each is a
// TileButton, sharing the row equally. Shared by the dashboard and the system menu, so the
// two cannot drift apart.
//
// The lock is the shell's own (modules/lock), not an external locker: a second locker would race
// it for the session lock and for the fingerprint reader. Every panel is closed first, so none is
// still open behind the lock when the session comes back.
RowLayout {
    id: root
    Layout.fillWidth: true
    Layout.bottomMargin: T.Config.layoutMarginSmall
    spacing: T.Config.cardSpacing

    property string username
    Process {
        command: ["whoami"]
        running: true
        stdout: SplitParser {
            onRead: data => root.username = data.trim()
        }
    }

    Process {
        id: sleepProcess
        command: ["systemctl", "suspend"]
    }
    Process {
        id: rebootProcess
        command: ["systemctl", "reboot"]
    }
    Process {
        id: poweroffProcess
        command: ["systemctl", "poweroff"]
    }
    Process {
        id: logoutProcess
        command: ["sh", "/home/" + root.username + "/.config/wmscripts/logout.sh"]
    }

    TileButton {
        icon: "󰌾"
        label: "Lock"
        onClicked: {
            S.PopupManager.closeAll();
            S.Lock.lock();
        }
    }
    TileButton {
        icon: "󰤄"
        label: "Sleep"
        onClicked: sleepProcess.running = true
    }
    TileButton {
        icon: "󰜉"
        label: "Restart"
        onClicked: rebootProcess.running = true
    }
    TileButton {
        icon: "⏻"
        label: "Shut down"
        onClicked: poweroffProcess.running = true
    }
    TileButton {
        icon: "󰗽"
        label: "Log out"
        onClicked: logoutProcess.running = true
    }
}
