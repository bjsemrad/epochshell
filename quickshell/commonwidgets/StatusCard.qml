import QtQuick
import QtQuick.Layouts
import qs.theme as T

// Where something stands, at the top of its panel: an icon in a disc, a line saying it, and up to
// two quieter lines under that. The same shape as the connection and battery cards.
//
// At rest it has no ground, like the connection summary. `active` lights it in the accent -- there
// is something to act on (updates waiting) -- and `problem` takes it over in red, since then the
// problem is the news: a filled card is reserved for something that wants you.
Rectangle {
    id: card

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property string detail: ""
    property bool active: false
    property bool problem: false

    Layout.fillWidth: true
    Layout.topMargin: T.Config.layoutMarginSmall
    implicitHeight: content.implicitHeight + T.Config.popupPadding * 2
    radius: T.Config.cardRadius
    antialiasing: true
    color: card.active && !card.problem ? T.Config.accentLightShade : "transparent"
    border.width: card.active || card.problem ? 1 : 0
    border.color: card.problem ? T.Config.red : T.Config.accent

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: T.Config.popupPadding
        spacing: T.Config.layoutMarginSmall * 2

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: T.Config.connectedIconSize
            implicitHeight: T.Config.connectedIconSize
            radius: width / 2
            antialiasing: true
            color: card.active && !card.problem ? T.Config.accent : T.Config.onPanel(T.Config.surfaceContainerHigh)

            Text {
                anchors.centerIn: parent
                text: card.icon
                // In the accent -- the same "all is in place" a connected network's icon says --
                // unless there is a problem.
                color: card.active && !card.problem ? T.Config.background
                    : card.problem ? T.Config.red : T.Config.accent
                font.pixelSize: T.Config.fontSizeLarge
                font.family: T.Config.fontFamily
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            Text {
                text: card.title
                color: card.problem ? T.Config.red : T.Config.surfaceText
                font.pixelSize: T.Config.fontSizeNormal
                font.bold: true
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            Text {
                visible: text.length > 0
                text: card.subtitle
                color: T.Config.inactive
                font.pixelSize: T.Config.fontSizeSubtext + 2
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                visible: text.length > 0
                text: card.detail
                color: T.Config.outline
                font.pixelSize: T.Config.fontSizeSubtext + 2
                font.family: T.Config.fontFamily
                Layout.fillWidth: true
                elide: Text.ElideMiddle
            }
        }
    }
}
