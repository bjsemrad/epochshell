import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.commonwidgets
import qs.services as S
import qs.theme as T

// Networks in range, behind a section label that opens them: scanning is slow and the list long,
// and most of the time the network you want is already saved. Opening it starts a scan; closing
// the panel folds it away again.
ColumnLayout {
    id: networksSection
    Layout.fillWidth: true
    Layout.bottomMargin: T.Config.layoutMarginSmall
    spacing: 2

    property bool expanded: false
    required property var attachedPanel

    Connections {
        target: networksSection.attachedPanel
        function onVisibleChanged() {
            if (!networksSection.attachedPanel.visible)
                networksSection.expanded = false;
        }
    }

    // The label, which is also the way in.
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: headerRow.implicitHeight + T.Config.popupPadding
        radius: T.Config.cardRadius
        color: headerMouse.containsMouse && !networksSection.expanded ? T.Config.onPanel(T.Config.surfaceContainerHigh) : "transparent"

        RowLayout {
            id: headerRow
            anchors.fill: parent
            anchors.leftMargin: 2
            anchors.rightMargin: T.Config.popupPadding
            spacing: T.Config.layoutMarginSmall

            SectionLabel {
                Layout.topMargin: 0
                text: "Available networks"
            }

            Spinner {
                running: S.Network.wifiScanning
                visible: running
            }

            Text {
                visible: !networksSection.expanded
                text: ""
                color: T.Config.outline
                font.pixelSize: T.Config.fontSizeSubtext
                font.family: T.Config.fontFamily
            }
        }

        MouseArea {
            id: headerMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: !networksSection.expanded
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                S.Network.refreshAvailable();
                networksSection.expanded = true;
            }
        }
    }

    ListView {
        id: networkList
        visible: networksSection.expanded
        Layout.fillWidth: true
        Layout.preferredHeight: networksSection.expanded ? Math.min(contentHeight, 300) : 0
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: S.Network.accessPoints

        delegate: ListRow {
            required property var modelData
            width: ListView.view.width
            icon: {
                const s = modelData.strength;
                if (s >= 75) return "󰤨";
                if (s >= 50) return "󰤢";
                return "󰤟";
            }
            title: modelData.ssid
            active: modelData.active === true
            onClicked: S.Network.connectTo(modelData.ssid)
        }

        ScrollBar.vertical: ScrollBar {
            policy: networkList.contentHeight > 300 ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
        }
    }
}
