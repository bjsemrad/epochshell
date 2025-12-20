import QtQuick
import QtQuick.Controls
import qs.theme as T

Item {
    id: root
    width: T.Config.switchHeight
    height: T.Config.switchWidth
    property bool checked: false
    signal toggled

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        border.width: 1
        border.color: checked ? T.Config.accent : T.Config.surfaceVariant

        color: checked ? T.Config.accent : T.Config.surfaceContainer
        Behavior on color {
            ColorAnimation {
                duration: 160
            }
        }
    }

    Rectangle {
        id: knob
        width: T.Config.switchKnobSize
        height: T.Config.switchKnobSize
        radius: T.Config.switchKnobRadius
        y: 2
        x: checked ? (root.width - width - 2) : 2
        color: checked ? T.Config.surface : T.Config.surfaceContainerHighest

        Text {
            text: ""
            anchors.centerIn: parent
            color: checked ? T.Config.accent : T.Config.surfaceContainerHighest
            font.pixelSize: T.Config.fontSizeNormal
            font.bold: true
        }

        Behavior on x {
            NumberAnimation {
                duration: 160
                easing.type: Easing.InOutQuad
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 160
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.checked = !root.checked;
            root.toggled();
        }
    }
}
