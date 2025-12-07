import Quickshell
import Quickshell.Wayland
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
    popupWidth: T.Config.tailscalePopupWidth

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

       // width: T.Config.tailscalePopupWidth
    // RowLayout {
         // Layout.fillWidth: true

  //      height: inner.implicitHeight
        // ColumnLayout {
            // id: inner
            // Layout.fillWidth: true
            // Layout.leftMargin: 10
            // Layout.rightMargin: 10
            // spacing: 10
            // children: [
                TailscaleOnOff {}
                ComponentSplitter{}
                TailscaleConnectedNetwork{}
                ComponentSplitter{}
                TailscalePeers{}
                ComponentSpacer{}
          //  ]
        //}
    // }
}

