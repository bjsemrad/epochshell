import QtQuick
import QtQuick.Layouts
import qs.theme as T

// A button as a tile: an icon over its name on a raised, rounded ground. The session actions are
// these; so are a panel's handful of big actions (capture a region, start recording). Shares a row
// with its siblings equally when laid out in one.
Rectangle {
    id: button

    property string icon: ""
    property string label: ""
    property bool active: false

    signal clicked()

    Layout.fillWidth: true
    implicitHeight: column.implicitHeight + T.Config.popupPadding * 2
    radius: T.Config.cardRadius
    antialiasing: true
    opacity: enabled ? 1 : 0.4
    color: button.active ? T.Config.accentLightShade
        : mouse.containsMouse ? T.Config.onPanel(T.Config.surfaceContainerHigh) : T.Config.onPanel(T.Config.surfaceContainer)
    border.width: button.active ? 1 : 0
    border.color: T.Config.accent

    ColumnLayout {
        id: column
        anchors.centerIn: parent
        spacing: 2

        Text {
            text: button.icon
            color: button.active ? T.Config.accent : T.Config.surfaceText
            font.pixelSize: T.Config.barIconSize
            font.family: T.Config.fontFamily
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            visible: button.label.length > 0
            text: button.label
            color: T.Config.inactive
            font.pixelSize: T.Config.fontSizeSubtext
            Layout.alignment: Qt.AlignHCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: button.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}
