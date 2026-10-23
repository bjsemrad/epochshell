pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

Singleton {
    id: root
    readonly property int fingerprintRetryMs: 1500
    readonly property int fingerprintQuickMs: 3000
    readonly property int fingerprintAgainMs: 200
    readonly property int fingerprintBackoffSteps: 3
    readonly property int fingerprintMaxBackoffMs: 35000
    readonly property int resumeFallbackMs: 20000

    property bool locked: false
    property bool secure: false
    property bool unlocking: false

    property string buffer: ""
    property bool checking: false
    property string message: ""
    property bool messageIsError: false
    property int failures: 0

    readonly property bool fingerprintAvailable: fingerprintProbe.enrolled
    property bool fingerprintActive: false

    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    readonly property string markerPath: runtimeDir + "/epochshell-locked"

    readonly property int unlockFadeMs: 280

    signal lockRequested

    function lock() {
        if (root.locked) return;
        // Marker first, so a restarted shell knows the session was meant to be locked.
        markerWriter.command = ["touch", root.markerPath];
        markerWriter.running = true;
        root.buffer = "";
        root.message = "";
        root.messageIsError = false;
        root.checking = false;
        root.unlocking = false;
        root.locked = true;
        root.lockRequested();
        root.startFingerprint();
    }

    // An empty submit is ignored: Enter is often pressed just to wake the screen.
    function submit() {
        if (!root.locked || root.unlocking || root.checking) return;
        if (root.buffer.length === 0) return;
        root.checking = true;
        root.message = "";
        root.messageIsError = false;
        pam.pending = root.buffer;
        root.buffer = "";
        if (!pam.start()) {
            pam.pending = "";
            root.checking = false;
            root.fail("Could not start the password check");
        }
    }

    function clearInput() {
        root.buffer = "";
    }

    function fail(text) {
        root.message = text;
        root.messageIsError = true;
        root.failures += 1;
    }

    function succeed(how) {
        if (!root.locked || root.unlocking) return;
        console.log("lock: unlocked by " + how);
        root.unlocking = true;
        root.checking = false;
        root.message = "";
        root.stopFingerprint();
        if (pam.active) pam.abort();
        releaseTimer.restart();
    }

    function compositorReleased() {
        console.log("lock: the compositor did not grant or did not keep the session lock");
        releaseTimer.stop();
        root.stopFingerprint();
        if (pam.active) pam.abort();
        root.locked = false;
        root.unlocking = false;
        root.checking = false;
        root.buffer = "";
        markerWriter.command = ["rm", "-f", root.markerPath];
        markerWriter.running = true;
    }

    Timer {
        id: releaseTimer
        interval: root.unlockFadeMs
        onTriggered: {
            root.locked = false;
            root.unlocking = false;
            root.buffer = "";
            markerWriter.command = ["rm", "-f", root.markerPath];
            markerWriter.running = true;
        }
    }

    Process {
        id: markerWriter
    }

    // A marker from a previous instance: we were started into a locked session (crash or reload).
    // Lock again.
    FileView {
        path: root.markerPath
        printErrors: false
        onLoaded: {
            console.log("lock: the session was locked when the shell last stopped; locking again");
            root.lock();
        }
    }

    PamContext {
        id: pam
        property string pending: ""

        configDirectory: Quickshell.shellDir + "/pam"
        config: "password.conf"

        onPamMessage: {
            if (pam.responseRequired) {
                pam.respond(pam.pending);
                pam.pending = "";
            } else if (pam.message.length > 0) {
                root.message = pam.message;
                root.messageIsError = pam.messageIsError;
            }
        }

        onCompleted: function (result) {
            pam.pending = "";
            root.checking = false;
            if (result === PamResult.Success) {
                root.succeed("password");
            } else if (result === PamResult.MaxTries) {
                root.fail("Too many attempts");
            } else {
                root.fail("Wrong password");
            }
        }

        onError: function (error) {
            pam.pending = "";
            root.checking = false;
            root.fail("Password check failed: " + PamError.toString(error));
        }
    }

    // fprintd-verify rather than a second PAM stack: pam_fprintd lives outside the libpam
    // quickshell links against.

    // A verify across sleep fails ("Cannot run while suspended") and can leave the reader unusable
    // after waking.
    property bool fingerprintPaused: false

    property int fingerprintFailures: 0

    // fprintd-verify has no signal handler, so it is killed, and fprintd only releases the reader
    // once it notices. Idle.qml waits on this before sleep.
    property real fingerprintStoppedAt: 0

    function startFingerprint() {
        if (!root.fingerprintAvailable || !root.locked || root.unlocking || root.fingerprintPaused) return;
        fingerprint.matched = false;
        fingerprint.startedAt = Date.now();
        fingerprint.running = true;
    }

    function stopFingerprint() {
        retryFingerprint.stop();
        fingerprint.running = false;
        root.fingerprintFailures = 0;
    }

    function pauseFingerprint() {
        root.fingerprintPaused = true;
        retryFingerprint.stop();
        fingerprint.running = false;
    }

    function resumeFingerprint() {
        root.fingerprintPaused = false;
        root.fingerprintFailures = 0;
        retryFingerprint.interval = root.fingerprintRetryMs;
        if (root.locked && !root.unlocking) retryFingerprint.restart();
    }

    Process {
        id: fingerprintProbe
        property bool enrolled: false
        command: ["sh", "-c", "command -v fprintd-verify >/dev/null && fprintd-list \"$USER\" 2>/dev/null | grep -q ' - #'"]
        running: true
        onExited: function (code) {
            fingerprintProbe.enrolled = code === 0;
            if (fingerprintProbe.enrolled && root.locked) root.startFingerprint();
        }
    }

    Process {
        id: fingerprint
        property bool matched: false
        property real startedAt: 0
        property string result: ""
        command: ["setpriv", "--pdeathsig", "TERM", "--", "fprintd-verify"]

        onRunningChanged: {
            root.fingerprintActive = fingerprint.running;
            if (!fingerprint.running) root.fingerprintStoppedAt = Date.now();
        }

        stdout: SplitParser {
            onRead: function (line) {
                // "Verify result: verify-match (done)" is the only line that means yes.
                if (line.indexOf("Verify result:") >= 0) fingerprint.result = line.trim();
                if (line.indexOf("verify-match") >= 0) {
                    fingerprint.matched = true;
                } else if (line.indexOf("verify-no-match") >= 0) {
                    root.fail("Fingerprint not recognised");
                }
            }
        }

        stderr: SplitParser {
            onRead: function (line) {
                console.log("lock: fprintd-verify: " + line);
            }
        }

        onExited: function (code) {
            const result = fingerprint.result;
            fingerprint.result = "";
            if (fingerprint.matched && code === 0) {
                root.succeed("fingerprint");
                return;
            }
            if (!root.locked || root.unlocking || root.fingerprintPaused) return;

            // A verify that ended almost at once means the reader is unavailable: back off 1.5s,
            // 3s, 6s, ...
            const quick = Date.now() - fingerprint.startedAt < root.fingerprintQuickMs;
            if (quick) {
                root.fingerprintFailures += 1;
                console.log("lock: fingerprint reader failed at once (exit " + code + (result ? ", " + result : "")
                    + "), attempt " + root.fingerprintFailures);
            } else {
                root.fingerprintFailures = 0;
            }
            retryFingerprint.interval = !quick ? root.fingerprintAgainMs
                : root.fingerprintFailures <= root.fingerprintBackoffSteps ? root.fingerprintRetryMs * Math.pow(2, root.fingerprintFailures - 1)
                : root.fingerprintMaxBackoffMs;
            retryFingerprint.restart();
        }
    }

    // Timers do not advance while asleep, so this lands about 20s after waking at the latest.
    Timer {
        running: root.fingerprintPaused
        interval: root.resumeFallbackMs
        onTriggered: root.resumeFingerprint()
    }

    Timer {
        id: retryFingerprint
        interval: root.fingerprintRetryMs
        onTriggered: root.startFingerprint()
    }
}
