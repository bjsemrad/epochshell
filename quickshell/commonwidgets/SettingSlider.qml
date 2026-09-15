import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.theme as T

// A labelled slider for one numeric setting, with the value shown beside the label.
//
// `value` is deliberately not bound to the setting it drives. A Slider writes to its own `value`
// as it is dragged, which would break any binding on the first pixel of movement and leave the
// control detached from the thing it claims to show -- the same trap RoundedSwitch fell into.
// Instead the setting is read in on load and whenever it changes elsewhere, and written out on
// movement.
Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: contents.implicitHeight

    required property string label
    // Optional line under the label, for saying which way the number runs.
    property string hint: ""
    required property real settingValue
    property real from: 0.3
    property real to: 1.0
    // Fine enough that any value a theme or config file sets is representable. A coarser step
    // with snapping would quietly round someone else's setting to the nearest notch and then
    // write the rounded value back as though it had been chosen.
    property real stepSize: 0.01

    // Live as the handle moves, so the change is visible while choosing it.
    signal moved(real value)
    // Once, when the handle is let go: the moment worth writing to disk.
    signal committed(real value)

    onSettingValueChanged: if (!slider.pressed) slider.value = settingValue

    ColumnLayout {
        id: contents
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            spacing: T.Config.layoutMarginSmall

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: root.label
                    color: T.Config.surfaceText
                    font.pixelSize: T.Config.fontSizeNormal
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    visible: root.hint.length > 0
                    text: root.hint
                    color: T.Config.outline
                    font.pixelSize: T.Config.fontSizeSubtext
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            Text {
                text: Math.round(slider.value * 100) + "%"
                color: T.Config.outline
                font.pixelSize: T.Config.fontSizeSubtext
                Layout.alignment: Qt.AlignVCenter
            }
        }

        Slider {
            id: slider
            Layout.fillWidth: true
            implicitHeight: 18
            from: root.from
            to: root.to
            stepSize: root.stepSize
            value: root.settingValue

            // A commit means "a person let go of this handle", and nothing else. Tracking the
            // press explicitly rather than trusting a bare !pressed matters: the handler also runs
            // as the control is set up, and without the flag that start-up call wrote a value
            // nobody had chosen into the settings file.
            property bool dragging: false

            onMoved: {
                slider.dragging = true;
                root.moved(value);
            }

            onPressedChanged: {
                if (pressed) return;
                if (!slider.dragging) return;
                slider.dragging = false;
                if (Math.abs(value - root.settingValue) < 0.0001) return;
                root.committed(value);
            }

            background: Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 6
                radius: height / 2
                color: T.Config.surfaceVariant

                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    radius: height / 2
                    color: T.Config.accent
                }
            }

            handle: Rectangle {
                x: slider.visualPosition * (slider.width - width)
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                height: 14
                radius: 7
                color: slider.pressed ? T.Config.accent : T.Config.surfaceContainerHighest
                border.width: 1
                border.color: T.Config.accent
            }
        }
    }
}
