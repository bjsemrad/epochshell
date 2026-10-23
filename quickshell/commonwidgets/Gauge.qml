import QtQuick
import qs.theme as T

Row {
    id: gauge

    property real value: 0
    property int segments: Ui.gaugeSegments
    property bool muted: false
    property string label: muted ? "muted" : Math.round(value * 100) + "%"
    property bool showLabel: true
    property int segmentHeight: Ui.segmentHeight
    property color filled: Ui.segmentOn

    spacing: Ui.spaceL

    Item {
        width: gauge.segments * (Ui.segmentWidth + Ui.segmentGap) - Ui.segmentGap
        height: Ui.rowHeight

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Ui.segmentGap

            Repeater {
                model: gauge.segments
                delegate: Rectangle {
                    required property int index
                    width: Ui.segmentWidth
                    height: gauge.segmentHeight
                    color: !gauge.muted && (index + 0.5) / gauge.segments <= gauge.value ? gauge.filled : Ui.segmentOff
                }
            }
        }
    }

    Text {
        visible: gauge.showLabel && gauge.label.length > 0
        anchors.verticalCenter: parent.verticalCenter
        text: gauge.label
        color: Ui.detail
        font.pixelSize: Ui.detailSize
        font.family: Ui.font
    }
}
