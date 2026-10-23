import QtQuick
import qs.commonwidgets
import qs.theme as T
import qs.services as S

Item {
    id: root

    implicitWidth: Ui.lockFieldWidth
    implicitHeight: Ui.lockFieldHeight

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
        color: Qt.rgba(0, 0, 0, Ui.lockFieldAlpha)

        SequentialAnimation {
            id: shake
            loops: 1
            NumberAnimation { target: pill; property: "x"; to: Ui.shakeLarge[0]; duration: Ui.shakeLargeMs[0]; easing.type: Easing.OutQuad }
            NumberAnimation { target: pill; property: "x"; to: Ui.shakeLarge[1]; duration: Ui.shakeLargeMs[1]; easing.type: Easing.InOutQuad }
            NumberAnimation { target: pill; property: "x"; to: Ui.shakeLarge[2]; duration: Ui.shakeLargeMs[2]; easing.type: Easing.InOutQuad }
            NumberAnimation { target: pill; property: "x"; to: Ui.shakeLarge[3]; duration: Ui.shakeLargeMs[3]; easing.type: Easing.InOutQuad }
            NumberAnimation { target: pill; property: "x"; to: Ui.shakeLarge[4]; duration: Ui.shakeLargeMs[4]; easing.type: Easing.OutQuad }
        }

        Rectangle {
            width: Ui.tick
            height: parent.height
            color: root.failed ? T.Config.red : T.Config.accent
        }

        Text {
            id: promptGlyph
            x: Ui.space2XL
            anchors.verticalCenter: parent.verticalCenter
            text: "›"
            color: root.failed ? T.Config.red : T.Config.accent
            font.family: T.Config.fontFamily
            font.pixelSize: Ui.lockGlyphSize
        }

        Text {
            x: promptGlyph.x + promptGlyph.width + Ui.spaceXL
            anchors.verticalCenter: parent.verticalCenter
            visible: S.Lock.buffer.length === 0 && !S.Lock.checking
            text: S.Lock.fingerprintActive ? "password or touch the reader" : "password"
            color: Qt.rgba(1, 1, 1, Ui.lockHintAlpha)
            font.family: T.Config.fontFamily
            font.pixelSize: T.Config.fontSizeNormal
        }

        Row {
            x: promptGlyph.x + promptGlyph.width + Ui.spaceXL
            anchors.verticalCenter: parent.verticalCenter
            spacing: Ui.spaceM
            visible: !S.Lock.checking
            Repeater {
                model: Math.min(S.Lock.buffer.length, Ui.lockMaxDots)
                delegate: Rectangle {
                    width: Ui.dotSize
                    height: Ui.dotSize
                    radius: 2
                    color: "white"
                }
            }
        }

        Row {
            x: promptGlyph.x + promptGlyph.width + Ui.spaceXL
            anchors.verticalCenter: parent.verticalCenter
            spacing: Ui.spaceM
            visible: S.Lock.checking
            Repeater {
                model: Ui.busyDots
                delegate: Rectangle {
                    required property int index
                    width: Ui.dotSize
                    height: Ui.dotSize
                    radius: 2
                    color: "white"
                    SequentialAnimation on opacity {
                        running: S.Lock.checking
                        loops: Animation.Infinite
                        PauseAnimation { duration: index * Ui.busyStaggerMs }
                        NumberAnimation { from: Ui.busyLowAlpha; to: 1; duration: Ui.busyPulseMs }
                        NumberAnimation { from: 1; to: Ui.busyLowAlpha; duration: Ui.busyPulseMs }
                        PauseAnimation { duration: (Ui.busyDots - 1 - index) * Ui.busyStaggerMs }
                    }
                }
            }
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: Ui.space3XL
            anchors.verticalCenter: parent.verticalCenter
            visible: S.Lock.fingerprintActive
            text: "󰈷"
            color: Qt.rgba(1, 1, 1, Ui.lockGlyphAlpha)
            font.family: T.Config.fontFamily
            font.pixelSize: T.Config.fontSizeLarge
        }
    }

    readonly property real textIndent: promptGlyph.x + promptGlyph.width + Ui.spaceXL

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
