import QtQuick
import QtQuick.Layouts
import qs.theme as T

// A section heading: a thin rule, then the name at row size in bold, so a page's groups -- the
// bar, the workspaces, the panels -- read as blocks of their own rather than a run of rows.
// `trailing` sits at the right ("scanning…"), and can be made a link.
Item {
    id: section

    property string text: ""
    property string trailing: ""
    property bool trailingClickable: false
    signal trailingClicked()

    Layout.fillWidth: true
    Layout.topMargin: 12
    Layout.bottomMargin: 2
    implicitHeight: rule.height + 8 + label.implicitHeight

    Rectangle {
        id: rule
        width: parent.width
        height: 1
        color: Readout.divider
    }

    Text {
        id: label
        x: 6
        y: rule.height + 8
        text: section.text
        color: Readout.value
        font.pixelSize: Readout.valueSize
        font.family: Readout.font
        font.bold: true
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: label.verticalCenter
        visible: text.length > 0
        text: section.trailing
        color: trailingMouse.containsMouse ? Readout.value : Readout.detail
        font.pixelSize: Readout.detailSize
        font.family: Readout.font
        MouseArea {
            id: trailingMouse
            anchors.fill: parent
            anchors.margins: -4
            enabled: section.trailingClickable
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: section.trailingClicked()
        }
    }
}
