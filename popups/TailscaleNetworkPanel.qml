import Quickshell
import Quickshell.Wayland        // for WlrLayershell + WlrLayer
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import qs.commonwidgets
import qs.modules
import qs.modules.tailscale
import qs.theme as T
import qs.services as S

HoverPopupWindow {
    id: tailscalePopup
    trigger: trigger
    
    function refresh() {
        S.Tailscale.refresh()
    }

    onVisibleChanged: {
        if (visible) {
            refresh()
            S.PopupManager.closeOthers(tailscalePopup)
        }
    }

    Component.onCompleted: {
        S.PopupManager.register(tailscalePopup)
    }

    Column {
        width: T.Config.tailscalePopupWidth
        spacing: 10
        TailscaleOnOff {}
        ComponentSplitter{}
        TailscaleConnectedNetwork{}
        ComponentSplitter{}
        TailscalePeers{}
        ComponentSpacer{}
    }
}

