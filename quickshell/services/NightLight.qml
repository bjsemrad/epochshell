pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property int neutralKelvin: 6500
    readonly property int statusPollMs: 30000
    readonly property int retryMs: 5000

    readonly property string socketPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/epochoxide.sock"

    property bool enabled: false
    property int temperature: 0
    property int daylight: neutralKelvin
    property string tool: ""
    property bool available: false
    property string unavailableReason: ""

    readonly property bool connected: socketLoader.item !== null && socketLoader.item.connected
    readonly property string icon: "󰖔"

    function refresh() {
        send("system.nightLight", {});
    }

    function toggle() {
        send("system.setNightLight", {});
    }

    function set(value) {
        send("system.setNightLight", { enabled: value === true });
    }

    function setTemperature(kelvin) {
        send("system.setNightLight", { enabled: true, temperature: Math.round(kelvin) });
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
        enabled = data.enabled === true;
        temperature = Number(data.temperature || 0);
        daylight = Number(data.daylight || root.neutralKelvin);
        tool = String(data.tool || "");
        available = data.available === true;
        unavailableReason = String(data.unavailable_reason || "");
    }

    function rebuildSocket() {
        socketLoader.active = false;
        socketLoader.active = true;
    }

    Timer {
        interval: root.statusPollMs
        repeat: true
        running: root.connected
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        interval: root.retryMs
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
                        console.log("night light epochoxide parse error:", e, line);
                        return;
                    }
                    root.apply(response.ok !== false, response.data || {});
                }
            }
        }
    }
}
