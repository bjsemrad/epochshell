import QtQuick
import qs.theme as T

// An action in a panel's list -- "Region", "Focused window", "Start recording" -- as a ListRow:
// the shared row look, lifted under the pointer. Kept under its old name and with its old
// `icon` / `description` / `onClick()` shape, which the capture and record panels speak.
ListRow {
    id: action
    title: description

    required property string description

    function onClick() {
        console.log("Implementation Missing");
    }

    onClicked: action.onClick()
}
