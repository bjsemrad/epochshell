import QtQuick
import Quickshell
import Quickshell.Widgets
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs.theme as T

Item {
    Layout.fillWidth: true
    Layout.preferredHeight: column.implicitHeight

    ColumnLayout {
        id: column
        anchors.fill: parent
        width: parent.width
        spacing: 4
        // What it is, and the device it is for underneath, quietly.
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: "Microphone"
                color: T.Config.surfaceText
                font.pixelSize: T.Config.fontSizeNormal
                font.bold: true
                Layout.fillWidth: true
            }

            Text {
                visible: text.length > 0
                text: Pipewire.defaultAudioSource ? (Pipewire.defaultAudioSource.description || "") : ""
                color: T.Config.inactive
                font.pixelSize: T.Config.fontSizeSubtext
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        MicVolumeSlider {}
    }
}
