import QtQuick
import QtQuick.Layouts
import qs.theme as T

// One row of a list in a panel: a network, a device, an output, an action. Rounded, and lifted a
// shade under the pointer. The one in use -- the network you are on, the output sound goes to --
// is marked by its icon in the accent and its name in bold, the way a menu marks the current
// choice: a selection is something to find, not something to shout. (The dashboard's tiles are
// filled when on because they are switches, whose state has to read from across the screen.)
//
// An icon, a title and an optional subtitle on the left; anything put inside it goes on the right
// (a spinner, a button, a badge), and takes its own clicks rather than the row's.
Rectangle {
    id: row

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    // The one in use.
    property bool active: false
    // Whether clicking the row does anything: a row that does not is not lifted under the pointer.
    property bool clickable: true
    // Colour of the icon when not active, for rows whose icon carries meaning of its own.
    property color iconColor: T.Config.surfaceText

    default property alias trailing: trailingRow.data

    signal clicked(var mouse)

    Layout.fillWidth: true
    implicitHeight: Math.max(T.Config.cardHeight - 8, content.implicitHeight + T.Config.popupPadding)
    radius: T.Config.cardRadius
    antialiasing: true
    color: row.clickable && mouse.containsMouse ? T.Config.onPanel(T.Config.surfaceContainerHigh) : "transparent"

    // Below the content, so whatever sits on the right gets its own clicks.
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: row.clickable
        cursorShape: row.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => row.clicked(event)
    }

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.leftMargin: T.Config.popupPadding
        anchors.rightMargin: T.Config.popupPadding
        spacing: T.Config.layoutMarginSmall

        Text {
            visible: row.icon.length > 0
            text: row.icon
            color: row.active ? T.Config.accent : row.iconColor
            font.pixelSize: T.Config.barIconSize
            font.family: T.Config.fontFamily
            horizontalAlignment: Text.AlignHCenter
            Layout.preferredWidth: T.Config.barIconSize + 6
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                text: row.title
                color: T.Config.surfaceText
                font.pixelSize: T.Config.fontSizeNormal
                font.bold: row.active
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                visible: row.subtitle.length > 0
                text: row.subtitle
                color: T.Config.inactive
                font.pixelSize: T.Config.fontSizeSubtext + 2
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        RowLayout {
            id: trailingRow
            Layout.alignment: Qt.AlignVCenter
            spacing: T.Config.layoutMarginSmall
        }
    }
}
