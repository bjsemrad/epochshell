import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import "../theme" as T
// ----- ROUNDED SLIDER -----
Rectangle {
      property var audioInterface: Pipewire.defaultAudioSink
      // width: parent.width
     // border.color: T.Config.grey //Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.10)
     // border.width: 1
     // color: T.Config.black
     // radius: 10
//     height: 24
      width: parent ? parent.width : 220
      height: 60
      radius: 40

         readonly property color _containerBg: T.Config.bg0

    color: _containerBg
    border.color: T.Config.grey
    border.width: 1
    antialiasing: true


     // Column {
         // width: 20
         // height: 20
        IconImage {
            anchors.left: parent.left
            anchors.leftMargin: 10
             anchors.verticalCenter: parent.verticalCenter
            implicitSize: 24
            source: Quickshell.iconPath(audioIcon(volume.value, audioInterface?.audio.muted))
        }

        function audioIcon(vol, muted) {
        if (muted) return "audio-volume-muted-symbolic"
        if (vol >= 65) return "audio-volume-high-symbolic"
        if (vol >= 25) return "audio-volume-medium-symbolic"
        if (vol >   0) return "audio-volume-low-symbolic"
        return "audio-volume-muted-symbolic"
    }
        

    	Connections {
		target: audioInterface?.audio

                function updateSlider() {
                    volume.value = (audioInterface?.audio.volume ?? 0) * 100
                }
                
                function onVolumeChanged() {
                    updateSlider()
		}


                function onMutedChanged() {
                    updateSlider()
                }

                Component.onCompleted: updateSlider()

        }
    // }
    // Column {
        // width: 200
        // height: 20
        Slider {
            anchors.centerIn: parent
        id: volume
        width: 200
        height: 20
        from: 0; to: 100

        background: Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: T.Config.grey
        }

        handle: Rectangle {
            width: 10
            height: 10
            radius: 6
            color: T.Config.red
            anchors.verticalCenter: parent.verticalCenter
        }

        // fill bar
        contentItem: Rectangle {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            width: volume.position * volume.width
            height: 10
            radius: height / 2
            color: T.Config.red
        }
    }
    // }
}

