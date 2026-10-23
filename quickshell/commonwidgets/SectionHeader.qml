import QtQuick
import QtQuick.Layouts
import qs.theme as T

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
        color: Ui.divider
    }

    Text {
        id: label
        x: 6
        y: rule.height + 8
        text: section.text
        color: Ui.value
        font.pixelSize: Ui.valueSize
        font.family: Ui.font
        font.bold: true
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: label.verticalCenter
        visible: text.length > 0
        text: section.trailing
        color: trailingMouse.containsMouse ? Ui.value : Ui.detail
        font.pixelSize: Ui.detailSize
        font.family: Ui.font
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
