// modules/Workspaces.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import "../theme" as T

Row {
    id: workspaces
    spacing: 6
    anchors.verticalCenter: parent.verticalCenter

    Repeater {
        model: Hyprland.workspaces.values

        delegate: WrapperMouseArea {
            required property var modelData   // workspace object from hyprland
            readonly property int wsId: modelData.id

            implicitWidth: 30
            implicitHeight: 22

            readonly property bool active: (
                Hyprland.focusedWorkspace
                && Hyprland.focusedWorkspace.id === wsId
            )

            onPressed: Hyprland.dispatch(`workspace ${wsId}`)

            Rectangle {
                anchors.fill: parent
                // radius: height / 2
                // border.width: 1
                // border.color: "#555"
                color: T.Config.bg //"#000000"//active ? "#FFFFFF" : "#000000"

                Text {
                    anchors.centerIn: parent
                    text: wsId
                    font.pixelSize: 16
                    font.weight: active ? Font.Bold : Font.Normal
                    font.family: T.Config.fontFamily
                    color: active ? T.Config.active  : T.Config.inactive
                }
            }
        }
    }

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() {
            workspaces.forceLayout()
        }
    }

}

