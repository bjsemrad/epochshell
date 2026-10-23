import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.commonwidgets
import qs.services as S
import qs.theme as T

HoverPopupWindow {
    id: panel

    popupWidth: 480

    property string target: "region"

    Component.onDestruction: S.PopupManager.unregister(panel)
    Component.onCompleted: S.PopupManager.register(panel, "record")

    onVisibleChanged: {
        if (visible) {
            S.Capture.refresh();
            S.Capture.refreshRecording();
            S.PopupManager.closeOthers(panel);
        }
    }

    Process {
        id: openFolder
    }

    readonly property var modes: ({
        "region": ["region", false],
        "window": ["window", false],
        "pick": ["window", true],
        "screen": ["fullscreen", false],
        "all": ["all", false]
    })

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Keys.onEscapePressed: panel.hidePanel()

        PageHeader {
            title: "record"
            status: S.Capture.recording ? "recording " + S.Capture.recordingElapsed : ""
            active: S.Capture.recording
        }
        Note {
            visible: text.length > 0
            text: {
                if (S.Capture.backendError.length > 0) return S.Capture.backendError.toLowerCase();
                if (!S.Capture.recordAvailable) return "wf-recorder is not installed";
                return S.Capture.recording ? "" : S.Capture.status.toLowerCase();
            }
        }

        KeyRow {
            visible: !S.Capture.recording && S.Capture.recordAvailable
            key: "target"
            Choice {
                options: S.Capture.windowCapture ? ["region", "window", "pick", "screen", "all"] : ["region", "screen", "all"]
                current: panel.target
                onPicked: v => panel.target = v
            }
        }

        Divider {}

        ListRow {
            visible: !S.Capture.recording && S.Capture.recordAvailable
            icon: "󰕧"
            value: "record"
            status: "↵"
            active: true
            onClicked: {
                const mode = panel.modes[panel.target] || panel.modes.region;
                S.Capture.startRecording(mode[0], mode[1]);
            }
        }
        ListRow {
            visible: S.Capture.recording
            icon: "󰙧"
            value: "stop"
            detail: S.Capture.recordingMode
            status: S.Capture.recordingElapsed
            active: true
            onClicked: S.Capture.stopRecording()
        }
        ListRow {
            visible: S.Capture.recordingDirectory.length > 0
            icon: "󰉋"
            value: "open folder"
            detail: S.Capture.recordingDirectory
            onClicked: {
                S.PopupManager.closeAll();
                openFolder.command = ["xdg-open", S.Capture.recordingDirectory];
                openFolder.running = true;
            }
        }
    }
}
