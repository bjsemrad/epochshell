pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property int emptyQueryLimit: 30
    readonly property int queryLimit: 10
    readonly property int filesDebounceMs: 40
    readonly property int debounceMs: 150
    readonly property int requestTimeoutMs: 3000
    readonly property int retryMs: 2000

    property string query: ""
    property alias results: resultModel

    readonly property string socketPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/epochoxide.sock"
    readonly property string allPrefix: "*"
    property bool searching: false
    property var providerCapabilities: []
    property var availableProviders: []
    property var providersByPrefix: ({})
    readonly property string defaultProviders: availableProviders.join(",")
    readonly property bool backendConnected: socketLoader.item !== null && socketLoader.item.connected
    property string backendError: ""
    property bool _providersLoaded: false
    readonly property bool providersLoaded: _providersLoaded

    readonly property int defaultAppsTTL: 600000
    property bool _defaultAppsLoaded: false
    property int _defaultAppsStamp: 0
    property var _defaultAppsCache: []
    property bool _silentRefresh: false
    property var _requestQueue: []
    property bool _requestInFlight: false
    property var _streamBatches: ({})

    signal providersUpdated()
    signal resultsUpdated()

    ListModel {
        id: resultModel
    }

    property string scope: ""

    function setQuery(text) {
        query = text;
        debounceTimer.restart();
    }

    function setScope(name) {
        scope = String(name || "");
        query = "";
        debounceTimer.restart();
    }

    function isMathQuery(text) {
        const t = String(text).trim();
        return /[0-9].{0,4}[+\-*/^%()]|[+\-*/^%()].{0,4}[0-9]/.test(t);
    }

    function providerAvailable(provider) {
        // Optimistic until the providers response lands, or prefix routing loses the race and falls
        // back to apps.
        if (!root._providersLoaded) return true;
        const base = String(provider).split(":")[0];
        return availableProviders.indexOf(base) !== -1;
    }

    function enabledProviders(providers) {
        return String(providers).split(",").filter(p => root.providerAvailable(p)).join(",");
    }

    function providerForPrefix(prefix) {
        if (prefix in providersByPrefix) return providersByPrefix[prefix];
        return prefix === root.allPrefix ? root.enabledProviders(root.defaultProviders) : "";
    }

    // Longest prefix wins; prefixes are arbitrary strings in EpochOxide's config.
    function prefixFor(text) {
        const s = String(text);
        let best = "";
        for (const prefix in providersByPrefix) {
            if (prefix.length > best.length && s.startsWith(prefix)) best = prefix;
        }
        if (best.length === 0 && s.startsWith(root.allPrefix)) best = root.allPrefix;
        return best;
    }

    function capabilityFor(name) {
        for (const cap of providerCapabilities) {
            if (cap.name === name) return cap;
        }
        return null;
    }

    function prettyName(name) {
        const cap = root.capabilityFor(name);
        return cap ? cap.namePretty : name;
    }

    function prefixForProvider(name) {
        const cap = root.capabilityFor(name);
        return cap && cap.prefixes.length > 0 ? cap.prefixes[0] : "";
    }

    function applyProviders(list) {
        const caps = [];
        const names = [];
        const byPrefix = {};
        for (const raw of list) {
            if (!raw) continue;
            const name = typeof raw === "string" ? raw : String(raw.name || "");
            if (name.length === 0) continue;
            const prefixes = (Array.isArray(raw.prefixes) ? raw.prefixes : []).filter(p => typeof p === "string" && p.length > 0);
            caps.push({
                name: name,
                namePretty: String(raw.name_pretty || name),
                description: String(raw.description || ""),
                icon: String(raw.icon || ""),
                prefixes: prefixes,
                supportsQuery: raw.supports_query !== false
            });
            names.push(name);
            for (const prefix of prefixes) {
                if (!(prefix in byPrefix)) byPrefix[prefix] = name;
            }
        }
        root.providerCapabilities = caps;
        root.availableProviders = names;
        root.providersByPrefix = byPrefix;
        root._providersLoaded = true;
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

    // A Socket that failed to connect stays dead; recovering means building a new one.
    function rebuildSocket() {
        socketLoader.active = false;
        socketLoader.active = true;
    }

    function sendNextRequest() {
        if (_requestInFlight || _requestQueue.length === 0) return;
        const socket = socketLoader.item;
        if (!socket || !socket.connected) return;
        _requestInFlight = true;
        const request = _requestQueue[0];
        if (request.payload.type === "query") root._streamBatches = {};
        socket.write(JSON.stringify(request.payload) + "\n");
        socket.flush();
        requestTimeout.restart();
    }

    function enqueueRequest(kind, payload, meta) {
        if (kind === "query") {
            const active = _requestInFlight && _requestQueue.length > 0 ? [_requestQueue[0]] : [];
            _requestQueue = active.concat(_requestQueue.slice(active.length).filter(r => r.kind !== "query"));
        }
        _requestQueue = _requestQueue.concat([{ kind: kind, payload: payload, meta: meta || {} }]);
        sendNextRequest();
    }

    function startQuery(providers, q) {
        const limit = q === "" ? root.emptyQueryLimit : root.queryLimit;
        const silent = root._silentRefresh;
        root._silentRefresh = false;
        const meta = { providers: providers, query: q, limit: limit, silent: silent };
        const providerList = String(providers).split(",").filter(p => p.length > 0);
        enqueueRequest("query", { type: "query", providers: providerList, query: q, limit: limit, exact: false, stream: providerList.length > 1 }, meta);
        if (!silent) root.searching = true;
    }

    function isDefaultAppsQuery(meta) {
        return meta.providers === "apps" && meta.query === "" && meta.limit === root.emptyQueryLimit;
    }

    function showCachedApps() {
        searching = false;
        resultModel.clear();
        for (const it of _defaultAppsCache) resultModel.append(it);
        root.resultsUpdated();
    }

    function applyResults(items) {
        resultModel.clear();
        for (const it of items) resultModel.append(it);
        root.resultsUpdated();
    }

    function runQuery() {
        debounceTimer.stop();
        const raw = query;
        if (raw.startsWith(";")) {
            resultModel.clear();
            root.resultsUpdated();
            return;
        }
        const prefix = root.prefixFor(raw);
        let providers;
        let q;
        const prefixedProvider = root.providerForPrefix(prefix);
        if (prefixedProvider.length > 0) {
            providers = prefixedProvider;
            q = raw.slice(prefix.length);
        } else if (root.scope.length > 0) {
            providers = root.scope === root.allPrefix
                ? root.enabledProviders(root.defaultProviders)
                : root.scope;
            q = raw.trim();
        } else if (root.providerAvailable("calc") && root.isMathQuery(raw)) {
            providers = "calc";
            q = raw.trim();
        } else {
            providers = "apps";
            q = raw.trim();
        }
        if (providers === "apps" && q === "" && _defaultAppsLoaded) {
            showCachedApps();
            if (Date.now() - _defaultAppsStamp >= defaultAppsTTL) {
                _silentRefresh = true;
                startQuery(providers, q);
            }
            return;
        }
        startQuery(providers, q);
    }

    function activate(provider, identifier, action) {
        enqueueRequest("activate", { type: "activate", provider: provider, identifier: identifier, action: action || "", query: query, arguments: "" });
    }

    function refreshProviders() {
        if (_requestQueue.some(request => request.kind === "providers")) {
            sendNextRequest();
            return;
        }
        enqueueRequest("providers", { type: "providers" });
    }

    function normalizeItem(obj) {
        const item = obj.item || obj;
        if (!item) return null;
        return {
            provider: item.provider || "",
            identifier: item.identifier || "",
            text: item.text || "",
            subtext: item.subtext || "",
            icon: item.icon || "",
            score: item.score || 0,
            action: (item.actions && item.actions.length > 0) ? item.actions[0] : "",
            preview: item.preview || "",
            previewType: item.preview_type || ""
        };
    }

    function applyQueryResult(data, meta) {
        root.searching = false;
        const items = [];
        try {
            const arr = Array.isArray(data) ? data : [];
            for (const obj of arr) {
                const item = normalizeItem(obj);
                if (!item) continue;
                items.push(item);
                if (items.length >= meta.limit) break;
            }
        } catch (e) {
            console.log("launcher query parse error:", e);
        }
        root.applyResults(items);
    }

    function mergedStreamItems(limit) {
        let merged = [];
        for (const provider in root._streamBatches) merged = merged.concat(root._streamBatches[provider]);
        merged.sort((a, b) => b.score - a.score || (a.text < b.text ? -1 : a.text > b.text ? 1 : 0));
        return merged.slice(0, limit);
    }

    function mergeQueryBatch(provider, rawItems, meta) {
        try {
            const batches = root._streamBatches;
            batches[String(provider)] = (rawItems || []).map(normalizeItem).filter(i => i);
            root._streamBatches = batches;
        } catch (e) {
            console.log("launcher query batch parse error:", e);
            return;
        }
        root.applyResults(root.mergedStreamItems(meta.limit));
    }

    function finishStreamedQuery(meta) {
        root.searching = false;
        const items = root.mergedStreamItems(meta.limit);
        root._streamBatches = {};
        if (root.isDefaultAppsQuery(meta)) {
            root._defaultAppsCache = items;
            root._defaultAppsStamp = Date.now();
            root._defaultAppsLoaded = true;
        }
        root.applyResults(items);
    }

    function finishRequest() {
        requestTimeout.stop();
        root._requestQueue = root._requestQueue.slice(1);
        root._requestInFlight = false;
        root.sendNextRequest();
    }

    Timer {
        id: debounceTimer
        interval: root.providerForPrefix(root.prefixFor(root.query)) === "files" ? root.filesDebounceMs : root.debounceMs
        repeat: false
        onTriggered: root.runQuery()
    }

    Timer {
        id: requestTimeout
        interval: root.requestTimeoutMs
        repeat: false
        onTriggered: {
            root._requestQueue = [];
            root._requestInFlight = false;
            root._streamBatches = {};
            root.searching = false;
            console.log("launcher epochoxide timeout:", root.socketPath);
            if (root.backendConnected) root.backendError = "EpochOxide is not responding";
            root.rebuildSocket();
        }
    }

    Timer {
        id: retryTimer
        interval: root.retryMs
        repeat: true
        running: !root.backendConnected
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
                    root._requestQueue = [];
                    root._requestInFlight = false;
                    root._streamBatches = {};
                    root.searching = false;
                    return;
                }
                root.backendError = "";
                root.refreshProviders();
            }

            onError: function (error) {
                root.backendError = root.socketErrorText(error);
            }

            parser: SplitParser {
                onRead: function (line) {
                    root.backendError = "";
                    const request = root._requestQueue.length > 0 ? root._requestQueue[0] : null;
                    if (!request) return;
                    let response;
                    try {
                        response = JSON.parse(line);
                    } catch (e) {
                        console.log("launcher epochoxide parse error:", e, line);
                        return;
                    }
                    if (response.ok === false) {
                        console.log("launcher epochoxide error:", response.error || "request failed");
                        root.finishRequest();
                        return;
                    }
                    if (request.kind === "providers") {
                        root.applyProviders(Array.isArray(response.data) ? response.data : []);
                        root.providersUpdated();
                        root.finishRequest();
                        return;
                    }
                    if (request.kind === "query") {
                        const data = response.data;
                        if (Array.isArray(data)) {
                            root.applyQueryResult(data, request.meta);
                            root.finishRequest();
                            return;
                        }
                        if (data && data.type === "query_batch") {
                            root.mergeQueryBatch(data.provider, data.items, request.meta);
                            requestTimeout.restart();
                            return;
                        }
                        root.finishStreamedQuery(request.meta);
                        root.finishRequest();
                        return;
                    }
                    root.finishRequest();
                }
            }
        }
    }

    Component.onCompleted: root.refreshProviders()
}
