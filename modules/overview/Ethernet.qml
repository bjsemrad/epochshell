import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.ethernet
import qs.commonwidgets
ColumnLayout {
    Layout.fillWidth: true
    EthernetHeader {}
    ComponentSplitter{}
    EthernetConnectedNetwork{}
    ComponentSpacer{}
}
