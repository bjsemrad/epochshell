import QtQuick
import qs.theme as T

Row {
    id: stepper

    property int value: 0
    property int from: 0
    property int to: 10
    signal stepped(int value)

    spacing: 10

    component Step: Text {
        id: step
        property int by: 1
        readonly property bool possible: by < 0 ? stepper.value > stepper.from : stepper.value < stepper.to
        height: Ui.rowHeight
        verticalAlignment: Text.AlignVCenter
        color: !possible ? Ui.segmentOff : stepMouse.containsMouse ? Ui.value : T.Config.inactive
        font.pixelSize: Ui.valueSize
        font.family: Ui.font
        MouseArea {
            id: stepMouse
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            enabled: step.possible
            cursorShape: Qt.PointingHandCursor
            onClicked: stepper.stepped(stepper.value + step.by)
        }
    }

    Step { text: "−"; by: -1 }
    Text {
        height: Ui.rowHeight
        verticalAlignment: Text.AlignVCenter
        text: stepper.value
        color: Ui.value
        font.pixelSize: Ui.valueSize
        font.family: Ui.font
    }
    Step { text: "+"; by: 1 }
}
