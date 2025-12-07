import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import qs.commonwidgets
import qs.modules
import qs.modules.ethernet
import qs.theme as T
import qs.services as S

HoverPopupWindow {
    id: networkPopup
    trigger: trigger
    
    function refresh() {
        S.Network.refresh()
    }

    Timer {
        id: refreshTimer
        interval: 5000  
        repeat: true
        running: networkPopup.visible

        onTriggered: {
            refresh()
        }
    }

    onVisibleChanged: {
        if (visible) {
            refresh()
            S.PopupManager.closeOthers(networkPopup)
        }
    }

    Component.onCompleted: {
        S.PopupManager.register(networkPopup)
    }


    
    RowLayout {
        width: T.Config.networkPopupWidth
        height: inner.implicitHeight
        ColumnLayout {
            id: inner
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            spacing: 10
            children: [ 
                EthernetHeader {},
                ComponentSplitter{},
                EthernetConnectedNetwork{},
                ComponentSpacer{},
            ]
        }
    }
}

