import QtQuick
import QtQuick.Layouts
import qs.theme as T

// The name of a section within a panel -- "Saved networks", "Paired devices" -- small and quiet,
// so it groups what follows without competing with the panel's own title.
Text {
    Layout.fillWidth: true
    Layout.topMargin: T.Config.layoutMarginSmall
    color: T.Config.outline
    font.pixelSize: T.Config.fontSizeSubtext
    font.bold: true
    elide: Text.ElideRight
}
