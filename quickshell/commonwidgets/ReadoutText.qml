import QtQuick
import QtQuick.Layouts

// A line of dim text in a panel: a status, a reason, an empty list's "nothing here".
Text {
    Layout.fillWidth: true
    Layout.leftMargin: 6
    Layout.rightMargin: 6
    Layout.topMargin: 2
    Layout.bottomMargin: 2
    color: Readout.detail
    font.pixelSize: Readout.detailSize
    font.family: Readout.font
    wrapMode: Text.Wrap
}
