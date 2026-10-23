import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services as S

Scope {
    id: root

    readonly property string settingsPath: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/epochshell-idle.json"

    property bool configured: false
    property int lockAfter: 0
    property int screenOffAfter: 0
    property int suspendAfter: 0
    property bool lockBeforeSleep: false
    property string afterSleepCommand: ""

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

    function screens(on, force) {
        // On Hyprland an "on" sent to a lit screen blanks it, so only the first "on" after our own
        // "off" goes out.
        if (on && !force && !root.screensOff && root.compositor === "hypr") return;
        console.log("idle: screens " + (on ? "on" : "off") + " (" + (root.compositor || "unknown") + ")");
        root.screensOff = !on;
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
                # Nothing to light: every output already on.
                if [ "$on" = 1 ] && mons=$(hyprctl monitors -j 2>/dev/null) && [ -n "$mons" ] \
                    && ! printf '%s' "$mons" | grep -q '"dpmsStatus": *false'; then return 0; fi
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

    readonly property string compositor: S.CompositorService.backend

    Process {
        id: screensProcess
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

    property bool screensOff: false

    // Only if we turned them off: on Hyprland 0.56 an "on" to a lit screen during unlock left it
    // dark.
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

    // setpriv --pdeathsig TERM: helpers die with the shell instead of being orphaned (an orphaned
    // sleep inhibitor blocked suspend).
    function orphanSafe(command) {
        return ["setpriv", "--pdeathsig", "TERM", "--"].concat(command);
    }

    // Stop the fingerprint verify before asking to suspend: fprintd suspends the reader on
    // PrepareForSleep, and a verify across that wedges it.
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

    // Not an inline component: those cannot see this file's ids.
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

    Process {
        id: sessionLookup
        running: root.configured
        command: ["busctl", "--system", "get-property", "org.freedesktop.login1", "/org/freedesktop/login1/user/self",
            "org.freedesktop.login1.User", "Display"]
        stdout: StdioCollector {
            onStreamFinished: {
                const match = this.text.match(/"(\/org\/freedesktop\/login1\/session\/[^"]+)"/);
                root.sessionPath = match ? match[1] : "";
            }
        }
    }

    // One line per signal, e.g. `/org/freedesktop/login1/session/_326:
    // org.freedesktop.login1.Session.Lock ()`. Unlock is ignored on purpose.
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
        onExited: if (root.configured) logindRestart.start()
    }

    Timer {
        id: logindRestart
        interval: 2000
        onTriggered: logind.running = root.configured
    }

    // A delay inhibitor is held throughout so logind waits (InhibitDelayMaxSec) while we lock and
    // release the reader before sleep.

    property bool delayReleased: false

    Process {
        id: sleepDelay
        running: root.configured && root.lockBeforeSleep && !root.delayReleased
        command: root.orphanSafe(["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=epochshell",
            "--why=Lock the screen before sleeping", "sleep", "infinity"])
    }

    function goingToSleep() {
        S.Lock.pauseFingerprint();
        if (!root.lockBeforeSleep) return;
        S.Lock.lock();
        sleepRelease.restart();
    }

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
        // Again shortly after: PrepareForSleep(false) can arrive before the compositor has its
        // outputs back, and an "on" then is lost.
        screensAfterWake.restart();
        if (root.afterSleepCommand.length > 0) {
            afterSleep.command = ["sh", "-c", root.afterSleepCommand];
            afterSleep.running = true;
        }
    }

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
        onTriggered: root.screens(true, true)
    }

    Process {
        id: afterSleep
    }
}
