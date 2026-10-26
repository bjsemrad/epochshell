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
            margins.top: S.OsdService.bar === null ? Ui.osdTopNoBar : Ui.osdTopGap
            exclusiveZone: 0
            implicitWidth: Ui.osdWidth
            implicitHeight: Ui.osdHeight
            color: "transparent"
            mask: Region {}
            BackgroundEffect.blurRegion: T.Config.popupBlur ? osdBlur : null
            Region {
                id: osdBlur
                item: osdBody
                radius: T.Config.popupRadius
            }

            Rectangle {
                id: osdBody
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
