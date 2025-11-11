import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import "../theme" as T

Rectangle {
    id: root

    property string iconName: ""
    property var audioInterface: Pipewire.defaultAudioSink
    // property color iconColor: Theme.surfaceText
    property string primaryText: ""
    property string secondaryText: ""
    property bool expanded: false
    property bool isActive: false
    property bool showExpandArea: true

    signal toggled()
    signal expandClicked()
    signal wheelEvent(var wheelEvent)

    width: parent ? parent.width : 220
    height: 60
    radius: 40

    readonly property color _containerBg: T.Config.bg0
    color: _containerBg
    border.color: T.Config.grey//Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.10)
    border.width: 1
    antialiasing: true

    // Drop shadow
    layer.enabled: true
    layer.effect: DropShadow {
        horizontalOffset: 0
        verticalOffset: 2
        radius: 8
        samples: 16
        color: Qt.rgba(0, 0, 0, SettingsData.controlCenterDropShadowOpacity)
        transparentBorder: true
    }

    readonly property color _labelPrimary: Theme.surfaceText
    readonly property color _labelSecondary: Theme.surfaceVariantText
    readonly property color _tileBgActive: Theme.primary
    readonly property color _tileBgInactive: {
        const transparency = Theme.popupTransparency || 0.92
        const surface = Theme.surfaceContainer || Qt.rgba(0.1, 0.1, 0.1, 1)
        return Qt.rgba(surface.r, surface.g, surface.b, transparency)
    }
    readonly property color _tileRingActive:
        Qt.rgba(Theme.primaryText.r, Theme.primaryText.g, Theme.primaryText.b, 0.22)
    readonly property color _tileRingInactive:
        Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.18)
    readonly property color _tileIconActive: T.Config.blue
    readonly property color _tileIconInactive: Theme.primary

    property int _padH: Theme.spacingS
    property int _tileSize: 48
    property int _tileRadius: 40

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



    Rectangle {
        id: rightHoverOverlay
        anchors.fill: parent
        radius: root.radius
        z: 0
        visible: false
        opacity: 0.08
        antialiasing: true
        Behavior on opacity { NumberAnimation { duration: Theme.shortDuration } }
    }

    Row {
        id: row
        anchors.fill: parent
        // anchors.leftMargin: _padH
        // anchors.rightMargin: Theme.spacingM
        spacing: 10

        Rectangle {
            id: iconTile
            z: 1
            width: _tileSize
            height: _tileSize
             anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            radius: _tileRadius
            color: T.Config.bg0 //isActive ? _tileBgActive : _tileBgInactive
            border.color: T.Config.blue //isActive ? _tileRingActive : "transparent"
            border.width: 2 
            antialiasing: true

            Rectangle {
                id: clickIcon
                anchors.fill: parent
                radius: _tileRadius
                opacity: tileMouse.pressed ? 0.3 : (tileMouse.containsMouse ? 0.2 : 0.0)
                visible: opacity > 0
                antialiasing: true
                Behavior on opacity { NumberAnimation { duration: Theme.shortDuration } }
            }
            IconImage {
                implicitWidth: 18
                implicitHeight: 18
                anchors.centerIn: parent
                source: Quickshell.iconPath(audioIcon(volume.value, audioInterface?.audio.muted))
                }


            MouseArea {
                id: tileMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggled()
            }
        }


        Slider {
        id: volume
        width: 190
        height: 20
        from: 0; to: 100
        anchors.left: iconTile.right
        anchors.leftMargin: 10
         anchors.verticalCenter: parent.verticalCenter


        background: Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: T.Config.grey
        }

        handle: Rectangle {
            width: 10
            height: 10
            radius: 6
            color: T.Config.fg
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
            color: T.Config.fg
        }
    }


        }

    focus: true
}

