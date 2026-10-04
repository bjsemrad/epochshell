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

    // Screens off and on, per compositor. The backend comes from EpochOxide; the environment is the
    // fallback for a daemon that is not answering. Hyprland's Lua dispatcher is tried before the
    // classic one, since which of the two a given Hyprland speaks depends on its config.
    function screens(on) {
        screensProcess.command = ["sh", "-c", `
            backend="$1"; on="$2"
            [ -n "$backend" ] || { [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] && backend=hypr; }
            [ -n "$backend" ] || { [ -n "$NIRI_SOCKET" ] && backend=niri; }
            [ -n "$backend" ] || { [ -n "$SWAYSOCK" ] && backend=sway; }
            case "$backend" in
              hypr)
                if [ "$on" = 1 ]; then lua=enable; classic=on; else lua=disable; classic=off; fi
                out=$(hyprctl dispatch "hl.dsp.dpms({ action = \\"$lua\\" })" 2>/dev/null)
                [ "$out" = ok ] || hyprctl dispatch dpms "$classic" ;;
              niri)
                if [ "$on" = 1 ]; then niri msg action power-on-monitors; else niri msg action power-off-monitors; fi ;;
              sway)
                if [ "$on" = 1 ]; then swaymsg 'output * power on'; else swaymsg 'output * power off'; fi ;;
            esac`, "screens", S.CompositorService.backend, on ? "1" : "0"];
        screensProcess.running = true;
    }

    Process {
        id: screensProcess
    }

    function suspend() {
        suspendProcess.running = true;
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
            // here too covers a configuration that suspends without it.
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
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1"]
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
        command: ["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=epochshell",
            "--why=Lock the screen before sleeping", "sleep", "infinity"]
    }

    function goingToSleep() {
        if (!root.lockBeforeSleep) return;
        S.Lock.lock();
        if (S.Lock.secure) {
            root.delayReleased = true;
        } else {
            sleepRelease.restart();
        }
    }

    function wokeUp() {
        sleepRelease.stop();
        root.delayReleased = false;
        root.screens(true);
        if (root.afterSleepCommand.length > 0) {
            afterSleep.command = ["sh", "-c", root.afterSleepCommand];
            afterSleep.running = true;
        }
    }

    // Waits for the lock to be confirmed, then lets sleep go ahead. Gives up before logind does, so
    // a lock that will not confirm costs a moment rather than the whole delay.
    Timer {
        id: sleepRelease
        interval: 50
        repeat: true
        property int waited: 0
        onRunningChanged: if (running) waited = 0
        onTriggered: {
            waited += interval;
            if (S.Lock.secure || waited >= 3000) {
                sleepRelease.stop();
                root.delayReleased = true;
            }
        }
    }

    Process {
        id: afterSleep
    }
}
