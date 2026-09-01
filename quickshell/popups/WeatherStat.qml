import QtQuick
import QtQuick.Layouts
import qs.theme as T

Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: 58
    radius: T.Config.cardRadius
    color: "transparent"

    required property string label
    required property string value

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 2

        Text {
            text: label
            color: T.Config.inactive
            font.pixelSize: T.Config.fontSizeSubtext
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: value || "--"
            color: T.Config.surfaceText
            font.pixelSize: T.Config.fontSizeNormal
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
