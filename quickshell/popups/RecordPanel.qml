import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.commonwidgets
import qs.services as S
import qs.theme as T

// Screen recording in the Readout design: the target, then record -- or, while recording, stop.
HoverPopupWindow {
    id: panel

    popupWidth: 420

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

        ReadoutHeader {
            title: "record"
            status: S.Capture.recording ? "recording " + S.Capture.recordingElapsed : ""
            active: S.Capture.recording
        }
        ReadoutText {
            visible: text.length > 0
            text: {
                if (S.Capture.backendError.length > 0) return S.Capture.backendError.toLowerCase();
                if (!S.Capture.recordAvailable) return "wf-recorder is not installed";
                return S.Capture.recording ? "" : S.Capture.status.toLowerCase();
            }
        }

        ReadoutKeyRow {
            visible: !S.Capture.recording && S.Capture.recordAvailable
            key: "target"
            ReadoutChoice {
                options: S.Capture.windowCapture ? ["region", "window", "pick", "screen", "all"] : ["region", "screen", "all"]
                current: panel.target
                onPicked: v => panel.target = v
            }
        }

        ReadoutDivider {}

        ReadoutRow {
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
        ReadoutRow {
            visible: S.Capture.recording
            icon: "󰙧"
            value: "stop"
            detail: S.Capture.recordingMode
            status: S.Capture.recordingElapsed
            active: true
            onClicked: S.Capture.stopRecording()
        }
        ReadoutRow {
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
