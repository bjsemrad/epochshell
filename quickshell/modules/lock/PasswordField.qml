import QtQuick
import qs.theme as T
import qs.services as S

Item {
    id: root

    implicitWidth: 320
    implicitHeight: 46

    // Qt does not report Caps Lock; inferred from a letter's case against Shift.
    property bool capsLock: false

    readonly property bool failed: S.Lock.messageIsError && !S.Lock.checking

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
        radius: 2
        color: Qt.rgba(0, 0, 0, 0.55)

        SequentialAnimation {
            id: shake
            loops: 1
            NumberAnimation { target: pill; property: "x"; to: -10; duration: 45; easing.type: Easing.OutQuad }
            NumberAnimation { target: pill; property: "x"; to: 10; duration: 70; easing.type: Easing.InOutQuad }
            NumberAnimation { target: pill; property: "x"; to: -6; duration: 60; easing.type: Easing.InOutQuad }
            NumberAnimation { target: pill; property: "x"; to: 4; duration: 50; easing.type: Easing.InOutQuad }
            NumberAnimation { target: pill; property: "x"; to: 0; duration: 40; easing.type: Easing.OutQuad }
        }

        Rectangle {
            width: 3
            height: parent.height
            color: root.failed ? T.Config.red : T.Config.accent
        }

        Text {
            id: promptGlyph
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "›"
            color: root.failed ? T.Config.red : T.Config.accent
            font.family: T.Config.fontFamily
            font.pixelSize: T.Config.fontSizeNormal + 6
        }

        Text {
            x: promptGlyph.x + promptGlyph.width + 10
            anchors.verticalCenter: parent.verticalCenter
            visible: S.Lock.buffer.length === 0 && !S.Lock.checking
            text: S.Lock.fingerprintActive ? "password or touch the reader" : "password"
            color: Qt.rgba(1, 1, 1, 0.55)
            font.family: T.Config.fontFamily
            font.pixelSize: T.Config.fontSizeNormal
        }

        Row {
            x: promptGlyph.x + promptGlyph.width + 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            visible: !S.Lock.checking
            Repeater {
                model: Math.min(S.Lock.buffer.length, 20)
                delegate: Rectangle {
                    width: 7
                    height: 7
                    radius: 2
                    color: "white"
                }
            }
        }

        Row {
            x: promptGlyph.x + promptGlyph.width + 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            visible: S.Lock.checking
            Repeater {
                model: 3
                delegate: Rectangle {
                    required property int index
                    width: 7
                    height: 7
                    radius: 2
                    color: "white"
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
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            visible: S.Lock.fingerprintActive
            text: "󰈷"
            color: Qt.rgba(1, 1, 1, 0.6)
            font.family: T.Config.fontFamily
            font.pixelSize: T.Config.fontSizeLarge
        }
    }

    readonly property real textIndent: promptGlyph.x + promptGlyph.width + 10

    // Invisible; Password echo so nothing inspecting the item (an accessibility tree) can read it
    // back.
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
