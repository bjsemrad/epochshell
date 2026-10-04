pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

// The lock screen's state: whether the session is locked, and the password and fingerprint checks
// that end it.
//
// The lock itself is the compositor's (ext-session-lock, through WlSessionLock in
// modules/lock/LockScreen.qml): once locked, nothing but this shell saying "unlock" ends it, and
// if the shell dies while locked the compositor keeps the screen locked rather than revealing it.
// That is the whole security model, so two rules follow:
//
//   * Only a PAM success or a fingerprint match unlocks. There is deliberately no unlock over IPC:
//     the compositor's guarantee is that a crashed or killed locker leaves the session locked, and
//     an IPC call that unlocks would hand that away to anything that can run `qs ipc`.
//   * A lock survives the shell restarting. The marker file below is written before locking and
//     removed only after a real unlock, so a shell that crashed or was reloaded while locked locks
//     again as soon as it starts -- the compositor hands the new instance the lock.
Singleton {
    id: root

    // Whether the lock is wanted. WlSessionLock follows this.
    property bool locked: false
    // Set by LockScreen.qml from WlSessionLock.secure: the compositor has confirmed every output
    // is covered. Until then a lock has been asked for but cannot be relied on.
    property bool secure: false
    // The fade-out between a successful check and the lock actually ending.
    property bool unlocking: false

    // What has been typed. Shared, so every screen shows the same dots and typing can carry on
    // from whichever screen has focus. Cleared the moment it has been handed to PAM.
    property string buffer: ""
    property bool checking: false
    // One line under the field: why the last attempt failed, or what PAM wants to say.
    property string message: ""
    property bool messageIsError: false
    // Bumped on every failure, so each screen can shake its field without a shared animation.
    property int failures: 0

    readonly property bool fingerprintAvailable: fingerprintProbe.enrolled
    property bool fingerprintActive: false

    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    readonly property string markerPath: runtimeDir + "/epochshell-locked"

    // How long the fade-out runs before the lock is released. Long enough to read as deliberate,
    // short enough that the desktop is back by the time a hand reaches the mouse.
    readonly property int unlockFadeMs: 280

    signal lockRequested

    function lock() {
        if (root.locked) return;
        // Marker first: if anything goes wrong between here and the compositor confirming, a
        // restarted shell still knows the session was meant to be locked.
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

    // Hand what was typed to PAM. An empty submit is ignored rather than counted as a failure:
    // Enter is often pressed just to wake the screen.
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

    // The only way out. Called from a PAM success or a fingerprint match, nowhere else.
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

    // The compositor ended or refused the lock on its own. Not an unlock this shell performed, so
    // no fade; just get the state back in line with the screen.
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

    // A marker left by a previous instance means this one was started into a locked session --
    // a crash or a reload while locked. Lock again straight away.
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

    // --- Fingerprint ------------------------------------------------------------------------
    //
    // Through fprintd-verify rather than a second PAM stack: pam_fprintd lives outside the libpam
    // quickshell links against, so a shipped config could not name it portably, and the CLI is
    // what every fprintd install has. It runs alongside the password field the whole time the
    // screen is locked, and a match unlocks just as a password does.

    // While the machine sleeps fprintd suspends the reader, and a verify running across that
    // fails ("Cannot run while suspended") and can leave the reader unusable for a while after
    // waking -- measured: a lock taken just before sleep then would not take a finger at all.
    // Idle.qml, which watches logind, pauses the reader for the sleep and resumes it after.
    property bool fingerprintPaused: false

    // Verifies in a row that ended without a finger being read. A reader that fails at once is
    // retried less and less often rather than every moment, which is what made the icon flash.
    property int fingerprintFailures: 0

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

    // fprintd brings the reader back a moment after the system resumes; asking before then is the
    // same failure again, so wait a little.
    function resumeFingerprint() {
        root.fingerprintPaused = false;
        root.fingerprintFailures = 0;
        retryFingerprint.interval = 1500;
        if (root.locked && !root.unlocking) retryFingerprint.restart();
    }

    // Whether this user has a finger enrolled. Asked once at startup; enrolling a finger later
    // needs a shell restart to be noticed, which is rare enough not to poll for.
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
        // Dies with the shell (see Idle.qml's orphanSafe): an orphaned verify would keep the
        // reader claimed, and the restarted shell's own verify would then fail to get it.
        command: ["setpriv", "--pdeathsig", "TERM", "--", "fprintd-verify"]

        onRunningChanged: root.fingerprintActive = fingerprint.running

        stdout: SplitParser {
            onRead: function (line) {
                // "Verify result: verify-match (done)" is the one line that means yes.
                if (line.indexOf("Verify result:") >= 0) fingerprint.result = line.trim();
                if (line.indexOf("verify-match") >= 0) {
                    fingerprint.matched = true;
                } else if (line.indexOf("verify-no-match") >= 0) {
                    root.fail("Fingerprint not recognised");
                }
            }
        }

        // Kept for the journal: the reader's own complaint is the only clue when it stops working.
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

            // A verify that ran a while ended in a real attempt or a timeout: go again straight
            // away. One that ended almost at once means the reader is not there for us -- claimed
            // elsewhere, still asleep -- so back off: 1.5s, 3s, 6s, then every 10s.
            const quick = Date.now() - fingerprint.startedAt < 3000;
            if (quick) {
                root.fingerprintFailures += 1;
                console.log("lock: fingerprint reader failed at once (exit " + code + (result ? ", " + result : "")
                    + "), attempt " + root.fingerprintFailures);
            } else {
                root.fingerprintFailures = 0;
            }
            retryFingerprint.interval = quick ? Math.min(10000, 1500 * Math.pow(2, root.fingerprintFailures - 1)) : 200;
            retryFingerprint.restart();
        }
    }

    // In case the wake-up is never heard (logind's signal missed, the monitor restarting): resume
    // anyway. Timers do not advance while the machine sleeps, so this lands about 20s after waking
    // at the latest, rather than 20s into the sleep.
    Timer {
        running: root.fingerprintPaused
        interval: 20000
        onTriggered: root.resumeFingerprint()
    }

    Timer {
        id: retryFingerprint
        interval: 1500
        onTriggered: root.startFingerprint()
    }
}
