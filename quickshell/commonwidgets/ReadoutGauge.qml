import QtQuick
import qs.theme as T

// A segmented bar, both display and control: click a segment to set it, drag along it, scroll to
// step by 5%. Muted or disabled, every segment draws
// empty and the label says so.
Row {
    id: gauge

    // 0 to 1.
    property real value: 0
    property int segments: 10
    property bool interactive: true
    property bool muted: false
    // After the bar: "50%" by default, "" for none.
    property string label: muted ? "muted" : Math.round(value * 100) + "%"
    property bool showLabel: true
    signal moved(real value)
    // Once the hand is lifted (and on every scroll step): for a setting that is written to disk,
    // so a drag is one write rather than one per segment.
    signal committed(real value)

    spacing: 8

    function set(v) {
        gauge.moved(Math.max(0, Math.min(1, v)));
    }

    Item {
        id: bar
        width: gauge.segments * (Readout.segmentWidth + Readout.segmentGap) - Readout.segmentGap
        height: Readout.rowHeight

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Readout.segmentGap

            Repeater {
                model: gauge.segments
                delegate: Rectangle {
                    required property int index
                    width: Readout.segmentWidth
                    height: Readout.segmentHeight
                    color: !gauge.muted && (index + 0.5) / gauge.segments <= gauge.value ? Readout.segmentOn : Readout.segmentOff
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: gauge.interactive
            cursorShape: Qt.PointingHandCursor
            function at(x) {
                return Math.ceil(Math.max(0, Math.min(bar.width, x)) / bar.width * gauge.segments) / gauge.segments;
            }
            onPressed: event => gauge.set(at(event.x))
            onPositionChanged: event => { if (pressed) gauge.set(at(event.x)); }
            onReleased: gauge.committed(gauge.value)
            onWheel: event => {
                gauge.set(gauge.value + (event.angleDelta.y > 0 ? 0.05 : event.angleDelta.y < 0 ? -0.05 : 0));
                gauge.committed(gauge.value);
            }
        }
    }

    Text {
        visible: gauge.showLabel && gauge.label.length > 0
        anchors.verticalCenter: parent.verticalCenter
        text: gauge.label
        color: Readout.detail
        font.pixelSize: Readout.detailSize
        font.family: Readout.font
    }
}
