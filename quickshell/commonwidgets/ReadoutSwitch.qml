import QtQuick
import qs.theme as T

// The Readout switch: a square-cornered track with a square knob, to match the accent tick
// and the gauge segments rather than a round pill. Off: a faint track, the knob grey on the left.
// On: an accent track, the knob in the background colour on the right. A click flips it; nothing
// slides.
Item {
    id: control

    property bool checked: false
    signal toggled()

    implicitWidth: 34
    implicitHeight: 18

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: control.checked ? T.Config.accent : Readout.alpha(T.Config.surfaceText, 0.12)

        Rectangle {
            x: control.checked ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 12
            height: 12
            radius: 3
            color: control.checked ? T.Config.background : T.Config.inactive
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        onClicked: control.toggled()
    }
}
