import QtQuick
import qs.theme as T

Item {
    id: slider

    property real value: 0
    property real step: Ui.sliderStep
    property bool muted: false
    property bool interactive: true
    property string label: muted ? "muted" : Math.round(value * 100) + "%"
    property bool showLabel: true
    property real trackWidth: Ui.sliderTrack
    signal moved(real value)
    signal committed(real value)

    readonly property bool hovered: hit.containsMouse
    readonly property color grey: Ui.alpha(T.Config.surfaceText, Ui.sliderMutedAlpha)

    implicitWidth: trackWidth + (showLabel ? Ui.spaceXL + labelText.implicitWidth : 0)
    implicitHeight: Ui.rowHeight
    activeFocusOnTab: interactive

    function set(v) {
        slider.moved(Math.max(0, Math.min(1, v)));
    }
    function nudge(by) {
        slider.set(slider.value + by);
        slider.committed(Math.max(0, Math.min(1, slider.value + by)));
    }

    Keys.onLeftPressed: event => slider.nudge(-((event.modifiers & Qt.ShiftModifier) ? Ui.sliderFineStep : slider.step))
    Keys.onRightPressed: event => slider.nudge((event.modifiers & Qt.ShiftModifier) ? Ui.sliderFineStep : slider.step)
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Home) { slider.set(0); slider.committed(0); event.accepted = true; }
        else if (event.key === Qt.Key_End) { slider.set(1); slider.committed(1); event.accepted = true; }
    }

    Item {
        id: track
        width: slider.trackWidth
        height: parent.height

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 2
            color: Ui.alpha(T.Config.surfaceText, slider.hovered ? Ui.sliderTrackHoverAlpha : Ui.sliderTrackAlpha)
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * Math.max(0, Math.min(1, slider.value))
            height: 2
            color: slider.muted ? slider.grey : Ui.alpha(T.Config.surfaceText, Ui.sliderFillAlpha)
        }
        Rectangle {
            readonly property real w: slider.hovered ? Ui.sliderHandleHover : Ui.sliderHandle
            x: Math.round(Math.max(0, Math.min(1, slider.value)) * (parent.width - w))
            anchors.verticalCenter: parent.verticalCenter
            width: w
            height: Ui.sliderHandleHeight
            color: slider.muted ? slider.grey : T.Config.accent
        }

        MouseArea {
            id: hit
            anchors.fill: parent
            enabled: slider.interactive
            hoverEnabled: true
            cursorShape: Qt.SizeHorCursor
            function at(x) {
                return Math.max(0, Math.min(1, x / track.width));
            }
            onPressed: event => {
                slider.forceActiveFocus();
                slider.set(at(event.x));
            }
            onPositionChanged: event => { if (pressed) slider.set(at(event.x)); }
            onReleased: slider.committed(slider.value)
            onWheel: event => {
                const by = event.angleDelta.y > 0 ? slider.step : event.angleDelta.y < 0 ? -slider.step : 0;
                if (by !== 0) slider.nudge(by);
            }
        }
    }

    Text {
        id: labelText
        visible: slider.showLabel && slider.label.length > 0
        x: track.width + Ui.spaceXL
        anchors.verticalCenter: parent.verticalCenter
        text: slider.label
        color: slider.muted ? Ui.detail : Ui.value
        font.pixelSize: Ui.detailSize
        font.family: Ui.font
    }
}
