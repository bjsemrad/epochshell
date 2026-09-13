import QtQuick
import QtQuick.Controls
import qs.theme as T

// A switch that reports what was asked of it and shows what is actually so.
//
// `checked` stays a live binding to whoever owns the state -- a service, usually, which owns it
// because the backend does. A click never writes to it: writing would break that binding, and a
// switch detached from the state it claims to show drifts away from every other view of the same
// thing, silently, from the first click onwards. Instead the click emits `toggled(requested)` and
// the owner acts; the switch moves when the state does.
//
// Waiting for a round trip would read as a dead control, so a click does move the knob at once --
// `pending` overrides the display until the answer arrives. The answer is either the state
// changing to match, or nothing at all, which is what a refusal looks like from here: a radio that
// would not come up, a toggle the backend declined. So the override also expires, and a switch
// that was refused falls back to the truth rather than sitting there claiming otherwise.
Item {
    id: root
    width: T.Config.switchHeight
    height: T.Config.switchWidth
    property bool checked: false
    // Emitted with the value the click asked for, rather than leaving the reader to work it out
    // from a `checked` that deliberately has not moved yet.
    signal toggled(bool requested)

    property bool pending: false
    property bool pendingValue: false
    readonly property bool displayChecked: root.pending ? root.pendingValue : root.checked

    // The state caught up -- or moved on its own, from a keybinding or another view of it -- and
    // the guess is worth nothing either way.
    onCheckedChanged: root.pending = false

    Timer {
        id: pendingTimeout
        interval: 1500
        onTriggered: root.pending = false
    }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        border.width: 1
        border.color: root.displayChecked ? T.Config.accent : T.Config.surfaceVariant

        color: root.displayChecked ? T.Config.accent : T.Config.surfaceContainer
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
        x: root.displayChecked ? (root.width - width - 2) : 2
        color: root.displayChecked ? T.Config.surface : T.Config.surfaceContainerHighest

        Text {
            text: ""
            anchors.centerIn: parent
            color: root.displayChecked ? T.Config.accent : T.Config.surfaceContainerHighest
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
            const requested = !root.displayChecked;
            root.pendingValue = requested;
            root.pending = true;
            pendingTimeout.restart();
            root.toggled(requested);
        }
    }
}
