import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.commonwidgets
import qs.services as S
import qs.theme as T

// The other machines on the tailnet. Click one to copy its MagicDNS name, right-click to copy its
// address. With a file chosen for Taildrop, each online peer gets a send button at its right end.
ColumnLayout {
    id: peersSection
    Layout.fillWidth: true
    Layout.bottomMargin: T.Config.layoutMarginSmall
    spacing: 2

    Process {
        id: wlcopy
    }

    SectionLabel {
        text: "Peers"
    }

    Flickable {
        id: peersFlick
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 300)
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: column
            width: peersFlick.width
            spacing: 2

            Repeater {
                model: S.Tailscale.peers

                delegate: ListRow {
                    id: peer
                    required property var modelData

                    icon: modelData.connected ? "󰱓" : "󰅛"
                    iconColor: modelData.connected ? T.Config.accent : T.Config.outline
                    title: modelData.hostName
                    subtitle: [modelData.dnsName, modelData.ip].filter(s => s && s.length > 0).join(" · ")
                    onClicked: mouse => {
                        wlcopy.command = ["wl-copy", mouse.button === Qt.RightButton ? modelData.ip : modelData.dnsName];
                        wlcopy.running = true;
                    }

                    // Send the chosen file here.
                    IconButton {
                        visible: S.Tailscale.selectedFile.length > 0
                        enabled: !S.Tailscale.sendingFile && peer.modelData.taildropTarget.length > 0
                        icon: S.Tailscale.sendingFile && S.Tailscale.sendTarget === peer.modelData.taildropTarget ? "󰔟" : "󰅧"
                        iconColor: T.Config.accent
                        onClicked: S.Tailscale.sendFile(peer.modelData)
                    }
                }
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: peersFlick.contentHeight > peersFlick.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
        }
    }
}
