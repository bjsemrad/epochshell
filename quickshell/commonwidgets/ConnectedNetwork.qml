import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.theme as T

// The connection a panel is about -- the Wi-Fi network, the wired link, the tailnet -- at the top,
// set apart from the list below by its size alone: the larger icon in its disc and the larger name.
// No ground behind it; that would be a box around something that already reads as the summary.
// Connected, its icon is in the accent: the same signal a list row uses for the one in use, so
// "blue icon" means one thing everywhere. The inner padding stays, so the icon lines up with the
// rows' icons. The name and the address each copy themselves when clicked, since
// those are what you go to a panel to fetch.
Rectangle {
    id: card

    required property bool connectedStatus
    required property string networkIconText
    required property string connectedName
    required property string connectedIp

    Layout.fillWidth: true
    Layout.topMargin: T.Config.layoutMarginSmall
    implicitHeight: content.implicitHeight + T.Config.popupPadding * 2
    radius: T.Config.cardRadius
    antialiasing: true
    color: "transparent"

    Process {
        id: wlcopy
    }

    function copy(text) {
        if (!text || text.length === 0) return;
        wlcopy.command = ["wl-copy", text];
        wlcopy.running = true;
    }

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: T.Config.popupPadding
        spacing: T.Config.layoutSpacingSmall / 2 + T.Config.layoutMarginSmall

        // The icon in a disc, which gives the summary its weight; the icon carries the state.
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: T.Config.connectedIconSize
            implicitHeight: T.Config.connectedIconSize
            radius: width / 2
            antialiasing: true
            color: T.Config.onPanel(T.Config.surfaceContainerHigh)

            Text {
                anchors.centerIn: parent
                text: card.networkIconText
                color: card.connectedStatus ? T.Config.accent : T.Config.inactive
                font.pixelSize: T.Config.fontSizeLarge
                font.family: T.Config.fontFamily
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                text: card.connectedStatus ? card.connectedName : "Disconnected"
                color: T.Config.surfaceText
                font.pixelSize: T.Config.fontSizeMedium
                font.bold: card.connectedStatus
                font.underline: card.connectedStatus && nameMouse.containsMouse
                Layout.fillWidth: true
                elide: Text.ElideRight

                MouseArea {
                    id: nameMouse
                    anchors.fill: parent
                    enabled: card.connectedStatus
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.copy(card.connectedName)
                }
            }

            Text {
                visible: card.connectedStatus && card.connectedIp.length > 0
                text: card.connectedIp
                color: T.Config.inactive
                font.pixelSize: T.Config.fontSizeSubtext + 2
                font.family: T.Config.fontFamily
                font.underline: ipMouse.containsMouse
                Layout.fillWidth: true
                elide: Text.ElideRight

                MouseArea {
                    id: ipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.copy(card.connectedIp)
                }
            }
        }
    }
}
