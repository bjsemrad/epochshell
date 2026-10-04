import QtQuick
import qs.theme as T
import qs.services as S

// The password pill. The text is kept in LockService rather than here, so a dot typed on one
// screen shows on all of them; the TextInput only collects keys.
Item {
    id: root

    implicitWidth: 320
    implicitHeight: 52

    // Inferred from what is typed. Qt does not report the Caps Lock state itself, but a letter that
    // comes out capitalised without Shift (or lower case with it) says the same thing.
    property bool capsLock: false

    readonly property bool failed: S.Lock.messageIsError && !S.Lock.checking

    // Shake on every failure. Bound to the counter rather than the message, so two wrong passwords
    // in a row shake twice.
    Connections {
        target: S.Lock
        function onFailuresChanged() {
            shake.restart();
        }
        function onBufferChanged() {
            if (input.text !== S.Lock.buffer) input.text = S.Lock.buffer;
        }
        function onLockRequested() {
            input.forceActiveFocus();
        }
    }

    Rectangle {
        id: pill
        width: parent.width
        height: parent.height
        radius: height / 2
        color: Qt.rgba(0, 0, 0, 0.35)
        border.width: 2
        border.color: {
            if (root.failed) return T.Config.red;
            if (S.Lock.checking) return T.Config.orange;
            if (input.activeFocus) return T.Config.accent;
            return Qt.rgba(1, 1, 1, 0.2);
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 150
            }
        }

        SequentialAnimation {
            id: shake
            loops: 1
            NumberAnimation { target: pill; property: "x"; to: -10; duration: 45; easing.type: Easing.OutQuad }
            NumberAnimation { target: pill; property: "x"; to: 10; duration: 70; easing.type: Easing.InOutQuad }
            NumberAnimation { target: pill; property: "x"; to: -6; duration: 60; easing.type: Easing.InOutQuad }
            NumberAnimation { target: pill; property: "x"; to: 4; duration: 50; easing.type: Easing.InOutQuad }
            NumberAnimation { target: pill; property: "x"; to: 0; duration: 40; easing.type: Easing.OutQuad }
        }

        Text {
            anchors.centerIn: parent
            visible: S.Lock.buffer.length === 0 && !S.Lock.checking
            text: S.Lock.fingerprintActive ? "Password or fingerprint" : "Password"
            color: Qt.rgba(1, 1, 1, 0.4)
            font.family: T.Config.fontFamily
            font.pixelSize: T.Config.fontSizeMedium
        }

        // The dots. Capped, so a very long password does not run out of the pill; past the cap
        // the count stops being exact, which it never needed to be.
        Row {
            anchors.centerIn: parent
            spacing: 8
            Repeater {
                model: Math.min(S.Lock.buffer.length, 20)
                delegate: Rectangle {
                    width: 10
                    height: 10
                    radius: 5
                    color: "white"
                    scale: 0
                    Component.onCompleted: scale = 1
                    Behavior on scale {
                        NumberAnimation {
                            duration: 90
                            easing.type: Easing.OutBack
                        }
                    }
                }
            }
        }

        // Spinner dots while PAM thinks, so a slow check does not look like a frozen screen.
        Row {
            anchors.centerIn: parent
            spacing: 8
            visible: S.Lock.checking
            Repeater {
                model: 3
                delegate: Rectangle {
                    required property int index
                    width: 8
                    height: 8
                    radius: 4
                    color: T.Config.orange
                    SequentialAnimation on opacity {
                        running: S.Lock.checking
                        loops: Animation.Infinite
                        PauseAnimation { duration: index * 150 }
                        NumberAnimation { from: 0.25; to: 1; duration: 300 }
                        NumberAnimation { from: 1; to: 0.25; duration: 300 }
                        PauseAnimation { duration: (2 - index) * 150 }
                    }
                }
            }
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            visible: S.Lock.fingerprintActive
            text: "󰈷"
            color: Qt.rgba(1, 1, 1, 0.55)
            font.family: T.Config.fontFamily
            font.pixelSize: T.Config.fontSizeXLarge
        }
    }

    // Invisible: it only gathers keys. Password echo mode anyway, so nothing that inspects the
    // item -- an accessibility tree, say -- can read the text back.
    TextInput {
        id: input
        anchors.fill: parent
        opacity: 0
        focus: true
        echoMode: TextInput.Password
        // No predictive or remembered text: an input method must never learn the password.
        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        selectByMouse: false
        enabled: !S.Lock.checking && !S.Lock.unlocking
        Component.onCompleted: forceActiveFocus()

        onTextChanged: {
            if (S.Lock.buffer !== input.text) S.Lock.buffer = input.text;
            // A new keystroke after a failure is a new attempt; let the error go.
            if (input.text.length > 0 && S.Lock.messageIsError) S.Lock.message = "";
        }

        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                S.Lock.submit();
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Escape) {
                S.Lock.clearInput();
                event.accepted = true;
                return;
            }
            const ch = event.text;
            if (ch.length === 1 && ch.toLowerCase() !== ch.toUpperCase()) {
                const shift = (event.modifiers & Qt.ShiftModifier) !== 0;
                const upper = ch === ch.toUpperCase();
                root.capsLock = upper !== shift;
            }
        }
    }

    function focusInput() {
        input.forceActiveFocus();
    }
}
