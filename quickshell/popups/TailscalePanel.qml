import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell.Io
import qs.commonwidgets
import qs.services as S
import qs.theme as T

// Tailscale in the Readout design: on or off in the header, this machine, Taildrop both ways, and
// the peers. A peer's row copies its name (its address on a right click); with a file chosen it
// sends the file there instead.
HoverPopupWindow {
    id: panel

    popupWidth: 460

    Component.onDestruction: S.PopupManager.unregister(panel)
    Component.onCompleted: S.PopupManager.register(panel, "tailscale")

    onVisibleChanged: {
        if (visible) {
            S.Tailscale.refresh();
            S.PopupManager.closeOthers(panel);
        }
    }

    Process {
        id: wlcopy
    }

    property string hostname: ""
    Process {
        command: ["hostname"]
        running: true
        stdout: SplitParser { onRead: data => panel.hostname = data.trim() }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Keys.onEscapePressed: panel.hidePanel()

        ReadoutHeader {
            title: "tailscale"
            active: S.Tailscale.connected
            hasSwitch: true
            checked: S.Tailscale.connected
            onToggled: S.Tailscale.toggle(!S.Tailscale.connected)
        }

        ReadoutRow {
            visible: S.Tailscale.connected
            icon: "󰒄"
            // This machine, by its name.
            value: panel.hostname
            detail: S.Tailscale.magicDNSSuffix
            status: S.Tailscale.connectedIP
            active: true
            hoverStatus: "trayscale"
            onClicked: S.Tailscale.trayscale()
        }

        ReadoutText {
            visible: S.Tailscale.backendError.length > 0
            text: S.Tailscale.backendError.toLowerCase()
        }

        // --- Taildrop ---
        ReadoutSection { text: "taildrop" }
        ReadoutRow {
            icon: S.Tailscale.selectedFile.length > 0 ? "󰈔" : "󰈙"
            value: S.Tailscale.selectedFile.length > 0 ? S.Tailscale.fileName(S.Tailscale.selectedFile) : "choose a file to send"
            detail: S.Tailscale.sendStatus.toLowerCase()
            status: S.Tailscale.selectedFile.length > 0 ? "pick a peer ↓" : ""
            hoverStatus: S.Tailscale.selectedFile.length > 0 ? "clear" : "browse"
            onClicked: S.Tailscale.selectedFile.length > 0 ? S.Tailscale.clearSelectedFile() : fileDialog.open()
        }
        Repeater {
            model: S.Tailscale.incomingFiles
            delegate: ReadoutRow {
                required property var modelData
                icon: "󰈔"
                value: modelData.name || "unnamed file"
                detail: S.Tailscale.formatBytes(modelData.size || 0)
                active: true
                interactive: false
            }
        }
        ReadoutRow {
            visible: S.Tailscale.hasIncomingFiles
            icon: "󰉋"
            value: S.Tailscale.receivingFiles ? "receiving…" : "save incoming files"
            status: "choose folder"
            active: true
            interactive: !S.Tailscale.receivingFiles
            onClicked: folderDialog.open()
        }

        // --- Peers ---
        ReadoutSection {
            visible: S.Tailscale.peers.length > 0
            text: "peers"
        }
        Repeater {
            model: S.Tailscale.peers
            delegate: ReadoutRow {
                required property var modelData
                readonly property bool sendable: S.Tailscale.selectedFile.length > 0 && !S.Tailscale.sendingFile && String(modelData.taildropTarget || "").length > 0
                readonly property bool sending: S.Tailscale.sendingFile && S.Tailscale.sendTarget === modelData.taildropTarget
                icon: modelData.connected ? "󰱓" : "󰅛"
                iconColor: modelData.connected ? Readout.value : Readout.detail
                value: modelData.hostName || ""
                detail: modelData.ip || ""
                status: sending ? "sending…" : sendable ? "send" : modelData.connected ? "online" : "idle"
                statusColor: sendable || sending ? Readout.accent : Readout.detail
                hoverStatus: sendable ? "send here" : "copy name · right-click ip"
                onClicked: {
                    if (sendable) {
                        S.Tailscale.sendFile(modelData);
                        return;
                    }
                    wlcopy.command = ["wl-copy", String(modelData.dnsName || modelData.hostName || "")];
                    wlcopy.running = true;
                }
                onSecondaryClicked: {
                    wlcopy.command = ["wl-copy", String(modelData.ip || "")];
                    wlcopy.running = true;
                }
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: "Send with Tailscale"
        fileMode: FileDialog.OpenFile
        onAccepted: {
            S.Tailscale.selectFile(selectedFile);
            Qt.callLater(() => panel.showPanel());
        }
    }
    FolderDialog {
        id: folderDialog
        title: "Save Taildrop files"
        onAccepted: {
            S.Tailscale.receiveFiles(selectedFolder);
            Qt.callLater(() => panel.showPanel());
        }
    }
}
