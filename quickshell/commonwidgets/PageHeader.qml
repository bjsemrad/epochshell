import QtQuick
import QtQuick.Layouts
import qs.theme as T

Item {
    id: header

    property bool showBack: false
    property string title: ""
    property string status: ""
    property bool active: false
    property bool switchable: false
    property bool hasSwitch: false
    property bool checked: false
    signal back()
    signal statusClicked()
    signal toggled()

    Layout.fillWidth: true
    implicitHeight: Ui.rowHeight + 4

    RowLayout {
        id: line
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 8

        Item {
            id: backArrow
            visible: header.showBack
            Layout.preferredWidth: 22
            Layout.fillHeight: true
            Text {
                anchors.centerIn: parent
                text: "‹"
                color: backMouse.containsMouse ? Ui.value : Ui.detail
                font.pixelSize: Ui.chevronSize
                font.family: Ui.font
            }
        }

        Text {
            id: titleText
            Layout.fillWidth: true
            text: header.title
            color: backMouse.containsMouse ? Ui.accent : Ui.value
            font.pixelSize: Ui.valueSize
            font.family: Ui.font
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            visible: text.length > 0
            text: header.status
            color: statusMouse.containsMouse ? Ui.value : header.active ? Ui.accent : Ui.detail
            font.pixelSize: Ui.detailSize
            font.family: Ui.font
            MouseArea {
                id: statusMouse
                anchors.fill: parent
                anchors.margins: -6
                enabled: header.switchable
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: header.statusClicked()
            }
        }

        ToggleSwitch {
            visible: header.hasSwitch
            Layout.alignment: Qt.AlignVCenter
            checked: header.checked
            onToggled: header.toggled()
        }
    }

    MouseArea {
        id: backMouse
        enabled: header.showBack
        visible: enabled
        x: 0
        width: line.x + titleText.x + Math.min(titleText.implicitWidth, titleText.width) + 8
        height: parent.height
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: header.back()
    }
}
