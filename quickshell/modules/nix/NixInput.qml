import QtQuick
import qs.commonwidgets
import qs.services as S

// One flake input that can move, and where it would move to: its name, and the revision it is on
// against the one it could be on, in the shared row look. Information, not an action, so it is not
// lifted under the pointer.
ListRow {
    id: root
    required property string name
    required property string source
    required property string currentRev
    required property string latestRev

    icon: "󰏗"
    title: root.name
    subtitle: S.NixUpdates.shortRev(root.currentRev) + " → " + S.NixUpdates.shortRev(root.latestRev)
        + (root.source.length > 0 ? " · " + root.source : "")
    clickable: false
}
