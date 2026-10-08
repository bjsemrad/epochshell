import QtQuick
import QtQuick.Layouts
import qs.services as S
import qs.theme as T

// How full the battery is and what it is doing, in the same shape as a panel's connection summary,
// and like it with no ground behind it: the icon in a disc -- in the accent while charging -- with the percentage large beside
// it and the state underneath. A bar along the bottom shows the charge at a glance.
Rectangle {
    id: card
    Layout.fillWidth: true
    Layout.topMargin: T.Config.layoutMarginSmall
    implicitHeight: content.implicitHeight + T.Config.popupPadding * 2 + meter.height + 4
    radius: T.Config.cardRadius
    antialiasing: true
    color: "transparent"

    readonly property real level: Math.max(0, Math.min(100, S.BatteryService.percentage))
    // Low is worth seeing from across the room.
    readonly property color levelColor: S.BatteryService.charging ? T.Config.accent
        : card.level <= 15 ? T.Config.red
        : card.level <= 30 ? T.Config.orange
        : T.Config.accent

    RowLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: T.Config.popupPadding
        spacing: T.Config.layoutMarginSmall * 2

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: T.Config.connectedIconSize
            implicitHeight: T.Config.connectedIconSize
            radius: width / 2
            antialiasing: true
            color: T.Config.surfaceContainerHigh

            Text {
                anchors.centerIn: parent
                text: S.BatteryService.batteryIcon()
                color: card.levelColor
                font.pixelSize: T.Config.fontSizeLarge
                font.family: T.Config.fontFamily
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                text: Math.round(card.level) + "%"
                color: T.Config.surfaceText
                font.pixelSize: T.Config.fontSizeXLarge
                font.bold: true
            }

            Text {
                visible: text.length > 0
                text: S.BatteryService.stateText()
                color: T.Config.inactive
                font.pixelSize: T.Config.fontSizeSubtext
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }
    }

    // The charge, as a bar.
    Rectangle {
        id: meter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: T.Config.popupPadding
        height: 4
        radius: 2
        color: T.Config.surfaceContainerHigh

        Rectangle {
            width: parent.width * card.level / 100
            height: parent.height
            radius: parent.radius
            color: card.levelColor
        }
    }
}
