import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.theme as T
import qs.services as S
import qs.commonwidgets

SettingsToggleHeader {
    headerText: "Wifi"
    enableToggle: true
    checkedValue: true

    function settingsClick(){
        S.Network.editNetworks()
    }

    function handleToggled(checked){
       S.Network.disableWifi(checked)
    }
}
// Rectangle {
//     id: root
//     width: parent.width
//     height: 30
//     radius: 40
//     color: "transparent"
//
//     Rectangle {
//         anchors.fill: parent
//         width: parent.width
//         color: "transparent"
//
//         Column {
//             spacing: 20
//             anchors.verticalCenter: parent.verticalCenter
//             width: parent.width*.80
//             Text {
//                 text: "Wifi"
//                 color: T.Config.fg
//                 font.bold: true
//                 font.pointSize: 13
//             }
//         }
//
//         Column {
//             width: parent.width*.20
//             height: parent.height
//             anchors.right: parent.right
//             anchors.rightMargin: 10
//             spacing: 8
//             Row {
//                 spacing: 10
//                 anchors.right: parent.right
//                 anchors.left: parent.left
//                 width: parent.width
//                 height: parent.height
//
//
//                 RoundedSwitch{
//                     id: wifiSwitch
//                     anchors.verticalCenter: parent.verticalCenter
//                     checked: S.Network.wifiEnabled
//                     onToggled: {
//                         S.Network.disableWifi(wifiSwitch.checked)
//                     }
//                 }
//
//
//                 PanelHeaderIcon {
//                     id: networkSettings
//                     iconText: ""
//                     function onClick(){
//                         S.Network.editNetworks()
//                     }
//                 }
//
//             }
//         }
//      }
// }
