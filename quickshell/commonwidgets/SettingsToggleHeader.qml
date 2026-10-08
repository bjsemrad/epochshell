import QtQuick
import QtQuick.Layouts
import qs.theme as T

// The top of a panel: its name, large and bold, with its on/off switch and its settings button at
// the right end. The header every panel with a switch uses -- Wi-Fi, Bluetooth, Ethernet,
// Tailscale, LocalSend -- so they all open the same way.
Item {
    Layout.fillWidth: true
    Layout.preferredHeight: T.Config.settingsHeaderHeight + 6
    Layout.topMargin: T.Config.layoutMarginSmall

    required property string headerText
    required property bool checkedValue
    property bool enableToggle: true
    // Whether there is a settings action to offer.
    property bool showSettings: true

    function handleToggled(checked) {
        console.log("Missing Implementation");
    }

    function settingsClick() {
        console.log("Missing Implementation");
    }

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: headerText
        color: T.Config.surfaceText
        font.pixelSize: T.Config.fontSizeLarge
        font.bold: true
    }

    RowLayout {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: T.Config.layoutMarginSmall

        RoundedSwitch {
            visible: enableToggle
            Layout.alignment: Qt.AlignVCenter
            checked: checkedValue
            onToggled: requested => handleToggled(requested)
        }

        IconButton {
            visible: showSettings
            icon: ""
            onClicked: settingsClick()
        }
    }
}
