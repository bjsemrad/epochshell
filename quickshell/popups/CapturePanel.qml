import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.commonwidgets
import qs.services as S
import qs.theme as T

// Capture in the Readout design: what to take and how to keep it as key rows, then the one action.
// Text (OCR) is offered for a region, which is what reading text needs.
HoverPopupWindow {
    id: panel

    popupWidth: 420

    // "region", "window", "pick", "screen", "all".
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

        ReadoutHeader {
            title: "capture"
            status: S.Capture.busy ? "busy…" : ""
        }
        ReadoutText {
            visible: text.length > 0
            text: {
                if (S.Capture.backendError.length > 0) return S.Capture.backendError.toLowerCase();
                if (!S.Capture.available && S.Capture.unavailableReason.length > 0) return S.Capture.unavailableReason.toLowerCase();
                return S.Capture.status.toLowerCase();
            }
        }

        ReadoutKeyRow {
            key: "target"
            ReadoutChoice {
                options: S.Capture.windowCapture ? ["region", "window", "pick", "screen", "all"] : ["region", "screen", "all"]
                current: panel.target
                onPicked: v => panel.target = v
            }
        }
        ReadoutKeyRow {
            visible: S.Capture.ocrAvailable && panel.target === "region"
            key: "text"
            ReadoutSwitch {
                checked: panel.readText
                onToggled: panel.readText = !panel.readText
            }
        }
        ReadoutKeyRow {
            key: "clipboard"
            ReadoutSwitch {
                checked: S.Capture.copyToClipboard
                onToggled: S.Capture.setCopyToClipboard(!S.Capture.copyToClipboard)
            }
        }
        ReadoutKeyRow {
            visible: !panel.ocr
            key: "save"
            ReadoutSwitch {
                checked: S.Capture.saveToDisk
                onToggled: S.Capture.setSaveToDisk(!S.Capture.saveToDisk)
            }
        }
        ReadoutKeyRow {
            visible: !panel.ocr
            key: "pointer"
            ReadoutSwitch {
                checked: S.Capture.includeCursor
                onToggled: S.Capture.setIncludeCursor(!S.Capture.includeCursor)
            }
        }
        ReadoutKeyRow {
            visible: S.Capture.annotateAvailable && !panel.ocr
            key: "annotate"
            ReadoutSwitch {
                checked: S.Capture.annotate
                onToggled: S.Capture.setAnnotate(!S.Capture.annotate)
            }
        }

        ReadoutDivider {}

        ReadoutRow {
            icon: panel.ocr ? "󰈙" : S.Capture.icon
            value: panel.ocr ? "read text" : "capture"
            status: "↵"
            active: true
            interactive: !S.Capture.busy
            onClicked: panel.go()
        }
        ReadoutRow {
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
