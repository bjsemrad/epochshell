import QtQuick
import qs.theme as T

// Options as words. The current one in the value colour with an accent underline, the rest in
// the inactive colour; click one to pick it.
Row {
    id: choice

    // Strings, or { value, label } where the label differs.
    property var options: []
    property string current: ""
    signal picked(string value)

    spacing: 12

    Repeater {
        model: choice.options

        delegate: Item {
            id: option
            required property var modelData
            readonly property string value: typeof modelData === "string" ? modelData : String(modelData.value)
            readonly property string label: typeof modelData === "string" ? modelData : String(modelData.label || modelData.value)
            readonly property bool selected: option.value === choice.current
            width: word.implicitWidth
            height: Readout.rowHeight

            Text {
                id: word
                anchors.verticalCenter: parent.verticalCenter
                text: option.label
                color: option.selected || optionMouse.containsMouse ? Readout.value : T.Config.inactive
                font.pixelSize: Readout.valueSize
                font.family: Readout.font
            }

            Rectangle {
                visible: option.selected
                anchors.top: word.bottom
                anchors.topMargin: 2
                width: word.width
                height: Readout.tick
                color: Readout.accent
            }

            MouseArea {
                id: optionMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: choice.picked(option.value)
            }
        }
    }
}
