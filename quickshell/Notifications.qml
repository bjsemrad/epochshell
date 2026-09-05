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
                    topMargin: T.Config.barHeight + T.Config.popupPadding
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
                            onClicked: S.Notifications.invokeDefault(slot.notificationId)
                        }
                    }
                }
            }
        }
    }
}
