import QtQuick
import QtQuick.Layouts
import qs.theme as T

Item {
    id: row

    property string key: ""
    property bool toggles: false
    signal toggled()
    property string text: ""
    property color textColor: Ui.value
    default property alias content: slot.data

    Layout.fillWidth: true
    implicitHeight: Ui.rowHeight

    MouseArea {
        anchors.fill: parent
        enabled: row.toggles
        cursorShape: Qt.PointingHandCursor
        onClicked: row.toggled()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 0

        Text {
            Layout.preferredWidth: Ui.keyColumn
            text: row.key
            color: Ui.key
            font.pixelSize: Ui.valueSize
            font.family: Ui.font
            elide: Text.ElideRight
        }

        Text {
            visible: row.text.length > 0
            Layout.fillWidth: true
            text: row.text
            color: row.textColor
            font.pixelSize: Ui.valueSize
            font.family: Ui.font
            elide: Text.ElideRight
        }

        RowLayout {
            id: slot
            spacing: 8
        }

        Item {
            visible: row.text.length === 0
            Layout.fillWidth: true
        }
    }
}
