import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.commonwidgets
import qs.services as S
import qs.theme as T

HoverPopupWindow {
    id: panel

    popupWidth: large ? Ui.notificationsLargeWidth : Ui.panelWidthWide

    property var expanded: ({})
    // The large view: wider, as tall as the screen allows, and every body in full. Kept across
    // closes for the session, so a shortcut reopens it the way it was left.
    property bool large: false
    readonly property real listMaxHeight: large && screen
        ? Math.max(Ui.panelListMaxHeight, screen.height - T.Config.barHeight - Ui.screenMarginV * 2)
        : Ui.panelListMaxHeight

    // Held open while the card resizes, like the dashboard's page change: the edge moving past the
    // pointer would otherwise read as leaving.
    function setLarge(value) {
        panel.stopHide = true;
        panel.large = value;
        sizeSettle.restart();
    }
    Timer {
        id: sizeSettle
        interval: Ui.pageSettleMs
        onTriggered: panel.stopHide = false
    }

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

        PageHeader {
            title: "notifications"
            actionIcon: panel.large ? "󰘕" : "󰘖"
            actionHint: panel.large ? "smaller" : "larger"
            onActionClicked: panel.setLarge(!panel.large)
            status: "do not disturb"
            active: S.Notifications.doNotDisturb
            hasSwitch: true
            checked: S.Notifications.doNotDisturb
            onToggled: S.Notifications.toggleDoNotDisturb()
        }

        Note {
            visible: S.Notifications.historyModel.count === 0
            text: S.Notifications.doNotDisturb ? "do not disturb is on" : "nothing new"
        }

        Flickable {
            visible: S.Notifications.historyModel.count > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(list.implicitHeight, panel.listMaxHeight)
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
                        required property int groupCount
                        // Read in full: clicked open, or the large view. The newest also shows a little more.
                        readonly property bool full: panel.large || panel.expanded[notificationId] === true
                        function focusApp() {
                            S.Notifications.focusFromHistory(item.notificationId, item.appName, item.index, item.windowClass);
                        }
                        readonly property string bodyText: panel.plain(body)
                        Layout.fillWidth: true
                        spacing: 0

                        ListRow {
                            iconSource: panel.iconSourceOf(item.image.length > 0 ? item.image : item.appIcon)
                            icon: "󰂚"
                            value: item.summary.length > 0 ? item.summary : item.appName
                            detail: (item.summary.length > 0 ? item.appName : "")
                                + (item.groupCount > 1 ? (item.summary.length > 0 ? " · " : "") + (item.groupCount - 1) + " more" : "")
                            status: panel.large ? Qt.formatTime(new Date(item.timestamp), "hh:mm") + " · " + panel.ago(item.timestamp)
                                : panel.ago(item.timestamp)
                            statusColor: item.urgency === 2 ? Ui.danger : Ui.detail
                            hoverStatus: "dismiss · right-click"
                            active: item.urgency === 2
                            // A click reads the message rather than leaving for the app; with nothing to
                            // read, it goes to the app. The link under an open message does that too.
                            onClicked: {
                                if (item.bodyText.length === 0) {
                                    item.focusApp();
                                    return;
                                }
                                if (panel.large) return;
                                const next = Object.assign({}, panel.expanded);
                                next[item.notificationId] = !item.full;
                                panel.expanded = next;
                            }
                            onSecondaryClicked: S.Notifications.dismissHistory(item.index)
                        }
                        // Every row previews its body; opening one (or the large view) shows more.
                        Note {
                            id: bodyNote
                            visible: item.bodyText.length > 0
                            Layout.leftMargin: Ui.iconColumn + Ui.space2XL
                            text: item.bodyText
                            Layout.bottomMargin: item.full ? 0 : Ui.spaceM
                            maximumLineCount: item.full ? 1000 : item.index === 0 ? Ui.notificationBodyLines : Ui.notificationPreviewLines
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: item.full && item.bodyText.length > 0
                            Layout.leftMargin: Ui.iconColumn + Ui.space2XL + Ui.spaceM
                            Layout.topMargin: Ui.spaceS
                            Layout.bottomMargin: Ui.spaceM
                            text: "open in " + (item.appName.length > 0 ? item.appName : "app") + " ›"
                            color: openMouse.containsMouse ? Ui.accent : Ui.detail
                            font.pixelSize: Ui.detailSize
                            font.family: Ui.font
                            MouseArea {
                                id: openMouse
                                anchors.fill: parent
                                anchors.margins: -Ui.hitSlop
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: item.focusApp()
                            }
                        }
                    }
                }
            }
        }

        Divider { visible: S.Notifications.historyModel.count > 0 }
        ListRow {
            visible: S.Notifications.historyModel.count > 0
            icon: "󰎟"
            value: "clear all"
            onClicked: S.Notifications.clearHistory()
        }
    }
}
