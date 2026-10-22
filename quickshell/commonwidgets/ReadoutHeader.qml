import QtQuick
import QtQuick.Layouts
import qs.theme as T

// The first row of a page: ‹ back (when the page was opened from the dashboard) · title · status
// · the page's main switch (Wi-Fi, Bluetooth, do-not-disturb...) when it has one. The status is
// information, or -- `switchable` -- a link ("today", "refresh"); never "on" or "off".
Item {
    id: header

    property bool showBack: false
    property string title: ""
    property string status: ""
    property bool active: false
    // Whether the status is a link.
    property bool switchable: false
    property bool hasSwitch: false
    property bool checked: false
    signal back()
    signal statusClicked()
    signal toggled()

    Layout.fillWidth: true
    implicitHeight: Readout.rowHeight + 4

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
                color: backMouse.containsMouse ? Readout.value : Readout.detail
                font.pixelSize: Readout.chevronSize
                font.family: Readout.font
            }
        }

        Text {
            id: titleText
            Layout.fillWidth: true
            text: header.title
            color: backMouse.containsMouse ? Readout.accent : Readout.value
            font.pixelSize: Readout.valueSize
            font.family: Readout.font
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            visible: text.length > 0
            text: header.status
            color: statusMouse.containsMouse ? Readout.value : header.active ? Readout.accent : Readout.detail
            font.pixelSize: Readout.detailSize
            font.family: Readout.font
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

        ReadoutSwitch {
            visible: header.hasSwitch
            Layout.alignment: Qt.AlignVCenter
            checked: header.checked
            onToggled: header.toggled()
        }
    }

    // Back: the arrow and the title together, "‹ wi-fi" as one target, from the header's left
    // edge to the end of the title's text.
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
