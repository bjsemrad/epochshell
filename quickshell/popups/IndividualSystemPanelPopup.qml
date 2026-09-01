import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets
import qs.commonwidgets
import qs.modules.overview as O
import qs.services as S
import qs.theme as T

HoverPopupWindow {
    id: popup
    trigger: trigger
    color: "transparent"
    popupWidth: T.Config.controlCenterPopupWidth - 50
    bottomPadding: 5

    property string username

    function showPanel() {
        open = true;
        visible = true;
    }

    function hidePanel() {
        if (!stopHide) {
            open = false;
            visible = false;
            popupHover = false;
        }
    }

    Component.onCompleted: {
        if (!username) {
            whoami.running = true;
        }
        S.PopupManager.register(popup);
        hidePanel();
    }

    onOpenChanged: {
        if (open) {
            S.PopupManager.closeOthers(popup);
        }
    }

    onVisibleChanged: {
        if (visible) {
            S.PopupManager.closeOthers(popup);
        }
    }

    Process {
        id: whoami
        command: ["whoami"]
        running: true

        stdout: SplitParser {
            onRead: data => username = data.trim()
        }
    }

    SystemClock {
        id: sysclk
        precision: SystemClock.Seconds
    }

    ClippingRectangle {
        id: content
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: 10
        Layout.bottomMargin: 10

        Layout.preferredHeight: flick.implicitHeight
        color: T.Config.background

        HoverHandler {
            onHoveredChanged: {
                if (!stopHide && !hovered) {
                    hidePanel();
                }
            }
        }

        Flickable {
            id: flick
            anchors.fill: parent

            contentWidth: width
            contentHeight: col.height

            implicitHeight: Math.min(contentHeight + 10, Screen.height - (Screen.height / 15))
            implicitWidth: popupWidth + 10

            clip: true

            ColumnLayout {
                id: col
                width: flick.width
                anchors.margins: 10
                spacing: 20

                O.User {}

                O.UtilsSystemTray {
                    panelRef: popup
                }

                // O.Stats {
                //     Layout.fillWidth: true
                //     container: popup
                // }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                opacity: flick.moving ? 1 : 0.0

                contentItem: Rectangle {
                    implicitWidth: 3
                    radius: 3
                    color: T.Config.surfaceText
                }
            }
        }
    }
}
