import QtQuick
import qs.theme as T

Row {
    id: choice

    property var options: []
    property string current: ""
    signal picked(string value)

    spacing: Ui.space2XL

    Repeater {
        model: choice.options

        delegate: Item {
            id: option
            required property var modelData
            readonly property string value: typeof modelData === "string" ? modelData : String(modelData.value)
            readonly property string label: typeof modelData === "string" ? modelData : String(modelData.label || modelData.value)
            readonly property bool selected: option.value === choice.current
            width: word.implicitWidth
            height: Ui.rowHeight

            Text {
                id: word
                anchors.verticalCenter: parent.verticalCenter
                text: option.label
                color: option.selected || optionMouse.containsMouse ? Ui.value : T.Config.inactive
                font.pixelSize: Ui.valueSize
                font.family: Ui.font
            }

            Rectangle {
                visible: option.selected
                anchors.top: word.bottom
                anchors.topMargin: 2
                width: word.width
                height: Ui.tick
                color: Ui.accent
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
