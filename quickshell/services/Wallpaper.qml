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
Singleton {
    id: root

    readonly property string socketPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/epochoxide.sock"

    property var wallpapers: []
    property string current: ""
    property var directories: []
    property bool available: false
    property string unavailableReason: ""

    readonly property bool connected: socketLoader.item !== null && socketLoader.item.connected

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

    function apply(ok, data) {
        if (!ok) {
            available = false;
            return;
        }
        wallpapers = data.wallpapers || [];
        current = String(data.current || "");
        directories = data.directories || [];
        available = data.available === true;
        unavailableReason = String(data.unavailable_reason || "");
    }

    function rebuildSocket() {
        socketLoader.active = false;
        socketLoader.active = true;
    }

    // Images are added and removed by hand, so a poll is the only way to notice. Slow, because
    // this is a directory listing rather than anything that changes on its own.
    Timer {
        interval: 120000
        repeat: true
        running: root.connected
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        interval: 5000
        repeat: true
        running: !root.connected
        onTriggered: root.rebuildSocket()
    }

    Loader {
        id: socketLoader
        active: true

        sourceComponent: Socket {
            id: epochoxideSocket
            path: root.socketPath
            connected: true

            onConnectionStateChanged: {
                if (epochoxideSocket.connected) root.refresh();
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
                    root.apply(response.ok !== false, response.data || {});
                }
            }
        }
    }
}
