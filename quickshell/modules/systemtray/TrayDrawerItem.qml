import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.theme as T

Rectangle {
    id: root

    required property var trayItem
    property string iconSource: {
        let icon = trayItem && trayItem.icon;
        if (typeof icon === 'string' || icon instanceof String) {
            if (icon === "") return "";
            if (icon.includes("?path=")) {
                const split = icon.split("?path=");
                if (split.length !== 2) return icon;
                const name = split[0];
                const path = split[1];
                let fileName = name.substring(name.lastIndexOf("/") + 1);
                return `file://${path}/${fileName}`;
            }
            if (icon.startsWith("/") && !icon.startsWith("file://")) {
                return `file://${icon}`;
            }
            return icon;
        }
        return "";
    }

    implicitWidth: T.Config.barIconSize + T.Config.barModuleHorizontalPadding
    implicitHeight: T.Config.barIconSize + T.Config.barModuleVerticalPadding
    color: mouseArea.containsMouse ? T.Config.surfaceContainer : "transparent"
    radius: T.Config.popupRadius

    QsMenuAnchor {
        id: menu
        menu: root.trayItem ? root.trayItem.menu : null
        anchor {
            item: iconImg
            edges: Edges.Left | Edges.Bottom
            gravity: Edges.Right | Edges.Bottom
            adjustment: PopupAdjustment.FlipX
        }
    }

    IconImage {
        id: iconImg
        width: T.Config.barIconSize
        height: T.Config.barIconSize
        anchors.centerIn: parent
        source: root.iconSource
        asynchronous: true
        smooth: true
        mipmap: true
        visible: status === Image.Ready
    }

    Text {
        visible: !iconImg.visible
        text: {
            const itemId = root.trayItem?.id || "";
            if (!itemId) return "?";
            return itemId.charAt(0).toUpperCase();
        }
        font.pixelSize: T.Config.barIconSize * 0.6
        font.family: T.Config.fontFamily
        anchors.centerIn: parent
        color: T.Config.surfaceText
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton && !root.trayItem.onlyMenu) {
                root.trayItem.activate();
                return;
            }
            if (mouse.button === Qt.RightButton && !root.trayItem.onlyMenu) {
                menu.open();
                return;
            }
        }
    }
}
