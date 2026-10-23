import QtQuick
import qs.commonwidgets
import Quickshell
import Quickshell.Wayland
import qs.services as S
import qs.theme as T

Scope {
    LazyLoader {
        active: S.OsdService.visible && !S.OsdService.inBar

        PanelWindow {
            screen: Quickshell.screens.find(s => s.name === S.OsdService.screenName) || Quickshell.screens[0]
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "epochshell-osd"
            anchors.top: true
            margins.top: S.OsdService.barReady[S.OsdService.screenName] === undefined ? Ui.osdTopNoBar : Ui.osdTopGap
            exclusiveZone: 0
            implicitWidth: Ui.osdWidth
            implicitHeight: Ui.osdHeight
            color: "transparent"
            mask: Region {}

            Rectangle {
                anchors.fill: parent
                radius: T.Config.popupRadius
                antialiasing: true
                color: T.Config.popupBackground
                border.width: 1
                border.color: T.Config.outline

                OsdDisplay {
                    anchors.fill: parent
                }
            }
        }
    }
}
