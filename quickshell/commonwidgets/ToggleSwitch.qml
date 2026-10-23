import QtQuick
import qs.theme as T

Item {
    id: control

    property bool checked: false
    signal toggled()

    implicitWidth: Ui.switchWidth
    implicitHeight: Ui.switchHeight

    Rectangle {
        anchors.fill: parent
        radius: Ui.switchRadius
        color: control.checked ? T.Config.accent : Ui.alpha(T.Config.surfaceText, Ui.switchOffAlpha)

        Rectangle {
            x: control.checked ? parent.width - width - Ui.switchKnobInset : Ui.switchKnobInset
            anchors.verticalCenter: parent.verticalCenter
            width: Ui.switchKnob
            height: Ui.switchKnob
            radius: Ui.switchKnobRadius
            color: control.checked ? T.Config.background : Ui.alpha(T.Config.surfaceText, Ui.switchKnobOffAlpha)
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -Ui.hitSlop
        cursorShape: Qt.PointingHandCursor
        onClicked: control.toggled()
    }
}
