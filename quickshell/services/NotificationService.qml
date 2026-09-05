pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property alias toastModel: toastModel
    property alias historyModel: historyModel
    property var liveNotifications: ({})
    property bool doNotDisturb: false
    property int unreadCount: 0
    readonly property int historyLimit: 30
    readonly property int normalTimeout: 3500
    readonly property int lowTimeout: 2000

    function snapshotOf(notification) {
        return {
            notificationId: notification.id || Date.now(),
            appName: String(notification.appName || ""),
            appIcon: String(notification.appIcon || ""),
            summary: String(notification.summary || ""),
            body: String(notification.body || ""),
            image: String(notification.image || ""),
            urgency: notification.urgency,
            timestamp: Date.now()
        };
    }

    function handleNotification(notification) {
        notification.tracked = true;

        const item = snapshotOf(notification);
        liveNotifications[item.notificationId] = notification;

        notification.closed.connect(function() {
            if (liveNotifications[item.notificationId] === notification) {
                delete liveNotifications[item.notificationId];
            }
        });

        addHistory(item);
        unreadCount += 1;

        if (!doNotDisturb) {
            toastModel.insert(0, item);
        }
    }

    function addHistory(item) {
        historyModel.insert(0, item);
        while (historyModel.count > historyLimit) {
            historyModel.remove(historyModel.count - 1);
        }
    }

    function dismissToast(index) {
        if (index < 0 || index >= toastModel.count) return;

        const item = toastModel.get(index);
        closeLiveNotification(item.notificationId);
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
        historyModel.clear();
        unreadCount = 0;
    }

    function dismissHistory(index) {
        if (index < 0 || index >= historyModel.count) return;

        const item = historyModel.get(index);
        closeLiveNotification(item.notificationId);
        removeToastById(item.notificationId);
        historyModel.remove(index);
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

    function invokeDefault(id) {
        const notification = liveNotifications[id];
        if (!notification) return;

        try {
            if (notification.actions) {
                for (let i = 0; i < notification.actions.length; i++) {
                    const action = notification.actions[i];
                    if (action && action.identifier === "default") {
                        action.invoke();
                        break;
                    }
                }
            }
        } catch (e) {
        }
        closeLiveNotification(id);
        removeToastById(id);
    }

    function removeToastById(id) {
        for (let i = toastModel.count - 1; i >= 0; i--) {
            if (toastModel.get(i).notificationId === id) {
                toastModel.remove(i);
            }
        }
    }

    ListModel {
        id: toastModel
    }

    ListModel {
        id: historyModel
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
