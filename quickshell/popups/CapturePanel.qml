import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.commonwidgets
import qs.services as S
import qs.theme as T

HoverPopupWindow {
    id: panel

    popupWidth: Ui.panelWidth

    property string target: "region"
    property bool readText: false

    Component.onDestruction: S.PopupManager.unregister(panel)
    Component.onCompleted: S.PopupManager.register(panel, "capture")

    onVisibleChanged: {
        if (visible) {
            S.Capture.refresh();
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
    readonly property bool ocr: readText && target === "region" && S.Capture.ocrAvailable

    function go() {
        const mode = modes[target] || modes.region;
        if (ocr) S.Capture.readText(mode[0], mode[1]);
        else S.Capture.shoot(mode[0], mode[1]);
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Keys.onEscapePressed: panel.hidePanel()

        PageHeader {
            title: "capture"
            status: S.Capture.busy ? "busy…" : ""
        }
        Note {
            visible: text.length > 0
            text: {
                if (S.Capture.backendError.length > 0) return S.Capture.backendError.toLowerCase();
                if (!S.Capture.available && S.Capture.unavailableReason.length > 0) return S.Capture.unavailableReason.toLowerCase();
                return S.Capture.status.toLowerCase();
            }
        }

        KeyRow {
            key: "target"
            Choice {
                options: S.Capture.windowCapture ? ["region", "window", "pick", "screen", "all"] : ["region", "screen", "all"]
                current: panel.target
                onPicked: v => panel.target = v
            }
        }
        KeyRow {
            visible: S.Capture.ocrAvailable && panel.target === "region"
            key: "text"
            toggles: true
            onToggled: panel.readText = !panel.readText
            ToggleSwitch {
                checked: panel.readText
                onToggled: panel.readText = !panel.readText
            }
        }
        KeyRow {
            key: "clipboard"
            toggles: true
            onToggled: S.Capture.setCopyToClipboard(!S.Capture.copyToClipboard)
            ToggleSwitch {
                checked: S.Capture.copyToClipboard
                onToggled: S.Capture.setCopyToClipboard(!S.Capture.copyToClipboard)
            }
        }
        KeyRow {
            visible: !panel.ocr
            key: "save"
            toggles: true
            onToggled: S.Capture.setSaveToDisk(!S.Capture.saveToDisk)
            ToggleSwitch {
                checked: S.Capture.saveToDisk
                onToggled: S.Capture.setSaveToDisk(!S.Capture.saveToDisk)
            }
        }
        KeyRow {
            visible: !panel.ocr
            key: "pointer"
            toggles: true
            onToggled: S.Capture.setIncludeCursor(!S.Capture.includeCursor)
            ToggleSwitch {
                checked: S.Capture.includeCursor
                onToggled: S.Capture.setIncludeCursor(!S.Capture.includeCursor)
            }
        }
        KeyRow {
            visible: S.Capture.annotateAvailable && !panel.ocr
            key: "annotate"
            toggles: true
            onToggled: S.Capture.setAnnotate(!S.Capture.annotate)
            ToggleSwitch {
                checked: S.Capture.annotate
                onToggled: S.Capture.setAnnotate(!S.Capture.annotate)
            }
        }

        Divider {}

        ListRow {
            icon: panel.ocr ? "󰈙" : S.Capture.icon
            value: panel.ocr ? "read text" : "capture"
            status: "↵"
            active: true
            interactive: !S.Capture.busy
            onClicked: panel.go()
        }
        ListRow {
            visible: S.Capture.directory.length > 0
            icon: "󰉋"
            value: "open folder"
            detail: S.Capture.directory
            onClicked: {
                S.PopupManager.closeAll();
                openFolder.command = ["xdg-open", S.Capture.directory];
                openFolder.running = true;
            }
        }
    }
}
