pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string socketPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/epochoxide.sock"

    property var wallpapers: []
    property string current: ""
    property var directories: []
    property string fitMode: "cover"
    property string backend: ""
    property bool available: false
    property string unavailableReason: ""

    readonly property bool connected: socketLoader.item !== null && socketLoader.item.connected
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
        if (!ok) {
            available = false;
            backend = "";
            wallpapers = [];
            unavailableReason = String(error || "EpochOxide cannot answer about wallpapers");
            return;
        }
        // Only when changed: an equal but new array would rebuild the picker's grid under the user.
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

    Timer {
        interval: 10000
        repeat: true
        running: root.connected && !root.streaming
        onTriggered: root.rebuildSubscription()
    }

    // Its own connection: a stream holds the socket.
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
