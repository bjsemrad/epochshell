pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The wallpaper, over EpochOxide's API.
//
// The state lives in the backend, which is what lets `epochctl wallpaper next` work with the shell
// closed and lets the choice be put back at session start, before anything has drawn. Shaped like
// NightLight.qml and StayAwake.qml, because it is the same kind of thing: one piece of system state
// the daemon owns and this asks about.
//
// Unlike those, it is also streamed. When `backend` is "shell" this shell is what draws the
// wallpaper (Background.qml), so a switch made from anywhere -- `epochctl wallpaper next` from a
// keybinding, say -- has to reach the screen at once rather than at the next poll.
Singleton {
    id: root

    readonly property string socketPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/epochoxide.sock"

    property var wallpapers: []
    property string current: ""
    property var directories: []
    property string fitMode: "cover"
    // "shell" when this shell draws the wallpaper, "hyprpaper" when that does, empty when neither
    // can. Background.qml draws only on "shell", so it never sits under a running hyprpaper.
    property string backend: ""
    property bool available: false
    property string unavailableReason: ""

    readonly property bool connected: socketLoader.item !== null && socketLoader.item.connected
    // Whether the daemon is streaming changes. An EpochOxide older than this shell has no
    // wallpaper.subscribe, and then the poll below is all there is.
    property bool streaming: false

    function refresh() {
        send("wallpaper.status", {});
    }

    function set(path) {
        const wanted = String(path || "").trim();
        if (wanted === "") return false;
        send("wallpaper.set", { path: wanted });
        return true;
    }

    // Signed, so one call covers both directions.
    function step(by) {
        send("wallpaper.next", { step: by || 1 });
    }

    function displayName(path) {
        const name = String(path || "").split("/").pop();
        const dot = name.lastIndexOf(".");
        return dot <= 0 ? name : name.slice(0, dot);
    }

    function send(method, params) {
        const socket = socketLoader.item;
        if (!socket || !socket.connected) return;
        socket.write(JSON.stringify({ type: "api", method: method, params: params || {}, version: 1 }) + "\n");
        socket.flush();
    }

    function apply(ok, data, error) {
        // A refusal is worth keeping the text of. The most likely one by far is a daemon older than
        // this shell, which answers `no API group "wallpaper"` -- and a caller that only learns
        // "unavailable" cannot tell that apart from "no images on disk".
        if (!ok) {
            available = false;
            backend = "";
            wallpapers = [];
            unavailableReason = String(error || "EpochOxide cannot answer about wallpapers");
            return;
        }
        // Only when it changed: the picker's grid is built from this list, and handing it an equal
        // but new array every heartbeat would rebuild the grid under a user browsing it.
        const found = data.wallpapers || [];
        if (JSON.stringify(found) !== JSON.stringify(wallpapers)) wallpapers = found;
        current = String(data.current || "");
        directories = data.directories || [];
        fitMode = String(data.fit_mode || "cover");
        backend = String(data.backend || "");
        available = data.available === true;
        unavailableReason = String(data.unavailable_reason || "");
    }

    function rebuildSocket() {
        socketLoader.active = false;
        socketLoader.active = true;
    }

    function rebuildSubscription() {
        subscriptionLoader.active = false;
        subscriptionLoader.active = true;
    }

    // Images are added and removed by hand, so something has to look again now and then. The
    // stream does that itself (it re-sends on a two-minute heartbeat), so this only runs without
    // one. Slow, because this is a directory listing rather than anything that changes on its own.
    Timer {
        interval: 120000
        repeat: true
        running: root.connected && !root.streaming
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        interval: 5000
        repeat: true
        running: !root.connected
        onTriggered: root.rebuildSocket()
    }

    // The stream ends when the daemon restarts. Retrying is slow enough that a daemon which simply
    // does not have the method costs one refused request every ten seconds, nothing more.
    Timer {
        interval: 10000
        repeat: true
        running: root.connected && !root.streaming
        onTriggered: root.rebuildSubscription()
    }

    // Its own connection: a stream holds the socket for as long as it runs, so set and next could
    // not share it.
    Loader {
        id: subscriptionLoader
        active: true

        sourceComponent: Socket {
            id: subscriptionSocket
            path: root.socketPath
            connected: true

            onConnectionStateChanged: {
                if (subscriptionSocket.connected) {
                    subscriptionSocket.write(JSON.stringify({ type: "api", method: "wallpaper.subscribe", version: 1 }) + "\n");
                    subscriptionSocket.flush();
                } else {
                    root.streaming = false;
                }
            }

            parser: SplitParser {
                onRead: function (line) {
                    let response;
                    try {
                        response = JSON.parse(line);
                    } catch (e) {
                        console.log("wallpaper subscription parse error:", e, line);
                        return;
                    }
                    // A refusal here is an older daemon, not a broken wallpaper: leave the state
                    // to the request socket and fall back to polling.
                    if (response.ok === false) {
                        root.streaming = false;
                        return;
                    }
                    const data = response.data || {};
                    if (data.type === "subscribed") {
                        root.streaming = true;
                        return;
                    }
                    root.apply(true, data, "");
                }
            }
        }
    }

    Loader {
        id: socketLoader
        active: true

        sourceComponent: Socket {
            id: epochoxideSocket
            path: root.socketPath
            connected: true

            onConnectionStateChanged: {
                if (!epochoxideSocket.connected) return;
                root.refresh();
                // The daemon is back, so the stream can be too -- now, rather than on the retry
                // timer's next tick, which left a switch made just after a daemon restart
                // invisible for up to fifteen seconds.
                if (!root.streaming) root.rebuildSubscription();
            }

            parser: SplitParser {
                onRead: function (line) {
                    let response;
                    try {
                        response = JSON.parse(line);
                    } catch (e) {
                        console.log("wallpaper epochoxide parse error:", e, line);
                        return;
                    }
                    const data = response.data || {};
                    root.apply(response.ok !== false, data, response.error || data.message || "");
                }
            }
        }
    }
}
