import QtQuick
import QtQuick.Layouts
import qs.services as S
import qs.theme as T

// Bar entry shown only while something is recording.
//
// It sits just left of the status icons, outside the drawer, so it is always in reach: a recording
// nobody can see is a recording that runs until the disk fills. The dot pulses and the elapsed time
// counts up; under the pointer they become a stop square and "Stop", so what a click will do is
// said before it is done -- stopping is the one thing anyone wants from this widget.
Rectangle {
    id: root
    visible: S.Capture.recording
    color: mouseArea.containsMouse ? T.Config.onBar(T.Config.surfaceContainer) : "transparent"
    radius: T.Config.popupRadius
    antialiasing: true
    border.width: 1
    border.color: "transparent"
    implicitWidth: contents.implicitWidth + T.Config.barModuleHorizontalPadding
    implicitHeight: contents.implicitHeight + T.Config.barModuleVerticalPadding

    RowLayout {
        id: contents
        anchors.centerIn: parent
        spacing: T.Config.barIconTextSpacing

        Text {
            id: dot
            text: mouseArea.containsMouse ? "󰓛" : "󰑊"
            font.pixelSize: T.Config.barIconSize
            font.family: T.Config.fontFamily
            color: T.Config.red
            Layout.alignment: Qt.AlignVCenter

            SequentialAnimation on opacity {
                running: S.Capture.recording && !mouseArea.containsMouse
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 0.35; duration: 700; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 0.35; to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
            }
        }

        Text {
            text: mouseArea.containsMouse ? "Stop" : S.Capture.recordingElapsed
            font.pixelSize: T.Config.fontSizeNormal
            font.family: T.Config.fontFamily
            color: T.Config.surfaceText
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        // The pulse stops under the pointer; the stop square shows at full strength, not wherever
        // the pulse happened to be.
        onEntered: dot.opacity = 1
        onClicked: S.Capture.stopRecording()
    }
}
