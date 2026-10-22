import QtQuick
import qs.theme as T

// − n + for small integers.
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
        height: Readout.rowHeight
        verticalAlignment: Text.AlignVCenter
        color: !possible ? Readout.segmentOff : stepMouse.containsMouse ? Readout.value : T.Config.inactive
        font.pixelSize: Readout.valueSize
        font.family: Readout.font
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
        height: Readout.rowHeight
        verticalAlignment: Text.AlignVCenter
        text: stepper.value
        color: Readout.value
        font.pixelSize: Readout.valueSize
        font.family: Readout.font
    }
    Step { text: "+"; by: 1 }
}
