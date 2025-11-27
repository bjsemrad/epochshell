import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../services" as S

Rectangle {
    id: root
    width: parent.width
    radius: 8
    color: "transparent"

    // // model of saved wifi connections (those with a profile in NM)
    // ListModel {
    //     id: savedWifiModel
    // }

    Component.onCompleted: S.NetworkMonitor.refreshSavedNetworks()

    // // grab saved connections once at startup
    // // you can re-run this on a timer if you want it to refresh
    // Process {
    //     id: nmcliSaved
    //     running: true
    //     // -t: terse, -f: fields we care about
    //     // we only keep entries where TYPE == wifi
    //     command: [ "sh", "-c", "nmcli -t -f NAME,TYPE connection show" ]
    //
    //     stdout: SplitParser {
    //         onRead: line => {
    //             if (!line.length)
    //                 return;
    //
    //             const parts = line.split(":");
    //             if (parts.length < 2)
    //                 return;
    //
    //             const name = parts[0];
    //             const type = parts[1];
    //             if (type.indexOf("wireless") !== -1) {
    //                 for (let i = 0; i < savedWifiModel.count; ++i) {
    //                     if (savedWifiModel.get(i).ssid === name)
    //                         return;
    //                     }
    //                     // if (S.NetworkMonitor.ssid !== name) {
    //                         savedWifiModel.append({ ssid: name });
    //                     // }
    //             }
    //         }
    //     }
    // }

    implicitHeight: column.implicitHeight + 8

    Column {
        id: column
        anchors.fill: parent
        anchors.margins: 4
        spacing: 10

        Text {
            text: "Saved Networks"
            color: "#a0a0a0"
            font.pixelSize: 11
            Layout.leftMargin: 4
        }

        Repeater {
            model: S.NetworkMonitor.savedAccessPoints

            delegate: NetworkRow {
                width: root.width
                ssid: model.ssid
            }
        }
    }
}
