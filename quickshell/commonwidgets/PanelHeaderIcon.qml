import QtQuick
import QtQuick.Layouts
import qs.theme as T

// A header's icon button, in the shared IconButton look. Kept under its old name and with its old
// `iconText` / `onClick()` shape, which the panels already speak.
IconButton {
    id: panelHeaderIcon
    Layout.alignment: Qt.AlignVCenter
    icon: iconText

    required property string iconText

    function onClick() {
        console.log("Implementation missing");
    }

    onClicked: panelHeaderIcon.onClick()
}
