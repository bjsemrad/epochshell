import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.theme as T
import qs.services as S

Rectangle {
    id: root
    color: "transparent"
    implicitWidth: inner.implicitWidth + T.Config.widthPaddingLarge
    implicitHeight: inner.implicitHeight + T.Config.heightPaddingSmall
    visible: S.CompositorService.isHyprland

    property int focusedWsId: {
        const ws = Hyprland.focusedWorkspace;
        return (ws && ws.id !== undefined) ? ws.id : -1;
    }

    property int activeWsId: {
        const tl = Hyprland.activeToplevel;
        const w = tl ? tl.workspace : null;
        return (w && w.id !== undefined) ? w.id : -1;
    }
    Row {
        id: inner
        anchors.centerIn: parent
        height: parent.height
        spacing: 5
        Text {
            text: {
                if (!S.CompositorService.isHyprland)
                    return "";
                if (focusedWsId < 0 || activeWsId < 0)
                    return "";
                if (focusedWsId !== activeWsId)
                    return "";

                const tl = Hyprland.activeToplevel;
                return (tl && tl.title) ? tl.title : "";
            }
            font.pixelSize: T.Config.fontSizeNormal
            anchors.verticalCenter: parent.verticalCenter
            color: T.Config.surfaceText
        }
    }

    Component.onCompleted: {
        Hyprland.refreshToplevels();
    }
}
