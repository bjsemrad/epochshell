import QtQuick
import QtQuick.Layouts
import qs.theme as T

// A labelled choice between a few named values, as a row of segments, the current one filled.
//
// Like SettingSlider, it reports a pick and leaves applying and saving it to its owner.
ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 4

    required property string label
    property string hint: ""
    // [{ value: "full", label: "Full" }, ...]
    required property var options
    required property string current

    signal picked(string value)

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Text {
            text: root.label
            color: T.Config.surfaceText
            font.pixelSize: T.Config.fontSizeNormal
            Layout.fillWidth: true
        }

        Text {
            visible: root.hint.length > 0
            text: root.hint
            color: T.Config.outline
            font.pixelSize: T.Config.fontSizeSubtext
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 32
        radius: T.Config.popupRadius
        antialiasing: true
        color: T.Config.surfaceContainer

        RowLayout {
            anchors.fill: parent
            anchors.margins: 3
            spacing: 3

            Repeater {
                model: root.options

                delegate: Rectangle {
                    id: segment
                    required property var modelData
                    readonly property bool selected: modelData.value === root.current

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: T.Config.popupRadius - 3
                    antialiasing: true
                    color: segment.selected ? T.Config.accent
                        : segmentMouse.containsMouse ? T.Config.surfaceContainerHigh : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: segment.modelData.label
                        color: segment.selected ? T.Config.background : T.Config.surfaceText
                        font.pixelSize: T.Config.fontSizeSubtext + 2
                        font.bold: segment.selected
                    }

                    MouseArea {
                        id: segmentMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (!segment.selected) root.picked(segment.modelData.value)
                    }
                }
            }
        }
    }
}
