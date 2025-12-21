pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: nixService

    readonly property string configDir: Quickshell.shellDir
    property string username
    property bool updatesAvailable: false
    property string updateText

    Process {
        id: whoami
        command: ["whoami"]
        running: false

        stdout: SplitParser {
            onRead: data => username = data.trim()
        }
    }

    Component.onCompleted: {
        whoami.running = true;
        checkForUpdates.running = true;
    }

    Timer {
        id: refreshTimer
        interval: 60 * 60 * 1000
        repeat: true

        onTriggered: {
            checkForUpdates.running = true;
        }
    }

    Process {
        id: checkForUpdates
        command: ["sh", "-c", configDir + "/services/scripts/updateCheck.sh", "/home/" + username + "/nixconfig"]

        stdout: StdioCollector {
            onStreamFinished: {
                console.log(checkForUpdates.command);
                updateText = text;
                console.log(text);
            }
        }

        onExited: (code, exitStatus) => {
            let lastExitCode = code;
            console.log(code);
            console.log(exitStatus);
            if (lastExitCode === 2) {
                updatesAvailable = true;
            } else {
                updatesAvailable = false;
            }
        }
    }
}
