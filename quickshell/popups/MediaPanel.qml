import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.services as S
import qs.theme as T
import qs.commonwidgets

// The media player, from the bar's track title. Built on HoverPopupWindow like every other bar
// panel, so it hangs from the bar and grows out of it the same way; what it adds is a short grace
// before closing, so the pointer can cross from the title to the panel without it vanishing.
HoverPopupWindow {
    id: popup

    popupWidth: 420
    readonly property var player: S.AudioService.player

    // Replaces the base's close-at-once: closed only if, a moment later, the pointer is over
    // neither the panel nor the title that opened it.
    function _updateHover() {
        closeTimer.restart();
    }

    onOpenChanged: if (open) S.PopupManager.closeOthers(popup)

    Timer {
        id: closeTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (!popup.popupHover && !(popup.trigger && popup.trigger.hovered)) {
                popup.hidePanel();
            }
        }
    }

    Component.onDestruction: S.PopupManager.unregister(popup)
    Component.onCompleted: S.PopupManager.register(popup, "media")

    // The player's position is not pushed as it moves -- MPRIS only says where it is when asked --
    // so while the panel is up and something is playing, it is asked once a second.
    Timer {
        interval: 1000
        repeat: true
        running: popup.open && popup.player && popup.player.isPlaying
        onTriggered: popup.player.positionChanged()
    }

    function formatTime(seconds) {
        const total = Math.max(0, Math.floor(seconds || 0));
        const h = Math.floor(total / 3600);
        const m = Math.floor((total % 3600) / 60);
        const s = total % 60;
        const pad = n => (n < 10 ? "0" : "") + n;
        return h > 0 ? h + ":" + pad(m) + ":" + pad(s) : m + ":" + pad(s);
    }

    ColumnLayout {
        id: content
        Layout.fillWidth: true
        spacing: T.Config.popupLayoutSpacing + 4

        // --- Header: whose music, and the others to switch to ------------------------------------

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: T.Config.layoutMarginSmall
            spacing: T.Config.layoutMarginSmall

            Text {
                Layout.fillWidth: true
                text: popup.player ? (popup.player.identity || popup.player.desktopEntry || "Media") : "Media"
                color: T.Config.outline
                font.pixelSize: T.Config.fontSizeSubtext + 2
                font.bold: true
                elide: Text.ElideRight
            }

            // One disc per player when there is more than one; the one shown is ringed.
            Repeater {
                model: S.AudioService.sourcePlayers.length > 1 ? S.AudioService.sourcePlayers : []

                delegate: Rectangle {
                    id: source
                    required property var modelData
                    readonly property bool selected: popup.player && S.AudioService.playerKey(popup.player) === S.AudioService.playerKey(modelData)
                    readonly property string appIcon: modelData && modelData.desktopEntry ? Quickshell.iconPath(modelData.desktopEntry, true) : ""

                    implicitWidth: 26
                    implicitHeight: 26
                    radius: 13
                    antialiasing: true
                    color: sourceMouse.containsMouse ? T.Config.surfaceContainerHigh : T.Config.surfaceContainer
                    border.width: selected ? 2 : 0
                    border.color: T.Config.accent

                    Image {
                        id: sourceIcon
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        source: source.appIcon
                        sourceSize.width: 32
                        sourceSize.height: 32
                        visible: source.appIcon.length > 0 && status !== Image.Error
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !sourceIcon.visible
                        text: source.modelData && source.modelData.isPlaying ? "󰏤" : "󰎈"
                        color: source.selected ? T.Config.accent : T.Config.inactive
                        font.pixelSize: T.Config.fontSizeSubtext + 2
                        font.family: T.Config.fontFamily
                    }

                    MouseArea {
                        id: sourceMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: S.AudioService.selectPlayer(S.AudioService.playerKey(source.modelData))
                    }
                }
            }
        }

        // --- Nothing to show -----------------------------------------------------------------------

        ColumnLayout {
            visible: !popup.player
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: T.Config.popupPadding
            Layout.bottomMargin: T.Config.popupPadding
            spacing: 4

            Text {
                text: "󰎈"
                color: T.Config.outline
                font.pixelSize: T.Config.fontSizeXLarge
                font.family: T.Config.fontFamily
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "Nothing playing"
                color: T.Config.inactive
                font.pixelSize: T.Config.fontSizeNormal
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // --- The track: what it is, large, and its cover -------------------------------------------

        RowLayout {
            visible: !!popup.player
            Layout.fillWidth: true
            spacing: T.Config.layoutSpacingSmall

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: popup.player ? (popup.player.trackTitle || "Nothing playing") : ""
                    color: T.Config.surfaceText
                    font.pixelSize: T.Config.fontSizeXLarge
                    font.bold: true
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: popup.player ? (popup.player.trackArtist || "") : ""
                    color: T.Config.inactive
                    font.pixelSize: T.Config.fontSizeMedium
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: popup.player ? (popup.player.trackAlbum || "") : ""
                    color: T.Config.outline
                    font.pixelSize: T.Config.fontSizeSubtext + 2
                    elide: Text.ElideRight
                }
            }

            // The cover, or a note in its place.
            Rectangle {
                Layout.preferredWidth: 112
                Layout.preferredHeight: 112
                Layout.alignment: Qt.AlignVCenter
                radius: T.Config.cardRadius
                antialiasing: true
                color: T.Config.surfaceContainer
                clip: true

                Image {
                    id: albumArt
                    anchors.fill: parent
                    source: popup.player && popup.player.trackArtUrl ? popup.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                    visible: source !== "" && status === Image.Ready
                }

                Text {
                    visible: !albumArt.visible
                    anchors.centerIn: parent
                    text: "󰎈"
                    color: T.Config.outline
                    font.pixelSize: T.Config.fontSizeXLarge + 8
                    font.family: T.Config.fontFamily
                }
            }
        }

        // --- Where in it ------------------------------------------------------------------------------

        RowLayout {
            id: seekRow
            visible: !!popup.player && popup.player.lengthSupported && popup.player.length > 0
            Layout.fillWidth: true
            spacing: T.Config.layoutMarginSmall * 2

            readonly property real length: popup.player ? popup.player.length : 0
            readonly property real position: popup.player ? Math.min(popup.player.position, length) : 0
            readonly property bool seekable: !!popup.player && popup.player.canSeek && popup.player.positionSupported

            Item {
                id: track
                Layout.fillWidth: true
                implicitHeight: 16

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 4
                    radius: 2
                    color: T.Config.surfaceContainerHigh

                    Rectangle {
                        width: seekRow.length > 0 ? parent.width * seekRow.position / seekRow.length : 0
                        height: parent.height
                        radius: parent.radius
                        color: T.Config.accent
                    }
                }

                // The handle, only while it can be grabbed.
                Rectangle {
                    visible: seekRow.seekable && seekMouse.containsMouse
                    x: (seekRow.length > 0 ? track.width * seekRow.position / seekRow.length : 0) - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12
                    height: 12
                    radius: 6
                    color: T.Config.accent
                }

                MouseArea {
                    id: seekMouse
                    anchors.fill: parent
                    enabled: seekRow.seekable
                    hoverEnabled: true
                    cursorShape: seekRow.seekable ? Qt.PointingHandCursor : Qt.ArrowCursor
                    function seekTo(x) {
                        if (!popup.player || seekRow.length <= 0) return;
                        popup.player.position = Math.max(0, Math.min(1, x / width)) * seekRow.length;
                    }
                    onPressed: mouse => seekTo(mouse.x)
                    onPositionChanged: mouse => { if (pressed) seekTo(mouse.x); }
                }
            }

            Text {
                text: popup.formatTime(seekRow.position) + " / " + popup.formatTime(seekRow.length)
                color: T.Config.inactive
                font.pixelSize: T.Config.fontSizeSubtext + 2
                font.family: T.Config.fontFamily
            }
        }

        // --- Control: the row of tiles ----------------------------------------------------------------

        RowLayout {
            visible: !!popup.player
            Layout.fillWidth: true
            Layout.bottomMargin: T.Config.layoutMarginSmall
            spacing: T.Config.cardSpacing

            readonly property bool canShuffle: !!popup.player && popup.player.shuffleSupported
            readonly property bool canLoop: !!popup.player && popup.player.loopSupported

            TransportTile {
                visible: parent.canShuffle
                icon: popup.player && popup.player.shuffle ? "󰒝" : "󰒞"
                active: popup.player && popup.player.shuffle
                onClicked: popup.player.shuffle = !popup.player.shuffle
            }

            TransportTile {
                icon: "󰒮"
                enabled: popup.player && popup.player.canGoPrevious
                onClicked: S.AudioService.runAction("previous", true, S.AudioService.playerKey(popup.player))
            }

            TransportTile {
                weight: 1.8
                filled: true
                icon: popup.player && popup.player.isPlaying ? "󰏤" : "󰐊"
                enabled: popup.player && S.AudioService.canHandleAction(popup.player, "playPause")
                onClicked: S.AudioService.runAction("playPause", true, S.AudioService.playerKey(popup.player))
            }

            TransportTile {
                icon: "󰒭"
                enabled: popup.player && popup.player.canGoNext
                onClicked: S.AudioService.runAction("next", true, S.AudioService.playerKey(popup.player))
            }

            // Repeat cycles off, the whole list, this track.
            TransportTile {
                visible: parent.canLoop
                readonly property int loop: popup.player ? popup.player.loopState : MprisLoopState.None
                icon: loop === MprisLoopState.Track ? "󰑘" : loop === MprisLoopState.Playlist ? "󰑖" : "󰑗"
                active: loop !== MprisLoopState.None
                onClicked: {
                    popup.player.loopState = loop === MprisLoopState.None ? MprisLoopState.Playlist
                        : loop === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None;
                }
            }
        }
    }

    // A control as a tile, sharing the row by `weight`. `filled` is the main one -- play -- in the
    // accent; `active` lights a toggle that is on (shuffle, repeat) the way a dashboard tile is.
    component TransportTile: Rectangle {
        id: tile
        property string icon
        property real weight: 1
        property bool filled: false
        property bool active: false
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredWidth: 40 * weight
        implicitHeight: 40
        radius: T.Config.cardRadius
        antialiasing: true
        opacity: enabled ? 1 : 0.35
        color: tile.filled ? T.Config.accent
            : tile.active ? T.Config.accentLightShade
            : tileMouse.containsMouse ? T.Config.surfaceContainerHigh : T.Config.surfaceContainer
        border.width: tile.active && !tile.filled ? 1 : 0
        border.color: T.Config.accent

        Text {
            anchors.centerIn: parent
            text: tile.icon
            color: tile.filled ? T.Config.background : tile.active ? T.Config.accent : T.Config.surfaceText
            font.pixelSize: tile.filled ? T.Config.barIconSize + 6 : T.Config.barIconSize + 2
            font.family: T.Config.fontFamily
        }

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            enabled: tile.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }
    }
}
