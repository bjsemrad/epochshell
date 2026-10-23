pragma Singleton
import QtQuick
import Quickshell
import qs.services as S

Singleton {
    id: root

    property string kind: ""
    property string icon: ""
    property real value: 0
    property int steps: 0
    property string label: ""
    property string text: ""
    property string detail: ""
    property bool muted: false
    property bool visible: false

    property var barReady: ({})
    function setBarReady(screenName, ready) {
        if (root.barReady[screenName] === ready) return;
        const next = Object.assign({}, root.barReady);
        next[screenName] = ready;
        root.barReady = next;
    }

    readonly property string screenName: {
        const focused = S.CompositorService.monitors.find(m => m.focused === true);
        if (focused) return String(focused.name);
        return Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "";
    }
    readonly property bool inBar: root.barReady[root.screenName] === true

    // Whether an open panel already shows this change: the dashboard's main and sound pages and the
    // sound panel show the volume, the media panel the track. Then there is nothing to add.
    function shownInPanel(kind) {
        for (const entry of S.PopupManager.entries) {
            const panel = entry.popup;
            if (!panel || !panel.open || !panel.visible) continue;
            if (kind === "volume") {
                if (entry.name === "dashboard" && (panel.page === "main" || panel.page === "audio")) return true;
                if (entry.name === "audio" && panel.page === undefined) return true;
            }
            if (kind === "media" && entry.name === "media") return true;
        }
        return false;
    }

    function show(fields, duration) {
        if (root.shownInPanel(String(fields.kind || ""))) {
            root.visible = false;
            return;
        }
        root.kind = String(fields.kind || "");
        root.icon = String(fields.icon || "");
        root.value = Number(fields.value) || 0;
        root.steps = Number(fields.steps) || 0;
        root.label = String(fields.label || "");
        root.text = String(fields.text || "");
        root.detail = String(fields.detail || "");
        root.muted = fields.muted === true;
        root.visible = true;
        hideTimer.interval = duration > 0 ? duration : 1000;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1000
        onTriggered: root.visible = false
    }
}
