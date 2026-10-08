import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.services as S

// The devices this machine already knows.
ColumnLayout {
    Layout.fillWidth: true
    spacing: 2

    SectionLabel {
        text: "Paired devices"
    }

    Repeater {
        model: S.Bluetooth.pairedDevices
        delegate: BluetoothPairedRow {
            required property var modelData
            device: modelData
        }
    }
}
