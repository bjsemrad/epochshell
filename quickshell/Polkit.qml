import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Polkit
import Quickshell.Wayland
import qs.commonwidgets
import qs.services as S
import qs.theme as T

Item {
    id: root

    property bool closing: false
    property bool submitted: false
    property string currentMessage: ""
    property string currentSupplementary: ""
    property bool responseRequired: false
    property bool responseVisible: false
    property bool errorFlash: false
    property bool fingerprintConfigured: false
    property bool laptopClosed: false
    property int shakeOffset: 0

    readonly property bool dialogVisible: polkitAgent.isActive || closing
    property int failedAttempts: 0
    property bool passwordChosen: false
    readonly property bool fingerprintMode: fingerprintConfigured && !laptopClosed && !passwordChosen && dialogVisible && !responseRequired && !submitted && !errorFlash

    readonly property string focusedScreenName: {
        const focused = S.CompositorService.monitors.find(m => m.focused === true);
        if (focused) return String(focused.name);
        return Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "";
    }

    function authorizationLabel(message) {
        var text = String(message || "")
        var match = text.match(/^Authentication is (?:needed|required) to run ['`]([^'`]+)['`] as /i)
        return match ? "Authorize running '" + match[1] + "'" : text
    }

    function fingerprintConfiguredFromPamConfig(raw) {
        // pam_fprintd may sit anywhere in the stack; a clamshell pam_exec gate may skip it while
        // the lid is shut.
        var lines = String(raw || "").split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].replace(/^\s+|\s+$/g, "")
            if (!line || line.charAt(0) === "#") continue
            if (!line.match(/^auth\s+/)) continue
            if (line.indexOf("pam_fprintd.so") !== -1) return true
        }
        return false
    }

    function loadPamConfig(raw) {
        fingerprintConfigured = fingerprintConfiguredFromPamConfig(raw)
    }

    function refreshLidState() {
        if (!laptopClosedProc.running) laptopClosedProc.running = true
    }

    function resetSnapshot() {
        currentMessage = ""
        currentSupplementary = ""
        responseRequired = false
        responseVisible = false
        errorFlash = false
        submitted = false
        passwordInput.text = ""
    }

    function syncFromFlow() {
        var flow = polkitAgent.flow
        if (!flow) return

        currentMessage = String(flow.message || "Authentication is needed...")
        currentSupplementary = String(flow.supplementaryMessage || "")
        responseRequired = !!flow.isResponseRequired
        responseVisible = !!flow.responseVisible

        if (responseRequired) submitted = false
    }

    function beginFlow() {
        closeTimer.stop()
        closing = false
        submitted = false
        failedAttempts = 0
        passwordChosen = false
        passwordInput.text = ""
        refreshLidState()
        syncFromFlow()
        Qt.callLater(refocus)
    }

    function refocus() {
        if (!dialogVisible) return
        if (fingerprintMode) dialog.forceActiveFocus()
        else passwordInput.forceActiveFocus()
    }

    function submitResponse() {
        var flow = polkitAgent.flow
        if (!flow || !flow.isResponseRequired) return
        submitted = true
        errorFlash = false
        flow.submit(passwordInput.text)
        passwordInput.text = ""
        dialog.forceActiveFocus()
    }

    function cancelRequest() {
        var flow = polkitAgent.flow
        passwordInput.text = ""
        submitted = false
        closing = true
        closeTimer.restart()
        if (flow) flow.cancelAuthenticationRequest()
    }

    function triggerFailureFeedback() {
        failedAttempts += 1
        submitted = false
        errorFlash = true
        passwordInput.text = ""
        errorTimer.restart()
        shakeAnimation.restart()
        Qt.callLater(refocus)
    }

    Timer {
        id: closeTimer
        interval: Ui.polkitCloseDelay
        repeat: false
        onTriggered: {
            root.closing = false
            resetSnapshot()
        }
    }

    Timer {
        id: errorTimer
        interval: Ui.polkitErrorMs
        repeat: false
        onTriggered: root.errorFlash = false
    }

    SequentialAnimation {
        id: shakeAnimation
        NumberAnimation { target: root; property: "shakeOffset"; to: Ui.shakeSmall[0]; duration: Ui.shakeSmallMs[0]; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; to: Ui.shakeSmall[1]; duration: Ui.shakeSmallMs[1]; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; to: Ui.shakeSmall[2]; duration: Ui.shakeSmallMs[2]; easing.type: Easing.OutQuad }
    }

    FileView {
        path: "/etc/pam.d/polkit-1"
        watchChanges: true
        printErrors: false
        onLoaded: root.loadPamConfig(text())
        onLoadFailed: root.fingerprintConfigured = false
        onFileChanged: reload()
    }

    Process {
        id: laptopClosedProc
        command: ["bash", "-c", "s=$(grep -r -m1 closed /proc/acpi/button/lid/ 2>/dev/null | grep -o closed | head -1); echo ${s:-open}"]
        stdout: StdioCollector { id: laptopClosedOut; waitForEnd: true }
        onExited: root.laptopClosed = String(laptopClosedOut.text || "").trim() === "closed"
    }

    PolkitAgent {
        id: polkitAgent
        path: "/org/epochshell/PolkitAgent"

        onAuthenticationRequestStarted: root.beginFlow()
        onIsActiveChanged: {
            if (isActive) root.syncFromFlow()
            else if (!root.closing) root.resetSnapshot()
        }
        onIsRegisteredChanged: {
            if (isRegistered) console.log("epochshell polkit agent registered")
            else console.warn("epochshell polkit agent is not registered; another agent may be running")
        }
    }

    Connections {
        target: polkitAgent.flow

        function onIsResponseRequiredChanged() {
            root.syncFromFlow()
            if (!polkitAgent.flow || !polkitAgent.flow.isResponseRequired) passwordInput.text = ""
            Qt.callLater(root.refocus)
        }

        function onInputPromptChanged() { root.syncFromFlow() }
        function onResponseVisibleChanged() { root.syncFromFlow() }
        function onSupplementaryMessageChanged() { root.syncFromFlow() }
        function onFailedChanged() { root.syncFromFlow() }

        function onAuthenticationFailed() {
            root.syncFromFlow()
            root.triggerFailureFeedback()
        }

        function onAuthenticationSucceeded() {
            root.closing = true
            closeTimer.restart()
        }

        function onAuthenticationRequestCancelled() {
            root.closing = true
            closeTimer.restart()
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.dialogVisible && modelData.name !== root.focusedScreenName
            anchors { top: true; bottom: true; left: true; right: true; }
            color: Qt.rgba(0, 0, 0, Ui.scrimAlpha)
            // No exclusiveZone: setting one reverts exclusionMode to Normal, undoing Ignore.
            WlrLayershell.namespace: "epochshell-polkit-dim"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }
        }
    }

    PanelWindow {
        id: panel
        visible: root.dialogVisible
        anchors { top: true; bottom: true; left: true; right: true; }
        color: Qt.rgba(0, 0, 0, Ui.scrimAlpha)
        // No exclusiveZone: setting one reverts exclusionMode to Normal, undoing Ignore.
        focusable: true
        screen: Quickshell.screens.find(s => s.name === root.focusedScreenName) || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

        WlrLayershell.namespace: "epochshell-polkit"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        exclusionMode: ExclusionMode.Ignore
        BackgroundEffect.blurRegion: T.Config.popupBlur ? dialogBlur : null
        Region {
            id: dialogBlur
            item: dialog
            radius: T.Config.popupRadius
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: Qt.callLater(root.refocus)
        }

        Rectangle {
            id: dialog
            readonly property real maxWidth: Math.max(Ui.dialogMinWidth, panel.width - Ui.dialogScreenMargin)
            width: Math.min(Math.max(Ui.dialogWidth, messageMeasure.implicitWidth + Ui.dialogTextPad), dialog.maxWidth)
            height: Math.min(contentCol.implicitHeight + Ui.dialogPadV, Math.max(panel.height - Ui.screenMarginV, 0))
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.shakeOffset
            radius: T.Config.popupRadius
            antialiasing: true
            color: T.Config.popupBackground
            border.width: 1
            border.color: root.errorFlash ? T.Config.red : T.Config.outline
            clip: true
            focus: true

            readonly property color failureText: {
                const red = T.Config.red;
                for (let t = 0; t <= 1; t += Ui.contrastStep) {
                    const c = Qt.rgba(red.r + (1 - red.r) * t, red.g + (1 - red.g) * t, red.b + (1 - red.b) * t, 1);
                    if (Ui.contrast(c, T.Config.background) >= Ui.contrastText) return c;
                }
                return Qt.rgba(1, 1, 1, 1);
            }

            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                    root.cancelRequest()
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (root.responseRequired) root.submitResponse()
                    event.accepted = true
                } else if (event.key === Qt.Key_P && root.fingerprintMode) {
                    root.passwordChosen = true
                    Qt.callLater(root.refocus)
                    event.accepted = true
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            Text {
                id: messageMeasure
                visible: false
                text: root.authorizationLabel(root.currentMessage)
                font.family: Ui.font
                font.pixelSize: Ui.valueSize
            }

            Flickable {
                id: scroller
                anchors.fill: parent
                anchors.margins: Ui.space4XL
                clip: true
                contentWidth: width
                contentHeight: contentCol.implicitHeight
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: contentCol
                    width: scroller.width
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: Ui.spaceXL
                        spacing: Ui.spaceXL
                        Text {
                            text: "󰒃"
                            color: T.Config.yellow
                            font.pixelSize: Ui.iconSize
                            font.family: Ui.font
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "authentication required"
                            color: T.Config.yellow
                            font.pixelSize: Ui.valueSize
                            font.family: Ui.font
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.bottomMargin: Ui.space2XL
                        implicitHeight: 1
                        color: Ui.divider
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.bottomMargin: Ui.spaceL
                        textFormat: Text.StyledText
                        text: {
                            const esc = t => String(t).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
                            return esc(root.authorizationLabel(root.currentMessage))
                                .replace(/(\/[^\s'`]+)/g, "<font color=\"#ffffff\">$1</font>");
                        }
                        color: Ui.value
                        font.pixelSize: Ui.valueSize
                        font.family: Ui.font
                        wrapMode: Text.WrapAnywhere
                    }

                    KeyRow {
                        readonly property string actionId: polkitAgent.flow ? String(polkitAgent.flow.actionId || "") : ""
                        visible: actionId.length > 0
                        key: "action"
                        text: actionId
                        textColor: Ui.detail
                    }

                    KeyRow {
                        id: asRow
                        readonly property var identities: polkitAgent.flow ? (polkitAgent.flow.identities || []) : []
                        function nameOf(identity) {
                            if (!identity) return "";
                            const name = String(identity.displayName || identity.name || identity.id || "");
                            return (identity.isGroup ? "group " : "") + name;
                        }
                        visible: identities.length > 0
                        key: "as"
                        text: identities.length === 1 ? nameOf(identities[0]) : ""
                        Choice {
                            visible: asRow.identities.length > 1
                            options: asRow.identities.map((identity, i) => ({ value: String(i), label: asRow.nameOf(identity) }))
                            current: String(asRow.identities.indexOf(polkitAgent.flow ? polkitAgent.flow.selectedIdentity : null))
                            onPicked: v => { if (polkitAgent.flow) polkitAgent.flow.selectedIdentity = asRow.identities[Number(v)]; }
                        }
                    }

                    ListRow {
                        id: detailsRow
                        property bool open: false
                        value: "details"
                        valueWidth: Ui.keyColumn - Ui.spaceXL
                        hasPage: !open
                        detail: open ? "" : ""
                        onOpened: open = true
                        onClicked: open = !open
                    }
                    Note {
                        visible: detailsRow.open
                        text: [polkitAgent.flow && polkitAgent.flow.iconName ? "icon " + polkitAgent.flow.iconName : "",
                            root.currentMessage].filter(x => x.length > 0).join("\n")
                    }

                    RowLayout {
                        visible: T.Config.polkitPhrase.length > 0
                        Layout.fillWidth: true
                        Layout.topMargin: Ui.spaceM
                        spacing: Ui.spaceXL
                        Text {
                            text: "󰌆"
                            color: Ui.detail
                            font.pixelSize: Ui.detailSize
                            font.family: Ui.font
                        }
                        Text {
                            Layout.fillWidth: true
                            text: T.Config.polkitPhrase
                            color: Ui.value
                            font.pixelSize: Ui.detailSize
                            font.family: Ui.font
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: Ui.space3XL
                        implicitHeight: Ui.polkitPromptHeight
                        color: Ui.hover

                        Rectangle {
                            width: Ui.tick
                            height: parent.height
                            color: root.errorFlash ? T.Config.red : T.Config.accent
                        }

                        RowLayout {
                            visible: !root.fingerprintMode
                            anchors.fill: parent
                            anchors.leftMargin: Ui.space3XL
                            anchors.rightMargin: Ui.space3XL
                            spacing: Ui.spaceXL
                            Text {
                                text: "›"
                                color: root.errorFlash ? T.Config.red : T.Config.accent
                                font.pixelSize: Ui.valueSize + 2
                                font.family: Ui.font
                            }
                            TextInput {
                                id: passwordInput
                                Layout.fillWidth: true
                                color: Ui.value
                                font.family: Ui.font
                                font.pixelSize: Ui.valueSize + 2
                                clip: true
                                selectionColor: T.Config.accent
                                selectedTextColor: T.Config.background
                                cursorVisible: activeFocus && !root.submitted && !root.errorFlash
                                readOnly: root.submitted || root.errorFlash
                                echoMode: root.responseVisible ? TextInput.Normal : TextInput.Password
                                passwordCharacter: "\u2022"
                                activeFocusOnPress: true
                                onAccepted: root.submitResponse()
                                Keys.onPressed: function(event) {
                                    if (event.key === Qt.Key_Escape) {
                                        root.cancelRequest()
                                        event.accepted = true
                                    }
                                }
                                Text {
                                    anchors.fill: parent
                                    visible: parent.text.length === 0
                                    text: {
                                        if (root.submitted) return "checking…";
                                        const prompt = polkitAgent.flow ? String(polkitAgent.flow.inputPrompt || "") : "";
                                        const cleaned = prompt.replace(/:\s*$/, "").trim().toLowerCase();
                                        return cleaned.length > 0 ? cleaned : "password";
                                    }
                                    color: Ui.detail
                                    font.family: Ui.font
                                    font.pixelSize: Ui.valueSize + 2
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }

                        RowLayout {
                            visible: root.fingerprintMode
                            anchors.fill: parent
                            anchors.leftMargin: Ui.space3XL
                            anchors.rightMargin: Ui.space3XL
                            spacing: Ui.space2XL
                            Text {
                                text: "󰈷"
                                color: T.Config.accent
                                font.pixelSize: Ui.fingerprintSize
                                font.family: Ui.font
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    text: "touch the reader"
                                    color: Ui.value
                                    font.pixelSize: Ui.valueSize
                                    font.family: Ui.font
                                }
                                Text {
                                    text: "p · use password"
                                    color: Ui.detail
                                    font.pixelSize: Ui.detailSize
                                    font.family: Ui.font
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.failedAttempts > 0
                        Layout.fillWidth: true
                        Layout.topMargin: Ui.spaceM
                        text: {
                            const what = root.currentSupplementary.length > 0 ? root.currentSupplementary.toLowerCase() : "wrong password";
                            const max = T.Config.polkitMaxAttempts;
                            const left = max - root.failedAttempts;
                            const count = max > 0 ? (left === 1 ? "1 attempt left" : Math.max(0, left) + " attempts left") : "attempt " + (root.failedAttempts + 1);
                            return what + " · " + count;
                        }
                        color: dialog.failureText
                        font.pixelSize: Ui.detailSize
                        font.family: Ui.font
                        wrapMode: Text.Wrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Ui.space3XL
                        spacing: 0
                        Text {
                            text: "esc · cancel"
                            color: cancelMouse.containsMouse ? Ui.value : Ui.detail
                            font.pixelSize: Ui.detailSize
                            font.family: Ui.font
                            MouseArea {
                                id: cancelMouse
                                anchors.fill: parent
                                anchors.margins: -Ui.hitSlop
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.cancelRequest()
                            }
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            visible: !root.fingerprintMode
                            implicitWidth: authText.implicitWidth + Ui.buttonPadX
                            implicitHeight: authText.implicitHeight + Ui.buttonPadY
                            radius: Ui.hoverRadius
                            color: authMouse.containsMouse ? Ui.alpha(T.Config.surfaceText, Ui.buttonHoverAlpha) : Ui.hover
                            Text {
                                id: authText
                                anchors.centerIn: parent
                                text: "↵ authenticate"
                                color: Ui.value
                                font.pixelSize: Ui.detailSize
                                font.family: Ui.font
                            }
                            MouseArea {
                                id: authMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.submitResponse()
                            }
                        }
                    }
                }
            }
        }
    }

    function scopeLabel() {
        var text = String(root.currentMessage || "")
        var match = text.match(/^Authentication is (?:needed|required) to run ['`]([^'`]+)['`] as /i)
        return match ? "Authorize '" + match[1] + "'" : "Authentication"
    }
}
