import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.theme as T
import qs.services as S
import qs.commonwidgets

Item {
    Layout.fillWidth: true
    Layout.preferredHeight: T.Config.settingsHeaderHeight
    Layout.topMargin: T.Config.layoutMarginSmall

    required property string headerText
    required property bool checkedValue
    property bool enableToggle: true

    function handleToggled(checked) {
        console.log("Missing Implementation");
    }

    function settingsClick() {
        console.log("Missing Implementation");
    }

    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        height: T.Config.settingsHeaderHeight
        color: "transparent"

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: headerText
            color: T.Config.surfaceText
            font.bold: true
            font.pointSize: T.Config.fontSizeNormal
        }
    }

    RowLayout {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: T.Config.settingsHeaderSpacing
        RoundedSwitch {
            id: rSwitch
            visible: enableToggle
            Layout.alignment: Qt.AlignVCenter
            checked: checkedValue
            onToggled: {
                handleToggled(rSwitch.checked);
            }
        }
        PanelHeaderIcon {
            id: settings
            iconText: ""
            function onClick() {
                settingsClick();
            }
        }
    }
}
