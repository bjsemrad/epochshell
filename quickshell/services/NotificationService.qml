pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root
    readonly property int genericIconPenalty: -100
    readonly property int iconMatchFloor: -50
    readonly property int thumbnailMaxBytes: 5242880
    readonly property int thumbnailTimeoutS: 5
    readonly property int expirySweepMs: 60000

    property alias toastModel: toastModel
    property alias historyModel: historyModel
    property var liveNotifications: ({})
    property bool doNotDisturb: false
    property int unreadCount: 0
    readonly property int historyLimit: 30
    readonly property int historyLifetimeMinutes: 60
    readonly property int normalTimeout: 3500
    readonly property int lowTimeout: 2000
    readonly property string imageStateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/epochshell/notifications/images/"

    readonly property var browserNames: ({
        "brave": "brave-",
        "Brave": "brave-",
        "chrome": "chrome-",
        "Chrome": "chrome-",
        "Chromium": "chrome-",
        "firefox": "firefox-",
        "Firefox": "firefox-",
        "vivaldi": "vivaldi-",
        "Vivaldi": "vivaldi-",
        "edge": "edge-",
        "Edge": "edge-",
        "chromium": "chrome-",
    })

    readonly property var browserGenericClasses: ({
        "brave-": ["brave-browser"],
        "chrome-": ["chrome", "chromium", "google-chrome", "google-chrome-stable"],
        "firefox-": ["firefox"],
        "vivaldi-": ["vivaldi", "vivaldi-stable"],
        "edge-": ["microsoft-edge", "microsoft-edge-stable"]
    })

    function isGenericBrowserClass(prefix, cls) {
        const generic = browserGenericClasses[prefix] || [];
        const lower = String(cls || "").toLowerCase();
        for (let i = 0; i < generic.length; i++) {
            if (lower === generic[i]) return true;
        }
        return false;
    }

    function browserPrefixForAppName(appName) {
        const exact = browserNames[appName];
        if (exact) return exact;

        const lower = String(appName || "").toLowerCase();
        if (lower.indexOf("brave") !== -1) return "brave-";
        if (lower.indexOf("chrome") !== -1 || lower.indexOf("chromium") !== -1) return "chrome-";
        if (lower.indexOf("firefox") !== -1) return "firefox-";
        if (lower.indexOf("vivaldi") !== -1) return "vivaldi-";
        if (lower.indexOf("edge") !== -1) return "edge-";
        return "";
    }

    function normalizeClass(cls) {
        return String(cls || "").replace(/__-?Default$/, "");
    }

    function chromiumOriginHost(body) {
        const text = String(body || "").toLowerCase();
        let match = /^\s*<a\b[^>]*>\s*(?:https?:\/\/|www\.)?((?:[a-z0-9-]+\.)+[a-z]{2,})/i.exec(text);
        if (match) return match[1];
        match = /^\s*(?:https?:\/\/|www\.)?((?:[a-z0-9-]+\.)+[a-z]{2,})(?::\d+)?(?:\/\S*)?\s+/i.exec(text);
        return match ? match[1] : "";
    }

    function originSignals(host) {
        const value = String(host || "").toLowerCase();
        if (value.length === 0) return [];
        const out = [value];
        if (value.startsWith("www.")) out.push(value.slice(4));
        if (value.indexOf("mail.google.") !== -1) out.push("gmail");
        const parts = value.split(/[\-.]+/).filter(p => p.length >= 4 && ["mail", "google"].indexOf(p) === -1);
        for (let i = 0; i < parts.length; i++) out.push(parts[i]);
        return out;
    }

    function findBestBrowserWindow(appName, desktopEntry, title, body) {
        const browserPrefix = browserPrefixForAppName(`${appName} ${desktopEntry}`);
        if (!browserPrefix) return null;

        const prefix = browserPrefix.toLowerCase();
        const toplevels = [];

        const windows = CompositorService.windows;
        for (let i = 0; i < windows.length; i++) {
            const cls = normalizeClass(windows[i].app_id || "");
            if (!cls.toLowerCase().startsWith(prefix)) continue;
            toplevels.push({
                cls: cls,
                title: String(windows[i].title || "").toLowerCase(),
                generic: isGenericBrowserClass(prefix, cls),
                win: windows[i]
            });
        }

        if (toplevels.length === 0) return null;
        if (toplevels.length === 1) return toplevels[0];

        const tl = String(title || "").toLowerCase();
        const tokens = String(appName || "")
            .toLowerCase()
            .replace(/[^a-z0-9 ]+/g, " ")
            .split(/\s+/)
            .filter(t => t.length >= 3);
        const summaryTokens = tl
            .replace(/[^a-z0-9 ]+/g, " ")
            .split(/\s+/)
            .filter(t => t.length >= 4 && ["from", "the", "for", "with", "this", "that", "your", "have"].indexOf(t) === -1);
        const signals = originSignals(chromiumOriginHost(body));

        let best = toplevels[0];
        let bestScore = -Infinity;
        for (let i = 0; i < toplevels.length; i++) {
            const t = toplevels[i];
            let score = t.generic ? root.genericIconPenalty : 0;
            for (let n = 0; n < signals.length; n++) {
                if (t.cls.toLowerCase().indexOf(signals[n]) !== -1) score += n === 0 ? 120 : 80;
            }
            for (let n = 0; n < tokens.length; n++) {
                if (t.cls.toLowerCase().indexOf(tokens[n]) !== -1) score += 30;
            }
            for (let n = 0; n < summaryTokens.length; n++) {
                if (t.cls.toLowerCase().indexOf(summaryTokens[n]) !== -1) score += 15;
            }
            if (tl.length >= 3) {
                if (tl.indexOf(t.title) !== -1 && t.title.length >= 5) score += 15;
                if (t.title.indexOf(tl) !== -1) score += 20;
            }
            if (score > bestScore) {
                bestScore = score;
                best = t;
            }
        }

        if (bestScore > root.iconMatchFloor) return best;

        if (CompositorService.activeWindowClass.toLowerCase().startsWith(prefix)
                && !isGenericBrowserClass(prefix, CompositorService.activeWindowClass)) {
            return { cls: normalizeClass(CompositorService.activeWindowClass), win: null };
        }

        for (let i = 0; i < toplevels.length; i++) {
            if (!toplevels[i].generic) {
                return toplevels[i];
            }
        }

        if (CompositorService.activeWindowClass.toLowerCase().startsWith(prefix)) {
            return { cls: normalizeClass(CompositorService.activeWindowClass), win: null };
        }

        return toplevels[0];
    }

    function workspaceIconForWindow(win) {
        if (!win || !win.app_id) return "";
        const entry = CompositorService.getDesktopEntry(String(win.app_id));
        return entry ? CompositorService.getDesktopIcon(entry) : "";
    }

    function localImageFile(value) {
        let path = String(value || "");
        if (path.startsWith("file://")) {
            path = path.slice(7);
            try {
                path = decodeURIComponent(path);
            } catch (e) {
            }
        } else if (path.startsWith("image://icon/")) {
            path = path.slice("image://icon/".length);
        }
        return path.startsWith("/") ? path : "";
    }

    // A pixmap sent with a notification dies with it, so history cannot keep drawing it.
    function staleAfterTheNotification(source) {
        const value = String(source || "");
        return value.startsWith("image://") && !value.startsWith("image://icon/");
    }

    function persistNotificationImages(notificationId, timestamp, appIcon, image) {
        const stem = String(timestamp) + "-" + String(notificationId);
        const out = { appIcon: String(appIcon || ""), image: String(image || "") };
        const command = ["bash", "-c",
            "dir=$1; shift\n" +
            "mkdir -p \"$dir\" || exit 0\n" +
            "while [ $# -ge 2 ]; do\n" +
            "  if [ -f \"$1\" ] && timeout " + root.thumbnailTimeoutS + " head -c " + (root.thumbnailMaxBytes + 1) + " -- \"$1\" > \"$2.tmp\" 2>/dev/null && [ $(stat -c%s -- \"$2.tmp\") -le " + root.thumbnailMaxBytes + " ]; then mv -f -- \"$2.tmp\" \"$2\"; else rm -f -- \"$2.tmp\"; fi\n" +
            "  shift 2\n" +
            "done", "--", imageStateDir];
        let copies = 0;

        const appIconSource = localImageFile(out.appIcon);
        if (appIconSource.length > 0) {
            const target = imageStateDir + stem + "-appIcon";
            command.push(appIconSource, target);
            out.appIcon = "file://" + target;
            copies += 1;
        } else if (staleAfterTheNotification(out.appIcon)) {
            out.appIcon = "";
        }

        const imageSource = localImageFile(out.image);
        if (imageSource.length > 0) {
            const target = imageStateDir + stem + "-image";
            command.push(imageSource, target);
            out.image = "file://" + target;
            copies += 1;
        } else if (staleAfterTheNotification(out.image)) {
            out.image = "";
        }

        if (copies > 0) Quickshell.execDetached(command);
        return out;
    }

    function snapshotOf(notification, persistImages, notificationId, timestamp) {
        const appName = String(notification.appName || "");
        const desktopEntry = String(notification.desktopEntry || "");
        const image = String(notification.image || "");
        const appIcon = String(notification.appIcon || "");
        const summary = String(notification.summary || "");
        const body = String(notification.body || "");
        const imageValues = persistImages ? persistNotificationImages(notificationId, timestamp, appIcon, image) : { appIcon: appIcon, image: image };
        let windowClass = "";
        let displayAppIcon = imageValues.appIcon;
        let displayImage = imageValues.image;

        const isBrowser = browserPrefixForAppName(`${appName} ${desktopEntry}`).length > 0;
        const hasImage = displayImage.length > 0;
        const hasAppIcon = displayAppIcon.length > 0;

        if (isBrowser) {
            const win = findBestBrowserWindow(appName, desktopEntry, summary, body);
            if (win) {
                windowClass = win.cls;
                if (!hasImage && !hasAppIcon) {
                    displayAppIcon = workspaceIconForWindow(win.win);
                }
            }
        } else {
            if (hasAppIcon) {
                displayAppIcon = imageValues.appIcon;
            } else if (desktopEntry.length > 0) {
                const entry = CompositorService.getDesktopEntry(desktopEntry);
                if (entry) {
                    displayAppIcon = CompositorService.getDesktopIcon(entry);
                }
            }
            if (displayAppIcon.length === 0 && appName.length > 0) {
                const entry = CompositorService.getDesktopEntry(appName);
                if (entry) {
                    displayAppIcon = CompositorService.getDesktopIcon(entry);
                }
            }
        }

        return {
            notificationId: notificationId,
            appName: appName,
            appIcon: displayAppIcon,
            windowClass: windowClass,
            desktopEntry: desktopEntry,
            summary: String(notification.summary || ""),
            body: isBrowser ? body
                .replace(/^\s*<a\b[^>]*>\s*(?:https?:\/\/|www\.)?(?:[a-z0-9-]+\.)+[a-z]{2,}(?::\d+)?(?:\/[^<\s]*)?\s*<\/a>\s*/i, "")
                .replace(/^\s*(?:https?:\/\/|www\.)?(?:[a-z0-9-]+\.)+[a-z]{2,}(?::\d+)?(?:\/\S*)?\s+/i, "") : body,
            image: displayImage,
            urgency: notification.urgency,
            timestamp: timestamp,
            actions: JSON.stringify(actionsOf(notification)),
            groupKey: windowClass.length > 0 ? "class:" + windowClass : "app:" + appName.toLowerCase(),
            groupCount: 1,
            groupIds: JSON.stringify([notificationId]),
            serial: 0
        };
    }

    function actionsOf(notification) {
        const out = [];
        try {
            for (const action of notification.actions || []) {
                if (!action || action.identifier === "default") continue;
                out.push({ id: String(action.identifier), label: String(action.text || action.identifier) });
            }
        } catch (e) {
        }
        return out;
    }

    function invokeAction(notificationId, actionId) {
        const notification = liveNotifications[notificationId];
        if (!notification) return false;
        try {
            for (const action of notification.actions || []) {
                if (action && String(action.identifier) === String(actionId)) {
                    action.invoke();
                    closeNotificationEverywhere(notificationId);
                    return true;
                }
            }
        } catch (e) {
        }
        return false;
    }

    readonly property int toastLimit: 4

    function insertToast(item) {
        if (item.urgency !== NotificationUrgency.Critical) {
            for (let i = 0; i < toastModel.count; i++) {
                const existing = toastModel.get(i);
                if (existing.groupKey !== item.groupKey || existing.urgency === NotificationUrgency.Critical) continue;
                const ids = JSON.parse(existing.groupIds || "[]");
                ids.push(item.notificationId);
                const merged = Object.assign({}, item, {
                    groupCount: existing.groupCount + 1,
                    groupIds: JSON.stringify(ids),
                    serial: existing.serial + 1
                });
                toastModel.set(i, merged);
                if (i > 0) toastModel.move(i, 0, 1);
                return;
            }
        }
        toastModel.insert(0, item);
        while (toastModel.count > toastLimit) toastModel.remove(toastModel.count - 1);
    }

    function idsOf(item) {
        try {
            return JSON.parse(item.groupIds || "[]");
        } catch (e) {
            return [item.notificationId];
        }
    }

    function handleNotification(notification) {
        notification.tracked = true;

        const timestamp = Date.now();
        const notificationId = notification.id || timestamp;
        const historyItem = snapshotOf(notification, true, notificationId, timestamp);
        const toastItem = snapshotOf(notification, false, notificationId, timestamp);
        liveNotifications[notificationId] = notification;

        notification.closed.connect(function() {
            if (liveNotifications[notificationId] === notification) {
                delete liveNotifications[notificationId];
            }
        });

        addHistory(historyItem);
        unreadCount += 1;

        if (!doNotDisturb || toastItem.urgency === NotificationUrgency.Critical) {
            insertToast(toastItem);
        }
    }

    function addHistory(item) {
        historyModel.insert(0, item);
        const stems = [];
        while (historyModel.count > historyLimit) {
            stems.push(stemFor(historyModel.get(historyModel.count - 1)));
            historyModel.remove(historyModel.count - 1);
        }
        forgetImages(stems);
    }

    function dismissToast(index) {
        if (index < 0 || index >= toastModel.count) return;

        const item = toastModel.get(index);
        for (const id of idsOf(item)) closeLiveNotification(id);
        toastModel.remove(index);
    }

    function expireToast(index) {
        if (index < 0 || index >= toastModel.count) return;

        const item = toastModel.get(index);
        if (item.urgency === NotificationUrgency.Critical) return;

        closeLiveNotification(item.notificationId);
        toastModel.remove(index);
    }

    function dismissAllToasts() {
        for (let i = toastModel.count - 1; i >= 0; i--) {
            dismissToast(i);
        }
    }

    function clearHistory() {
        const stems = [];
        for (let i = 0; i < historyModel.count; i++) {
            stems.push(stemFor(historyModel.get(i)));
        }
        historyModel.clear();
        unreadCount = 0;
        forgetImages(stems);
    }

    // Critical notifications are kept regardless of age.
    function expireHistory() {
        if (historyLifetimeMinutes <= 0) return;
        const cutoff = Date.now() - historyLifetimeMinutes * 60000;
        let removed = 0;
        const stems = [];
        for (let i = historyModel.count - 1; i >= 0; i--) {
            const item = historyModel.get(i);
            if (item.urgency === NotificationUrgency.Critical) continue;
            if (Number(item.timestamp) > cutoff) continue;
            closeLiveNotification(item.notificationId);
            stems.push(stemFor(item));
            historyModel.remove(i);
            removed += 1;
        }
        if (removed > 0) unreadCount = Math.max(0, unreadCount - removed);
        if (stems.length > 0) forgetImages(stems);
    }

    function stemFor(item) {
        return String(item.timestamp) + "-" + String(item.notificationId);
    }

    function forgetImages(stems) {
        const paths = [];
        for (let i = 0; i < stems.length; i++) {
            paths.push(imageStateDir + stems[i] + "-image");
            paths.push(imageStateDir + stems[i] + "-appIcon");
        }
        if (paths.length === 0) return;
        Quickshell.execDetached(["rm", "-f"].concat(paths));
    }

    function dismissHistory(index) {
        if (index < 0 || index >= historyModel.count) return;

        const item = historyModel.get(index);
        closeLiveNotification(item.notificationId);
        removeToastById(item.notificationId);
        const stem = stemFor(item);
        historyModel.remove(index);
        forgetImages([stem]);
    }

    function markRead() {
        unreadCount = 0;
    }

    function toggleDoNotDisturb() {
        doNotDisturb = !doNotDisturb;
        if (doNotDisturb) dismissAllToasts();
    }

    function timeoutFor(urgency) {
        if (urgency === NotificationUrgency.Critical) return 0;
        if (urgency === NotificationUrgency.Low) return lowTimeout;
        return normalTimeout;
    }

    function closeLiveNotification(id) {
        const notification = liveNotifications[id];
        if (!notification) return;

        try {
            notification.dismiss();
        } catch (e) {
        }
        delete liveNotifications[id];
    }

    function invokeDefaultAction(id) {
        const notification = liveNotifications[id];
        if (!notification) return false;

        try {
            if (notification.actions) {
                for (let i = 0; i < notification.actions.length; i++) {
                    const action = notification.actions[i];
                    if (action && action.identifier === "default") {
                        action.invoke();
                        return true;
                    }
                }
            }
        } catch (e) {
        }
        return false;
    }

    function closeNotificationEverywhere(id) {
        closeLiveNotification(id);
        removeToastById(id);
        removeHistoryById(id);
    }

    function invokeDefault(id) {
        invokeDefaultAction(id);
        closeNotificationEverywhere(id);
    }

    // A click raises the app's window; the default action is only a fallback (it often opens
    // something unwanted, and niri ignores its activation).
    function activateNotification(id, appName, windowClass) {
        const match = (windowClass && windowClass.length > 0) ? windowClass : appName;
        const window = CompositorService.findWindow(match);
        if (window) {
            CompositorService.focusWindow(window.id);
            return true;
        }
        return invokeDefaultAction(id);
    }

    function focusAndDismiss(id, appName, windowClass) {
        activateNotification(id, appName, windowClass);
        closeNotificationEverywhere(id);
    }

    function focusAndDismissToast(index) {
        if (index < 0 || index >= toastModel.count) return;
        const item = toastModel.get(index);
        const ids = idsOf(item);
        activateNotification(item.notificationId, item.appName, item.windowClass);
        for (const id of ids) closeNotificationEverywhere(id);
    }

    function focusFromHistory(id, appName, index, windowClass) {
        if (activateNotification(id, appName, windowClass)) {
            closeNotificationEverywhere(id);
            return;
        }
        if (index !== undefined && index !== null) {
            dismissHistory(index);
        }
    }

    function removeToastById(id) {
        for (let i = toastModel.count - 1; i >= 0; i--) {
            if (toastModel.get(i).notificationId === id) {
                toastModel.remove(i);
            }
        }
    }

    function removeHistoryById(id) {
        for (let i = historyModel.count - 1; i >= 0; i--) {
            if (historyModel.get(i).notificationId === id) {
                historyModel.remove(i);
            }
        }
    }

    ListModel {
        id: toastModel
    }

    ListModel {
        id: historyModel
    }

    Component.onCompleted: {
        if (root.historyLifetimeMinutes > 0) {
            Quickshell.execDetached(["find", root.imageStateDir, "-maxdepth", "1", "-type", "f",
                "-mmin", "+" + root.historyLifetimeMinutes, "-delete"]);
        }
    }

    Timer {
        interval: root.expirySweepMs
        repeat: true
        running: root.historyLifetimeMinutes > 0
        onTriggered: root.expireHistory()
    }

    NotificationServer {
        id: server
        imageSupported: true
        actionsSupported: true
        bodyMarkupSupported: false
        persistenceSupported: false

        onNotification: notification => root.handleNotification(notification)
    }
}
