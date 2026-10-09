import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.commonwidgets
import qs.services as S
import qs.theme as T

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: popupWindow
            required property var modelData
            screen: modelData
            visible: S.Notifications.toastModel.count > 0
            color: "transparent"
            exclusiveZone: 0

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            // Input only where the toasts are. The window spans the screen so the column can sit
            // anywhere in it; without this, everything under it -- every window -- stopped taking
            // clicks for as long as a toast was up.
            mask: Region {
                item: toastColumn
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

                        Layout.preferredWidth: card.implicitWidth
                        implicitHeight: card.implicitHeight

                        property bool hovered: false

                        Timer {
                            interval: S.Notifications.timeoutFor(slot.urgency)
                            running: interval > 0 && !slot.hovered
                            repeat: false
                            onTriggered: S.Notifications.expireToast(slot.index)
                        }

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
                            onDismissRequested: S.Notifications.dismissToast(slot.index)
                            onClicked: S.Notifications.focusAndDismiss(slot.notificationId, slot.appName, slot.windowClass)
                        }
                    }
                }
            }
        }
    }
}
