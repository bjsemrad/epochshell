import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.commonwidgets
import qs.services as S

// The devices sound can go to, or come from: click one to make it the default. The default is lit.
// AvailableAudioOutputs and AvailableAudioInputs say which kind, by `isAudioType`.
ColumnLayout {
    id: audioSection
    Layout.fillWidth: true
    spacing: 2

    // "Outputs" or "Inputs".
    required property string type
    required property PwNode defaultAudioNode

    function isAudioType(node) {
        console.log("ERROR Missing Implementations");
    }

    function clickOperation(nodeId) {
        S.AudioService.setDefault(nodeId);
    }

    SectionLabel {
        text: audioSection.type
    }

    Repeater {
        model: Pipewire.nodes

        delegate: ListRow {
            required property var modelData
            readonly property bool isDefault: modelData.id === audioSection.defaultAudioNode?.id

            visible: audioSection.isAudioType(modelData) && modelData.description
            icon: audioSection.type === "Inputs" ? "󰍬" : "󰓃"
            title: modelData.description || ""
            subtitle: isDefault ? "In use" : ""
            active: isDefault
            onClicked: audioSection.clickOperation(modelData.id)
        }
    }
}
