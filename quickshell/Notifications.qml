import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.commonwidgets
import qs.services as S
import qs.theme as T

Scope {
    readonly property string focusedName: {
        const focused = S.CompositorService.monitors.find(m => m.focused === true);
        if (focused) return String(focused.name);
        return Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "";
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: popupWindow
            required property var modelData
            screen: modelData
            visible: S.Notifications.toastModel.count > 0 && modelData.name === focusedName
            color: "transparent"
            exclusiveZone: 0

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            mask: Region {
                item: toastColumn
            }
            BackgroundEffect.blurRegion: T.Config.popupBlur ? toastBlur : null
            Region {
                id: toastBlur
                regions: {
                    const shapes = [];
                    for (let i = 0; i < toastRepeater.count; i++) {
                        const slot = toastRepeater.itemAt(i);
                        if (slot) shapes.push(slot.blurShape);
                    }
                    return shapes;
                }
            }

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            ColumnLayout {
                id: toastColumn
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: T.Config.barBottom + T.Config.popupPadding
                    rightMargin: T.Config.popupPadding * 2
                }
                spacing: T.Config.popupLayoutSpacing

                Repeater {
                    id: toastRepeater
                    model: S.Notifications.toastModel

                    delegate: Item {
                        id: slot
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
                        required property string actions
                        required property int groupCount
                        required property int serial

                        Layout.preferredWidth: card.implicitWidth
                        implicitHeight: card.implicitHeight

                        property bool hovered: false
                        readonly property Region blurShape: Region {
                            item: card
                            radius: T.Config.popupRadius
                        }

                        Timer {
                            id: expiry
                            interval: S.Notifications.timeoutFor(slot.urgency)
                            running: interval > 0 && !slot.hovered
                            repeat: false
                            onTriggered: S.Notifications.expireToast(slot.index)
                        }
                        onSerialChanged: if (expiry.running) expiry.restart()

                        HoverHandler {
                            onHoveredChanged: slot.hovered = hovered
                        }

                        NotificationCard {
                            id: card
                            appName: slot.appName
                            appIcon: slot.appIcon
                            summary: slot.summary
                            body: slot.body
                            image: slot.image
                            urgency: slot.urgency
                            timestamp: slot.timestamp
                            count: slot.groupCount
                            actions: {
                                try {
                                    return JSON.parse(slot.actions || "[]");
                                } catch (e) {
                                    return [];
                                }
                            }
                            onDismissRequested: S.Notifications.dismissToast(slot.index)
                            onClicked: S.Notifications.focusAndDismissToast(slot.index)
                            onActionInvoked: actionId => S.Notifications.invokeAction(slot.notificationId, actionId)
                            onHistoryRequested: S.PopupManager.openPanel("notifications")
                        }
                    }
                }
            }
        }
    }
}
