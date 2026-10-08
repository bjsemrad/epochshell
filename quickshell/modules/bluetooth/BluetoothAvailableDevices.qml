import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.commonwidgets
import qs.services as S
import qs.theme as T

// Devices in range, found by scanning. The scan is started and stopped from the label's right
// end; the list opens with the first scan and folds away, scan stopped, when the panel closes.
ColumnLayout {
    id: bluetoothSection
    Layout.fillWidth: true
    Layout.bottomMargin: T.Config.layoutMarginSmall
    spacing: 2

    property bool expanded: false

    onVisibleChanged: {
        bluetoothSection.expanded = false;
        S.Bluetooth.stopScan();
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: T.Config.layoutMarginSmall

        SectionLabel {
            text: "Available devices"
        }

        Spinner {
            Layout.topMargin: T.Config.layoutMarginSmall
            running: S.Bluetooth.discovering
            visible: running
        }

        // Start or stop a scan.
        IconButton {
            Layout.topMargin: T.Config.layoutMarginSmall
            icon: S.Bluetooth.discovering ? "󰓛" : "󰑐"
            iconColor: S.Bluetooth.discovering ? T.Config.accent : T.Config.surfaceText
            onClicked: {
                if (!S.Bluetooth.adapter) return;
                if (S.Bluetooth.discovering) {
                    S.Bluetooth.stopScan();
                } else {
                    S.Bluetooth.scanForDevices();
                    bluetoothSection.expanded = true;
                }
            }
        }
    }

    ListView {
        id: bluetoothList
        visible: bluetoothSection.expanded
        Layout.fillWidth: true
        Layout.preferredHeight: bluetoothSection.expanded ? Math.min(contentHeight, 300) : 0
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: S.Bluetooth.devices

        delegate: ListRow {
            required property var modelData
            width: ListView.view.width
            icon: S.Bluetooth.getDeviceIcon(modelData)
            title: modelData.name
            subtitle: "Click to pair"
            clickable: !S.Bluetooth.discovering
            onClicked: {
                modelData.trusted = true;
                modelData.connect();
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: bluetoothList.contentHeight > 300 ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
        }
    }
}
