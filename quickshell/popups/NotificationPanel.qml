import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.commonwidgets
import qs.services as S
import qs.theme as T

// Notifications in the Readout design: one row each -- the app's icon, the summary, how long ago
// -- with the body under only the newest (or any you click open). A click on the summary goes to
// the app; the status clears one on hover. Do-not-disturb is the header's switch.
HoverPopupWindow {
    id: panel

    popupWidth: 460

    // Which notifications have their body shown, by id, beyond the newest.
    property var expanded: ({})

    Component.onDestruction: S.PopupManager.unregister(panel)
    Component.onCompleted: S.PopupManager.register(panel, "notifications")

    onVisibleChanged: {
        if (visible) {
            S.PopupManager.closeOthers(panel);
            S.Notifications.markRead();
        } else {
            expanded = ({});
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    function iconSourceOf(icon) {
        const value = String(icon || "");
        if (value.length === 0) return "";
        if (value.startsWith("file:") || value.startsWith("http") || value.startsWith("data:") || value.startsWith("image:")) return value;
        if (value.startsWith("/")) return "file://" + value;
        return Quickshell.iconPath(value, true);
    }
    function ago(timestamp) {
        const minutes = Math.max(0, Math.round((clock.date.getTime() - timestamp) / 60000));
        if (minutes < 1) return "now";
        if (minutes < 60) return minutes + "m";
        return Math.round(minutes / 60) + "h";
    }
    function plain(text) {
        return String(text || "").replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim();
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Keys.onEscapePressed: panel.hidePanel()

        ReadoutHeader {
            title: "notifications"
            status: "do not disturb"
            active: S.Notifications.doNotDisturb
            hasSwitch: true
            checked: S.Notifications.doNotDisturb
            onToggled: S.Notifications.toggleDoNotDisturb()
        }

        ReadoutText {
            visible: S.Notifications.historyModel.count === 0
            text: S.Notifications.doNotDisturb ? "do not disturb is on" : "nothing new"
        }

        Flickable {
            visible: S.Notifications.historyModel.count > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(list.implicitHeight, 420)
            contentWidth: width
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: list
                width: parent.width
                spacing: 0

                Repeater {
                    model: S.Notifications.historyModel
                    delegate: ColumnLayout {
                        id: item
                        required property int index
                        required property int notificationId
                        required property string appName
                        required property string appIcon
                        required property string windowClass
                        required property string summary
                        required property string body
                        required property string image
                        required property int urgency
                        required property real timestamp
                        readonly property bool open: index === 0 || panel.expanded[notificationId] === true
                        readonly property string bodyText: panel.plain(body)
                        Layout.fillWidth: true
                        spacing: 0

                        ReadoutRow {
                            iconSource: panel.iconSourceOf(item.image.length > 0 ? item.image : item.appIcon)
                            icon: "󰂚"
                            value: item.summary.length > 0 ? item.summary : item.appName
                            detail: item.summary.length > 0 ? item.appName : ""
                            status: panel.ago(item.timestamp)
                            statusColor: item.urgency === 2 ? Readout.danger : Readout.detail
                            hoverStatus: "dismiss · right-click"
                            active: item.urgency === 2
                            onClicked: {
                                if (!item.open && item.bodyText.length > 0) {
                                    const next = Object.assign({}, panel.expanded);
                                    next[item.notificationId] = true;
                                    panel.expanded = next;
                                    return;
                                }
                                S.Notifications.focusFromHistory(item.notificationId, item.appName, item.index, item.windowClass);
                            }
                            onSecondaryClicked: S.Notifications.dismissHistory(item.index)
                        }
                        ReadoutText {
                            visible: item.open && item.bodyText.length > 0
                            Layout.leftMargin: Readout.iconColumn + 12
                            Layout.bottomMargin: 6
                            text: item.bodyText
                            maximumLineCount: 4
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        ReadoutDivider { visible: S.Notifications.historyModel.count > 0 }
        ReadoutRow {
            visible: S.Notifications.historyModel.count > 0
            icon: "󰎟"
            value: "clear all"
            onClicked: S.Notifications.clearHistory()
        }
    }
}
