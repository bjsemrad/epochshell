pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property int selectionTimeoutMs: 300000
    readonly property int requestTimeoutMs: 8000
    readonly property int recordingPollMs: 1000
    readonly property int idlePollMs: 5000
    readonly property int retryMs: 2000

    readonly property string socketPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/epochoxide.sock"

    property string directory: ""
    property bool windowCapture: false
    property bool available: false
    property string unavailableReason: ""
    property bool ocrAvailable: false
    property string ocrLanguage: ""
    property bool recordAvailable: false
    property bool annotateAvailable: false
    property string recordingDirectory: ""

    property bool recording: false
    property string recordingPath: ""
    property string recordingMode: ""
    property int recordingSeconds: 0

    property bool copyToClipboard: true
    property bool saveToDisk: true
    property bool includeCursor: false
    property bool annotate: false

    property bool busy: false
    property string status: ""
    property string lastPath: ""
    property string backendError: ""

    property var _requestQueue: []
    property bool _requestInFlight: false

    readonly property bool connected: socketLoader.item !== null && socketLoader.item.connected
    readonly property string icon: "󰄀"

    readonly property real settleDelay: 0.4

    readonly property string recordingElapsed: {
        const total = root.recordingSeconds;
        const hours = Math.floor(total / 3600);
        const minutes = Math.floor((total % 3600) / 60);
        const seconds = total % 60;
        const pad = value => (value < 10 ? "0" + value : String(value));
        return hours > 0 ? (hours + ":" + pad(minutes) + ":" + pad(seconds)) : (minutes + ":" + pad(seconds));
    }

    function fileName(path) {
        const value = String(path || "");
        const index = value.lastIndexOf("/");
        return index >= 0 ? value.slice(index + 1) : value;
    }

    function refresh() {
        apiRequest("capture.status", {}, { kind: "status" });
    }

    function shoot(mode, select) {
        if (busy) return;
        const interactive = mode === "region" || (mode === "window" && select === true);
        busy = true;
        status = interactive ? "Waiting for a selection..." : "Taking a screenshot...";
        lastPath = "";
        PopupManager.closeAll();
        apiRequest("capture.screenshot", {
            mode: String(mode),
            select: select === true,
            cursor: root.includeCursor,
            copy: root.copyToClipboard,
            save: root.saveToDisk,
            annotate: root.annotate && root.annotateAvailable,
            delay: interactive ? 0 : root.settleDelay
        }, { kind: "screenshot", mode: String(mode) });
    }

    function readText(mode, select) {
        if (busy) return;
        const interactive = mode === "region" || (mode === "window" && select === true);
        busy = true;
        status = interactive ? "Waiting for a selection..." : "Reading text...";
        lastPath = "";
        PopupManager.closeAll();
        apiRequest("capture.ocr", {
            mode: String(mode),
            select: select === true,
            copy: root.copyToClipboard,
            save: false,
            delay: interactive ? 0 : root.settleDelay
        }, { kind: "ocr", mode: String(mode) });
    }

    function startRecording(mode, select) {
        if (busy || recording) return;
        const interactive = mode === "region" || (mode === "window" && select === true);
        busy = true;
        status = interactive ? "Waiting for a selection..." : "Starting the recording...";
        PopupManager.closeAll();
        apiRequest("capture.record", {
            mode: String(mode),
            select: select === true,
            delay: interactive ? 0 : root.settleDelay
        }, { kind: "record" });
    }

    function stopRecording() {
        if (!recording) return;
        busy = true;
        status = "Finishing the recording...";
        apiRequest("capture.stopRecording", {}, { kind: "stopRecording" });
    }

    function refreshRecording() {
        apiRequest("capture.recording", {}, { kind: "recording" });
    }

    function setCopyToClipboard(value) {
        copyToClipboard = value === true;
        if (!copyToClipboard && !saveToDisk) saveToDisk = true;
    }

    function setSaveToDisk(value) {
        saveToDisk = value === true;
        if (!copyToClipboard && !saveToDisk) copyToClipboard = true;
    }

    function setIncludeCursor(value) {
        includeCursor = value === true;
    }

    function setAnnotate(value) {
        annotate = value === true;
    }

    function applyStatus(ok, data, error) {
        if (!ok) {
            available = false;
            unavailableReason = error || "Capture is unavailable";
            return;
        }
        directory = String(data.directory || "");
        windowCapture = data.window_capture === true;
        ocrAvailable = data.ocr === true;
        ocrLanguage = String(data.ocr_language || "");
        recordAvailable = data.record === true;
        annotateAvailable = data.annotate === true;
        recordingDirectory = String(data.recording_directory || "");
        const tools = Array.isArray(data.tools) ? data.tools : [];
        const missing = tools.filter(tool => tool.required === true && !tool.path);
        available = missing.length === 0;
        unavailableReason = available ? "" : (missing.map(tool => tool.name).join(", ") + " is not installed");
        if (status.length === 0 && !available) status = unavailableReason;
    }

    function applyShot(ok, data, error) {
        busy = false;
        if (!ok) {
            status = error || "Screenshot failed";
            return;
        }
        if (data.cancelled === true) {
            status = "Cancelled";
            return;
        }
        lastPath = String(data.path || "");
        if (data.annotating === true) {
            status = "Opened in the editor";
            return;
        }
        const where = data.saved === true ? ("Saved " + root.fileName(lastPath)) : "Copied to the clipboard";
        const also = data.saved === true && data.copied === true ? ", copied" : "";
        status = where + also;
    }

    function applyText(ok, data, error) {
        busy = false;
        if (!ok) {
            status = error || "Reading text failed";
            return;
        }
        if (data.cancelled === true) {
            status = "Cancelled";
            return;
        }
        const characters = Number(data.characters || 0);
        if (characters === 0) {
            status = "No text found";
            return;
        }
        status = (data.copied === true ? "Copied " : "Read ") + characters + (characters === 1 ? " character" : " characters");
    }

    function applySession(ok, data, error, kind) {
        if (kind !== "recording") busy = false;
        if (!ok) {
            if (kind !== "recording") status = error || "Recording failed";
            return;
        }
        if (data.cancelled === true) {
            status = "Cancelled";
            return;
        }
        const wasRecording = recording;
        recording = data.recording === true;
        recordingPath = String(data.path || "");
        recordingMode = String(data.mode || "");
        recordingSeconds = Number(data.seconds || 0);
        if (recording) {
            if (kind === "record") status = "Recording " + recordingMode;
            return;
        }
        if (kind === "stopRecording" || (kind === "recording" && wasRecording)) {
            status = recordingPath.length > 0 ? ("Saved " + root.fileName(recordingPath)) : "Nothing was recorded";
            recordingPath = "";
        }
    }

    function apiRequest(method, params, meta) {
        _requestQueue = _requestQueue.concat([{ method: method, params: params || {}, meta: meta || {} }]);
        sendNextRequest();
    }

    function sendNextRequest() {
        if (_requestInFlight || _requestQueue.length === 0) return;
        const socket = socketLoader.item;
        if (!socket || !socket.connected) return;
        _requestInFlight = true;
        const request = _requestQueue[0];
        socket.write(JSON.stringify({ type: "api", method: request.method, params: request.params, version: 1 }) + "\n");
        socket.flush();
        requestTimeout.interval = request.meta.kind === "screenshot" ? root.selectionTimeoutMs : root.requestTimeoutMs;
        requestTimeout.restart();
    }

    function finishRequest() {
        requestTimeout.stop();
        _requestQueue = _requestQueue.slice(1);
        _requestInFlight = false;
        sendNextRequest();
    }

    function socketErrorText(error) {
        switch (error) {
        case 0: return "EpochOxide refused the connection";
        case 1: return "EpochOxide closed the connection";
        case 2: return "EpochOxide is not running";
        case 3: return "No permission to open the EpochOxide socket";
        case 5: return "EpochOxide timed out";
        default: return "Cannot reach EpochOxide";
        }
    }

    function rebuildSocket() {
        socketLoader.active = false;
        socketLoader.active = true;
    }

    Timer {
        id: requestTimeout
        repeat: false
        onTriggered: {
            const request = root._requestQueue.length > 0 ? root._requestQueue[0] : null;
            root.busy = false;
            if (request && (request.meta.kind === "screenshot" || request.meta.kind === "ocr")) {
                root.status = "The capture never came back";
            } else {
                root.backendError = "EpochOxide is not responding";
            }
            root._requestQueue = [];
            root._requestInFlight = false;
            root.rebuildSocket();
        }
    }

    Timer {
        id: recordingPoll
        interval: root.recording ? root.recordingPollMs : root.idlePollMs
        repeat: true
        running: root.connected
        onTriggered: {
            if (root.recording) root.recordingSeconds += 1;
            root.refreshRecording();
        }
    }

    Timer {
        id: retry
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
                if (!epochoxideSocket.connected) {
                    root._requestInFlight = false;
                    root.busy = false;
                    return;
                }
                root.backendError = "";
                root.sendNextRequest();
                root.refresh();
                root.refreshRecording();
            }

            onError: function (error) {
                root.backendError = root.socketErrorText(error);
            }

            parser: SplitParser {
                onRead: function (line) {
                    const request = root._requestQueue.length > 0 ? root._requestQueue[0] : null;
                    if (!request) return;
                    let response;
                    try {
                        response = JSON.parse(line);
                    } catch (e) {
                        console.log("capture epochoxide parse error:", e, line);
                        root.finishRequest();
                        return;
                    }
                    const ok = response.ok !== false;
                    const data = response.data || {};
                    const error = response.error || data.message || "";
                    // "unavailable" means a missing tool, not a broken backend.
                    if (ok) root.backendError = "";
                    else if (data.code !== "unavailable") root.backendError = error;
                    if (request.meta.kind === "status") {
                        root.applyStatus(ok, data, error);
                    } else if (request.meta.kind === "screenshot") {
                        root.applyShot(ok, data, error);
                    } else if (request.meta.kind === "ocr") {
                        root.applyText(ok, data, error);
                    } else if (request.meta.kind === "record" || request.meta.kind === "stopRecording" || request.meta.kind === "recording") {
                        root.applySession(ok, data, error, request.meta.kind);
                    }
                    root.finishRequest();
                }
            }
        }
    }
}
