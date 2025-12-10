import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.tailscale
import qs.commonwidgets
ColumnLayout {
    Layout.fillWidth: true
    TailscaleOnOff {}
    ComponentSplitter{}
    TailscaleConnectedNetwork{}
    ComponentSplitter{}
    TailscalePeers{}
    ComponentSpacer{}
}
