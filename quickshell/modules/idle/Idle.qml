import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services as S

// Idle handling: lock, screen off, and suspend after a while untouched, plus locking for
// `loginctl lock-session` and before the machine sleeps. What hypridle did, without a separate
// daemon -- the shell owns the lock screen, so it is the natural thing to decide when to show it.
//
// Settings come from ~/.config/epochshell-idle.json, written by the home-manager module's
// `programs.epochshell.idle` (the shell's own config directory is a read-only store path there).
// No file means none of this runs, so a machine still using hypridle is not idled twice.
//
//     { "lockAfter": 300, "screenOffAfter": 400, "suspendAfter": 600,
//       "lockBeforeSleep": true, "afterSleepCommand": "" }
//
// Times are seconds; 0 turns a stage off.
//
// Inhibitors are honoured two ways. Wayland idle inhibitors -- a playing video, the shell's own
// Stay Awake -- stop the idle timers outright (respectInhibitors). logind idle inhibitors, taken
// with `systemd-inhibit --what=idle` by anything else, are checked at the moment a stage would fire,
// and a stage that was held back fires once the inhibitor goes away if the session is still idle.
Scope {
    id: root

    readonly property string settingsPath: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/epochshell-idle.json"

    property bool configured: false
    property int lockAfter: 0
    property int screenOffAfter: 0
    property int suspendAfter: 0
    property bool lockBeforeSleep: false
    property string afterSleepCommand: ""

    // The logind session this shell belongs to, so a Lock signal for some other session (an ssh
    // login, another seat) is not taken as ours. Empty until asked; until then any Lock counts.
    property string sessionPath: ""

    function applySettings(text) {
        let data;
        try {
            data = JSON.parse(text);
        } catch (e) {
            console.log("idle: cannot parse " + root.settingsPath + ":", e);
            root.configured = false;
            return;
        }
        root.lockAfter = Math.max(0, Number(data.lockAfter) || 0);
        root.screenOffAfter = Math.max(0, Number(data.screenOffAfter) || 0);
        root.suspendAfter = Math.max(0, Number(data.suspendAfter) || 0);
        root.lockBeforeSleep = data.lockBeforeSleep === true;
        root.afterSleepCommand = String(data.afterSleepCommand || "");
        root.configured = true;
        console.log("idle: lock " + root.lockAfter + "s, screen off " + root.screenOffAfter + "s, suspend "
            + root.suspendAfter + "s, lock before sleep " + root.lockBeforeSleep);
    }

    FileView {
        path: root.settingsPath
        watchChanges: true
        printErrors: false
        onFileChanged: this.reload()
        onLoaded: root.applySettings(this.text())
        onLoadFailed: root.configured = false
    }

    // --- Actions -----------------------------------------------------------------------------

    // Screens off and on, per compositor. The backend comes from EpochOxide, which knows what is
    // actually running. Without it (the daemon not answering), each compositor is tried in turn and
    // the first that accepts the command wins -- not decided from environment variables, which
    // outlive their session: a terminal opened under Hyprland keeps HYPRLAND_INSTANCE_SIGNATURE
    // long after the session moved to niri, and trusting it sent the command to a dead Hyprland.
    // Hyprland's Lua dispatcher is tried before the classic one, since which a given Hyprland speaks
    // depends on its config.
    function screens(on) {
        // Logged: a screen left dark is otherwise impossible to trace back to who asked.
        console.log("idle: screens " + (on ? "on" : "off") + " (" + (root.compositor || "unknown") + ")");
        root.screensOff = !on;
        // One command at a time. A request made while one is still running replaces any earlier
        // one waiting and runs when it finishes, so the last word -- usually "on" -- always lands.
        if (screensProcess.running) {
            screensProcess.pending = on ? 1 : 0;
            return;
        }
        screensProcess.command = ["sh", "-c", `
            backend="$1"; on="$2"
            niri_() {
                if [ "$on" = 1 ]; then niri msg action power-on-monitors; else niri msg action power-off-monitors; fi
            }
            hypr_() {
                if [ "$on" = 1 ]; then lua=enable; classic=on; else lua=disable; classic=off; fi
                out=$(hyprctl dispatch "hl.dsp.dpms({ action = \"$lua\" })" 2>/dev/null)
                [ "$out" = ok ] || [ "$(hyprctl dispatch dpms "$classic" 2>/dev/null)" = ok ]
            }
            sway_() {
                if [ "$on" = 1 ]; then swaymsg 'output * power on'; else swaymsg 'output * power off'; fi
            }
            case "$backend" in
              niri) niri_ ;;
              hypr) hypr_ ;;
              sway) sway_ ;;
              *) niri_ 2>/dev/null || hypr_ || sway_ ;;
            esac`, "screens", root.compositor, on ? "1" : "0"];
        screensProcess.running = true;
    }

    // Read here so the compositor service starts with this module, and its answer is in hand before
    // the first stage fires rather than being asked for at that moment.
    readonly property string compositor: S.CompositorService.backend

    Process {
        id: screensProcess
        // -1 when nothing is waiting, otherwise 1 (on) or 0 (off).
        property int pending: -1
        stderr: StdioCollector {
            onStreamFinished: if (this.text.trim().length > 0) console.log("idle: screens:", this.text.trim())
        }
        onExited: {
            const next = screensProcess.pending;
            screensProcess.pending = -1;
            if (next >= 0) root.screens(next === 1);
        }
    }

    // Whether the last word this shell sent was "off". Waking from sleep and activity both send
    // "on", so this is only still set when the screens went dark here and nothing has lit them.
    property bool screensOff: false

    // Screens on again when the lock ends, but only if this shell turned them off. Not on every
    // unlock: measured on Hyprland 0.56, every unlock that sent "on" to an already-lit screen as
    // the lock surfaces were torn down left the screen black with the compositor alive (input still
    // handled, SIGTERM answered at once) -- three unlocks out of three. Asking for "on" when it
    // already is does not cost nothing there. Sent a moment after the lock ends rather than at the
    // same instant, so the lock's teardown is done before the outputs are touched.
    // Not gated on `configured`: a lock taken by hand before a suspend needs this just as much.
    Connections {
        target: S.Lock
        function onLockedChanged() {
            if (S.Lock.locked) screensAfterUnlock.stop();
            else if (root.screensOff) screensAfterUnlock.restart();
        }
    }

    Timer {
        id: screensAfterUnlock
        interval: 500
        onTriggered: if (root.screensOff && !S.Lock.locked) root.screens(true)
    }

    // Long-running helpers are started through `setpriv --pdeathsig TERM`, which has the kernel
    // kill them when this shell dies. Without it a killed or crashed shell leaves them behind:
    // measured, an orphaned sleep-delay inhibitor that went on delaying every suspend.
    function orphanSafe(command) {
        return ["setpriv", "--pdeathsig", "TERM", "--"].concat(command);
    }

    // The fingerprint reader is stopped and let go of before the suspend is even asked for. Waiting
    // inside the sleep delay is too late: fprintd hears PrepareForSleep at the same moment this
    // shell does and starts suspending the reader, and a verify killed then collides with that --
    // measured, "Error closing device after disconnect: The device is still busy" at the instant
    // of every idle suspend, even with the delay held a second longer, and no fingerprint after
    // waking until fprintd restarted.
    function suspend() {
        S.Lock.pauseFingerprint();
        suspendWhenReleased.restart();
    }

    Timer {
        id: suspendWhenReleased
        interval: 50
        repeat: true
        property int waited: 0
        onRunningChanged: if (running) waited = 0
        onTriggered: {
            waited += interval;
            const released = !S.Lock.fingerprintActive
                && Date.now() - S.Lock.fingerprintStoppedAt >= root.fingerprintSettleMs;
            if (released || waited >= 3000) {
                suspendWhenReleased.stop();
                suspendProcess.running = true;
            }
        }
    }

    Process {
        id: suspendProcess
        command: ["systemctl", "suspend"]
    }

    // Run `then` unless logind reports an idle inhibitor. Asked fresh every time: inhibitors come
    // and go with downloads, calls and presentations, and a cached answer would be wrong as often
    // as it was right.
    function unlessInhibited(then) {
        inhibitCheck.then = then;
        inhibitCheck.running = true;
    }

    Process {
        id: inhibitCheck
        property var then: null
        command: ["busctl", "--system", "get-property", "org.freedesktop.login1", "/org/freedesktop/login1",
            "org.freedesktop.login1.Manager", "BlockInhibited"]
        stdout: StdioCollector {
            onStreamFinished: {
                const blocked = this.text.split(/[":\s]+/).indexOf("idle") >= 0;
                const then = inhibitCheck.then;
                inhibitCheck.then = null;
                if (then) then(blocked);
            }
        }
    }

    // --- Idle stages -------------------------------------------------------------------------

    // Each stage is a plain IdleMonitor with a `held` flag; what it does lives in stageIdle and
    // stageActive below. (Not an inline component: those cannot see this file's ids.)
    function fire(stage) {
        root.unlessInhibited(function (blocked) {
            if (!stage.isIdle) return;
            if (blocked && !stage.held) console.log("idle: held back by a logind idle inhibitor (" + stage.timeout + "s stage)");
            stage.held = blocked;
            if (!blocked) root.stageIdle(stage);
        });
    }

    function changed(stage) {
        if (stage.isIdle) {
            root.fire(stage);
            return;
        }
        // Activity. A stage that never fired (held by an inhibitor) has nothing to undo.
        const wasHeld = stage.held;
        stage.held = false;
        if (!wasHeld) root.stageActive(stage);
    }

    function stageIdle(stage) {
        if (stage === lockStage) {
            S.Lock.lock();
        } else if (stage === screenStage) {
            root.screens(false);
        } else if (stage === suspendStage) {
            // The lock also comes from PrepareForSleep below when lockBeforeSleep is on; locking
            // here too covers a configuration that suspends without it. Paused first, so the lock
            // does not start a verify only for suspend() to kill it.
            S.Lock.pauseFingerprint();
            S.Lock.lock();
            root.screens(false);
            root.suspend();
        }
    }

    function stageActive(stage) {
        if (stage === screenStage || stage === suspendStage) root.screens(true);
    }

    IdleMonitor {
        id: lockStage
        property bool held: false
        respectInhibitors: true
        enabled: root.configured && root.lockAfter > 0
        timeout: Math.max(1, root.lockAfter)
        onIsIdleChanged: root.changed(lockStage)
    }

    IdleMonitor {
        id: screenStage
        property bool held: false
        respectInhibitors: true
        enabled: root.configured && root.screenOffAfter > 0
        timeout: Math.max(1, root.screenOffAfter)
        onIsIdleChanged: root.changed(screenStage)
    }

    IdleMonitor {
        id: suspendStage
        property bool held: false
        respectInhibitors: true
        enabled: root.configured && root.suspendAfter > 0
        timeout: Math.max(1, root.suspendAfter)
        onIsIdleChanged: root.changed(suspendStage)
    }

    // Retry stages held back by a logind inhibitor, for as long as the session stays idle.
    Timer {
        interval: 30000
        repeat: true
        running: lockStage.held || screenStage.held || suspendStage.held
        onTriggered: {
            for (const stage of [lockStage, screenStage, suspendStage]) {
                if (stage.held && stage.isIdle) root.fire(stage);
            }
        }
    }

    // --- logind ------------------------------------------------------------------------------

    Process {
        id: sessionLookup
        running: root.configured
        command: ["busctl", "--system", "get-property", "org.freedesktop.login1", "/org/freedesktop/login1/user/self",
            "org.freedesktop.login1.User", "Display"]
        stdout: StdioCollector {
            // (so) "26" "/org/freedesktop/login1/session/_326"
            onStreamFinished: {
                const match = this.text.match(/"(\/org\/freedesktop\/login1\/session\/[^"]+)"/);
                root.sessionPath = match ? match[1] : "";
            }
        }
    }

    // Lock and PrepareForSleep, one line per signal:
    //   /org/freedesktop/login1/session/_326: org.freedesktop.login1.Session.Lock ()
    //   /org/freedesktop/login1: org.freedesktop.login1.Manager.PrepareForSleep (true,)
    // Unlock is ignored on purpose: `loginctl unlock-session` must not get past the lock screen.
    Process {
        id: logind
        running: root.configured
        command: root.orphanSafe(["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1"])
        stdout: SplitParser {
            onRead: function (line) {
                if (line.indexOf("org.freedesktop.login1.Session.Lock ") >= 0) {
                    const path = line.split(":")[0].trim();
                    if (root.sessionPath === "" || path === root.sessionPath) S.Lock.lock();
                } else if (line.indexOf("org.freedesktop.login1.Manager.PrepareForSleep") >= 0) {
                    if (line.indexOf("true") >= 0) root.goingToSleep();
                    else root.wokeUp();
                }
            }
        }
        // gdbus exiting means the system bus went away or was restarted; follow it back.
        onExited: if (root.configured) logindRestart.start()
    }

    Timer {
        id: logindRestart
        interval: 2000
        onTriggered: logind.running = root.configured
    }

    // --- Sleep -------------------------------------------------------------------------------
    //
    // A delay inhibitor is held the whole time, which makes logind wait (up to its
    // InhibitDelayMaxSec, 5s by default) after announcing sleep. Releasing it once the lock is
    // confirmed is what guarantees the machine never sleeps -- and so never wakes -- showing the
    // desktop.

    // Set once the delay has been given up for this sleep, cleared on waking to take it again.
    property bool delayReleased: false

    Process {
        id: sleepDelay
        running: root.configured && root.lockBeforeSleep && !root.delayReleased
        command: root.orphanSafe(["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=epochshell",
            "--why=Lock the screen before sleeping", "sleep", "infinity"])
    }

    function goingToSleep() {
        // Before locking, so the lock does not start the fingerprint reader just as fprintd puts
        // it to sleep.
        S.Lock.pauseFingerprint();
        if (!root.lockBeforeSleep) return;
        S.Lock.lock();
        // Always through the timer, even when already locked: the verify just stopped above still
        // has to be let go of by fprintd before the machine sleeps (see LockService).
        sleepRelease.restart();
    }

    // How long fprintd is given to release the reader after the verify exits.
    readonly property int fingerprintSettleMs: 1000

    function readyToSleep() {
        return S.Lock.secure && !S.Lock.fingerprintActive
            && Date.now() - S.Lock.fingerprintStoppedAt >= root.fingerprintSettleMs;
    }

    function wokeUp() {
        S.Lock.resumeFingerprint();
        sleepRelease.stop();
        root.delayReleased = false;
        root.screens(true);
        // And again shortly after: PrepareForSleep(false) arrives the moment the kernel is back,
        // which can be before the compositor has its outputs again, and an "on" sent then is lost.
        screensAfterWake.restart();
        if (root.afterSleepCommand.length > 0) {
            afterSleep.command = ["sh", "-c", root.afterSleepCommand];
            afterSleep.running = true;
        }
    }

    // Waits for the lock to be confirmed and the fingerprint reader to be let go, then lets sleep go
    // ahead. Gives up before logind does, so a lock that will not confirm costs a moment rather than
    // the whole delay.
    Timer {
        id: sleepRelease
        interval: 50
        repeat: true
        property int waited: 0
        onRunningChanged: if (running) waited = 0
        onTriggered: {
            waited += interval;
            if (root.readyToSleep() || waited >= 3000) {
                sleepRelease.stop();
                root.delayReleased = true;
            }
        }
    }

    Timer {
        id: screensAfterWake
        interval: 2000
        onTriggered: root.screens(true)
    }

    Process {
        id: afterSleep
    }
}
