import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.commonwidgets
import qs.services as S
import qs.theme as T

HoverPopupWindow {
    id: notificationPopup
    trigger: trigger
    popupWidth: T.Config.systemTrayPopupWidth + 120

    property int scrollBarPadding: 14

    onVisibleChanged: {
        if (visible) {
            S.PopupManager.closeOthers(notificationPopup);
            S.Notifications.markRead();
        }
    }

    Component.onDestruction: S.PopupManager.unregister(notificationPopup)
    Component.onCompleted: S.PopupManager.register(notificationPopup, "notifications")

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: T.Config.settingsHeaderHeight
        spacing: T.Config.layoutMarginSmall

        Text {
            text: "Notifications"
            color: T.Config.surfaceText
            font.pixelSize: T.Config.fontSizeLarge
            font.bold: true
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }

        // Do not disturb: the bell crossed out and lit in the accent while it is on.
        IconButton {
            icon: S.Notifications.doNotDisturb ? "󰂛" : "󰂚"
            iconColor: S.Notifications.doNotDisturb ? T.Config.accent : T.Config.surfaceText
            onClicked: S.Notifications.toggleDoNotDisturb()
        }

        PanelHeaderIcon {
            iconText: "󰎟"
            function onClick() {
                S.Notifications.clearHistory();
            }
        }
    }

    ComponentSplitter {}

    // Nothing here: said quietly, with the bell, in the middle.
    ColumnLayout {
        visible: S.Notifications.historyModel.count === 0
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: T.Config.popupPadding * 2
        Layout.bottomMargin: T.Config.popupPadding * 2
        spacing: 4

        Text {
            text: S.Notifications.doNotDisturb ? "󰂛" : "󰂚"
            color: T.Config.outline
            font.pixelSize: T.Config.fontSizeXLarge
            font.family: T.Config.fontFamily
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: S.Notifications.doNotDisturb ? "Do not disturb is on" : "No notifications"
            color: T.Config.inactive
            font.pixelSize: T.Config.fontSizeNormal
            Layout.alignment: Qt.AlignHCenter
        }
    }

    ListView {
        id: notificationList
        visible: S.Notifications.historyModel.count > 0
        Layout.fillWidth: true
        implicitHeight: Math.min(contentHeight, Screen.height * 0.75)
        clip: true
        model: S.Notifications.historyModel
        spacing: T.Config.popupLayoutSpacing
        boundsBehavior: Flickable.StopAtBounds

        footer: Item {
            width: notificationList.width
            height: T.Config.popupPadding * 2
        }

        delegate: Item {
            id: historySlot
            required property int notificationId
            required property string appName
            required property string appIcon
            required property string windowClass
            required property string summary
            required property string body
            required property string image
            required property int urgency
            required property int index

            width: notificationList.width - notificationPopup.scrollBarPadding
            height: card.implicitHeight

            NotificationCard {
                id: card
                width: parent.width
                appName: historySlot.appName
                appIcon: historySlot.appIcon
                summary: historySlot.summary
                body: historySlot.body
                image: historySlot.image
                urgency: historySlot.urgency
                embedded: true
                closeVisible: true
                onClicked: S.Notifications.focusFromHistory(historySlot.notificationId, historySlot.appName, historySlot.index, historySlot.windowClass)
                onDismissRequested: S.Notifications.dismissHistory(historySlot.index)
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: notificationList.contentHeight > notificationList.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
            contentItem: Rectangle {
                implicitWidth: 3
                radius: 3
                antialiasing: true
                color: T.Config.surfaceText
            }
        }
    }

    ComponentSpacer { bottomMargin: 6 }
}
