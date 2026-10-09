import QtQuick
import qs.theme as T

// A small round icon button for a panel's header or a row's right end -- settings, refresh,
// remove. Quiet until the pointer is on it.
Rectangle {
    id: button

    property string icon: ""
    property color iconColor: T.Config.surfaceText
    // For the accent filled variant, used for the main action of a row (play, send).
    property bool accent: false
    property int size: T.Config.barIconSize + T.Config.popupPadding * 1.4

    signal clicked()

    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    antialiasing: true
    opacity: enabled ? 1 : 0.4
    color: button.accent ? T.Config.accent
        : mouse.containsMouse ? T.Config.onPanel(T.Config.surfaceContainerHigh) : "transparent"

    Text {
        anchors.centerIn: parent
        text: button.icon
        color: button.accent ? T.Config.background : button.iconColor
        font.pixelSize: T.Config.fontSizeLarge
        font.family: T.Config.fontFamily
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
