pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string socketPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/epochoxide.sock"

    property string vendor: ""
    property string product: ""
    property string family: ""
    property string biosVersion: ""
    property string kernel: ""
    property bool framework: false

    property int batteryHealth: 0
    property int batteryCycles: 0
    property string batteryModel: ""

    property bool firmwareAvailable: false
    property var firmwareUpdates: []

    readonly property bool connected: socketLoader.item !== null && socketLoader.item.connected
    readonly property bool hasFirmwareUpdates: firmwareUpdates.length > 0
    readonly property string firmwareIcon: "󰍛"

    readonly property string machine: {
        const parts = [];
        if (root.vendor.length > 0) parts.push(root.vendor);
        if (root.product.length > 0) parts.push(root.product);
        return parts.join(" ");
    }

    function refresh() {
        send("system.hardware", {});
    }

    function refreshFirmware(force) {
        send("system.firmware", { refresh: force === true });
    }

    function updateFirmware() {
        send("system.updateFirmware", {});
    }

    function send(method, params) {
        const socket = socketLoader.item;
        if (!socket || !socket.connected) return;
        socket.write(JSON.stringify({ type: "api", method: method, params: params || {}, version: 1 }) + "\n");
        socket.flush();
    }

    function apply(ok, data) {
        if (!ok) return;
        if (data.vendor !== undefined) {
            vendor = String(data.vendor || "");
            product = String(data.product || "");
            family = String(data.family || "");
            biosVersion = String(data.bios_version || "");
            kernel = String(data.kernel || "");
            framework = data.framework === true;
            const battery = data.battery || {};
            batteryHealth = Number(battery.health || 0);
            batteryCycles = Number(battery.cycle_count || 0);
            batteryModel = String(battery.model || battery.name || "");
            return;
        }
        if (data.updates !== undefined) {
            firmwareAvailable = data.available === true;
            firmwareUpdates = Array.isArray(data.updates) ? data.updates : [];
        }
    }

    function rebuildSocket() {
        socketLoader.active = false;
        socketLoader.active = true;
    }

    Timer {
        interval: 300000
        repeat: true
        running: root.connected
        triggeredOnStart: true
        onTriggered: {
            root.refresh();
            root.refreshFirmware(false);
        }
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
                if (epochoxideSocket.connected) {
                    root.refresh();
                    root.refreshFirmware(false);
                }
            }

            parser: SplitParser {
                onRead: function (line) {
                    let response;
                    try {
                        response = JSON.parse(line);
                    } catch (e) {
                        console.log("system epochoxide parse error:", e, line);
                        return;
                    }
                    root.apply(response.ok !== false, response.data || {});
                }
            }
        }
    }
}
