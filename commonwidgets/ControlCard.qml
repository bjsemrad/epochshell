import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

Rectangle {
    id: root
    property alias iconSource: icon.text
    property string title: ""
    property string subtitle: ""
    property bool accent: false

    radius: 18
    color: accent ? "#b388ff33" : "#151320"
    border.width: accent ? 0 : 1
    border.color: "#ffffff10"

    implicitWidth: 180
    implicitHeight: 70

    // Simple click handler you can hook into
    signal clicked()

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
        cursorShape: Qt.PointingHandCursor
        onEntered: root.color = accent ? "#b388ff55" : "#1b1926"
        onExited:  root.color = accent ? "#b388ff33" : "#151320"
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        Rectangle {
            id: iconBg
            width: 32
            height: 32
            radius: 999
            color: accent ? "#b388ff" : "#ffffff1a"
            Layout.alignment: Qt.AlignVCenter

            Text {
                id: icon
                anchors.centerIn: parent
                width: 18
                height: 18
                color: "white"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: root.title
                color: "white"
                font.pixelSize: 14
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                text: root.subtitle
                color: "#ffffffaa"
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }
}
