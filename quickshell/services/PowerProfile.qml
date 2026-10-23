pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string socketPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/epochoxide.sock"

    property bool available: false
    property string reason: ""
    property string profile: ""
    property string governor: ""
    property string energyPreference: ""
    property var turbo: null
    property string driver: ""
    property string manager: ""
    property string platformProfile: ""

    property bool watching: false

    readonly property bool connected: socketLoader.item !== null && socketLoader.item.connected

    readonly property string profileLabel: {
        switch (root.profile) {
        case "performance": return "Performance";
        case "balanced": return "Balanced";
        case "power-saver": return "Power saver";
        default: return root.governor.length > 0 ? root.governor : "Unknown";
        }
    }

    readonly property string profileIcon: {
        switch (root.profile) {
        case "performance": return "󰓅";
        case "power-saver": return "󰌪";
        default: return "󰾅";
        }
    }

    readonly property string detail: {
        const parts = [];
        if (root.governor.length > 0) parts.push(root.governor);
        if (root.energyPreference.length > 0) parts.push(root.energyPreference);
        if (root.turbo !== null) parts.push(root.turbo ? "turbo on" : "turbo off");
        return parts.join(" · ");
    }

    function refresh() {
        send("system.power");
    }

    function send(method) {
        const socket = socketLoader.item;
        if (!socket || !socket.connected) return;
        socket.write(JSON.stringify({ type: "api", method: method, params: {}, version: 1 }) + "\n");
        socket.flush();
    }

    function apply(ok, data) {
        if (!ok) {
            available = false;
            return;
        }
        available = data.available === true;
        reason = String(data.reason || "");
        profile = String(data.profile || "");
        governor = String(data.governor || "");
        energyPreference = String(data.energy_preference || "");
        turbo = data.turbo === null || data.turbo === undefined ? null : data.turbo === true;
        driver = String(data.driver || "");
        manager = String(data.manager || "");
        platformProfile = String(data.platform_profile || "");
    }

    function rebuildSocket() {
        socketLoader.active = false;
        socketLoader.active = true;
    }

    Timer {
        id: poll
        interval: 5000
        repeat: true
        running: root.watching && root.connected
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: retry
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
                        console.log("power epochoxide parse error:", e, line);
                        return;
                    }
                    root.apply(response.ok !== false, response.data || {});
                }
            }
        }
    }
}
