import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import qs.commonwidgets
import qs.services as S
import qs.theme as T

HoverPopupWindow {
    id: panel

    popupWidth: 500

    Component.onDestruction: S.PopupManager.unregister(panel)
    Component.onCompleted: S.PopupManager.register(panel, "localsend")

    onVisibleChanged: {
        if (visible) {
            S.LocalSend.refresh();
            S.PopupManager.closeOthers(panel);
        }
    }

    function iconFor(deviceType) {
        switch (String(deviceType || "").toLowerCase()) {
        case "mobile": return "󰄜";
        case "web": return "󰖟";
        case "headless":
        case "server": return "󰒋";
        default: return "󰇄";
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Keys.onEscapePressed: panel.hidePanel()

        PageHeader {
            title: "localsend"
            status: S.LocalSend.receivingAvailable ? "receiving" : "not receiving"
            active: S.LocalSend.receivingAvailable
        }
        KeyRow {
            visible: S.LocalSend.receivingAvailable && S.LocalSend.downloadDir.length > 0
            key: "saves to"
            text: S.LocalSend.downloadDir
        }
        Note {
            visible: text.length > 0
            text: (S.LocalSend.backendError || S.LocalSend.receiveStatus || "").toLowerCase()
        }

        SectionHeader {
            visible: S.LocalSend.hasIncomingFiles
            text: "incoming"
        }
        Repeater {
            model: S.LocalSend.incomingTransfers
            delegate: ColumnLayout {
                id: transfer
                required property var modelData
                readonly property string session: String(modelData.session || "")
                readonly property var files: modelData.files || []
                Layout.fillWidth: true
                spacing: 0

                ListRow {
                    icon: S.LocalSend.icon
                    value: String(transfer.modelData.device || "unknown device")
                    detail: transfer.files.length + (transfer.files.length === 1 ? " file" : " files")
                    active: true
                    interactive: false

                    Row {
                        spacing: 12
                        Repeater {
                            model: [{ label: "accept", accept: true }, { label: "decline", accept: false }]
                            delegate: Text {
                                required property var modelData
                                height: Ui.rowHeight
                                verticalAlignment: Text.AlignVCenter
                                text: modelData.label
                                color: decisionMouse.containsMouse ? Ui.value : modelData.accept ? Ui.accent : Ui.detail
                                font.pixelSize: Ui.detailSize
                                font.family: Ui.font
                                MouseArea {
                                    id: decisionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: modelData.accept ? S.LocalSend.acceptTransfer(transfer.session) : S.LocalSend.declineTransfer(transfer.session)
                                }
                            }
                        }
                    }
                }
                Repeater {
                    model: transfer.files
                    delegate: ListRow {
                        required property var modelData
                        icon: "󰈔"
                        iconColor: Ui.detail
                        value: modelData.name || "unnamed file"
                        detail: S.LocalSend.formatBytes(modelData.size || 0)
                        interactive: false
                    }
                }
            }
        }

        SectionHeader {
            text: "send"
            trailing: S.LocalSend.scanning ? "scanning…" : "refresh"
            trailingClickable: !S.LocalSend.scanning
            onTrailingClicked: S.LocalSend.refresh()
        }
        ListRow {
            icon: S.LocalSend.selectedFile.length > 0 ? "󰈔" : "󰈙"
            value: S.LocalSend.selectedFile.length > 0 ? S.LocalSend.fileName(S.LocalSend.selectedFile) : "choose a file to send"
            detail: S.LocalSend.sendStatus.toLowerCase()
            hoverStatus: S.LocalSend.selectedFile.length > 0 ? "clear" : "browse"
            onClicked: S.LocalSend.selectedFile.length > 0 ? S.LocalSend.clearSelectedFile() : fileDialog.open()
        }
        Repeater {
            model: S.LocalSend.devices
            delegate: ListRow {
                required property var modelData
                readonly property bool sending: S.LocalSend.sendingFile && S.LocalSend.sendTarget === String(modelData.alias)
                readonly property bool sendable: S.LocalSend.selectedFile.length > 0 && !S.LocalSend.sendingFile
                icon: panel.iconFor(modelData.device_type)
                value: String(modelData.alias || "")
                detail: [String(modelData.device_model || ""), String(modelData.ip || "")].filter(x => x.length > 0).join(" · ")
                status: sending ? "sending…" : sendable ? "send ›" : ""
                statusColor: Ui.accent
                interactive: sendable
                onClicked: S.LocalSend.sendFile(modelData)
            }
        }
        Note {
            visible: !S.LocalSend.hasDevices && !S.LocalSend.scanning
            text: "no devices -- open localsend on another device on this network, then refresh"
        }
    }

    FileDialog {
        id: fileDialog
        title: "Send with LocalSend"
        fileMode: FileDialog.OpenFile
        onAccepted: {
            S.LocalSend.selectFile(selectedFile);
            Qt.callLater(() => panel.showPanel());
        }
    }
}
