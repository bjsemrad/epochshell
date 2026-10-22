import QtQuick
import QtQuick.Layouts
import qs.theme as T

// A key row: the key in its column, then whatever the row holds -- text, a choice, a gauge, a
// stepper -- packed to the left straight after it, so a page of key rows reads as a table, every
// value starting at the same edge. A spec sheet, one fact per line.
Item {
    id: row

    property string key: ""
    // Plain text in place of content, for the common case.
    property string text: ""
    property color textColor: Readout.value
    default property alias content: slot.data

    Layout.fillWidth: true
    implicitHeight: Readout.rowHeight

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 0

        Text {
            Layout.preferredWidth: Readout.keyColumn
            text: row.key
            color: Readout.key
            // The size of what it labels, only dimmer: smaller, the keys read as footnotes.
            font.pixelSize: Readout.valueSize
            font.family: Readout.font
            elide: Text.ElideRight
        }

        Text {
            visible: row.text.length > 0
            Layout.fillWidth: true
            text: row.text
            color: row.textColor
            font.pixelSize: Readout.valueSize
            font.family: Readout.font
            elide: Text.ElideRight
        }

        // Only as wide as what it holds; the space left over goes after it, not around it.
        RowLayout {
            id: slot
            spacing: 8
        }

        Item {
            visible: row.text.length === 0
            Layout.fillWidth: true
        }
    }
}
