import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.theme as T
import qs.services as S
import qs.commonwidgets

Rectangle {
    id: root
    width: parent.width
    radius: 8
    color: "transparent"
    implicitHeight: column.implicitHeight + 8

    property string pendingSsid: ""
    property int pendingIndex: -1

    Column {
        id: column
        anchors.fill: parent
        spacing: 10

        Text {
            text: "Saved Networks"
            color: T.Config.fg
            font.pixelSize: 13
            Layout.leftMargin: 4
        }

        Repeater {
            model: S.Network.savedAccessPoints

            delegate: WifiSavedNetworkRow {
                width: root.width
                ssid: model.ssid
            }
        }

     }
}
