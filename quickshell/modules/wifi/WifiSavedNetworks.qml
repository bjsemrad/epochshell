import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.services as S

// The networks this machine already knows.
ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 2

    SectionLabel {
        text: "Saved networks"
    }

    Repeater {
        model: S.Network.savedAccessPoints
        delegate: WifiSavedNetworkRow {
            required property var model
            ssid: model.ssid
        }
    }
}
