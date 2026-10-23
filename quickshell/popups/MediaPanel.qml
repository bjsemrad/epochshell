import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.commonwidgets
import qs.services as S
import qs.theme as T

HoverPopupWindow {
    id: popup

    popupWidth: 480
    readonly property var player: S.AudioService.player

    function _updateHover() {
        closeTimer.restart();
    }

    onOpenChanged: if (open) S.PopupManager.closeOthers(popup)

    Timer {
        id: closeTimer
        interval: 120
        onTriggered: {
            if (!popup.popupHover && !(popup.trigger && popup.trigger.hovered)) popup.hidePanel();
        }
    }

    Component.onDestruction: S.PopupManager.unregister(popup)
    Component.onCompleted: S.PopupManager.register(popup, "media")

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
        Layout.fillWidth: true
        spacing: 0

        Keys.onEscapePressed: popup.hidePanel()

        PageHeader {
            title: popup.player ? (popup.player.trackTitle || "nothing playing") : "nothing playing"
            status: popup.player ? String(popup.player.identity || "").toLowerCase() : ""
            active: popup.player !== null && popup.player.isPlaying
        }
        Note {
            visible: text.length > 0
            text: popup.player ? [popup.player.trackArtist, popup.player.trackAlbum].filter(x => x && x.length > 0).join(" · ") : ""
            maximumLineCount: 1
            elide: Text.ElideRight
        }

        KeyRow {
            visible: S.AudioService.sourcePlayers.length > 1
            key: "player"
            Choice {
                options: S.AudioService.sourcePlayers.map(p => ({ value: S.AudioService.playerKey(p), label: String(p.identity || p.desktopEntry || "player").toLowerCase() }))
                current: popup.player ? S.AudioService.playerKey(popup.player) : ""
                onPicked: v => S.AudioService.selectPlayer(v)
            }
        }

        KeyRow {
            id: seek
            readonly property real length: popup.player ? popup.player.length : 0
            readonly property real position: popup.player ? Math.min(popup.player.position, length) : 0
            visible: popup.player !== null && popup.player.lengthSupported && length > 0
            key: popup.formatTime(seek.position)
            LevelSlider {
                trackWidth: 200
                interactive: popup.player !== null && popup.player.canSeek && popup.player.positionSupported
                value: seek.length > 0 ? seek.position / seek.length : 0
                label: popup.formatTime(seek.length)
                onMoved: v => { if (popup.player) popup.player.position = v * seek.length; }
            }
        }

        Divider { visible: popup.player !== null }

        RowLayout {
            visible: popup.player !== null
            Layout.fillWidth: true
            spacing: 2
            readonly property int loop: popup.player ? popup.player.loopState : MprisLoopState.None

            Item { Layout.fillWidth: true }
            IconButton {
                visible: popup.player !== null && popup.player.shuffleSupported
                icon: popup.player && popup.player.shuffle ? "󰒝" : "󰒞"
                name: "shuffle"
                active: popup.player !== null && popup.player.shuffle
                onClicked: popup.player.shuffle = !popup.player.shuffle
            }
            IconButton {
                icon: "󰒮"
                name: "previous"
                opacity: popup.player && popup.player.canGoPrevious ? 1 : 0.35
                onClicked: S.AudioService.runAction("previous", true, S.AudioService.playerKey(popup.player))
            }
            IconButton {
                icon: popup.player && popup.player.isPlaying ? "󰏤" : "󰐊"
                name: popup.player && popup.player.isPlaying ? "pause" : "play"
                active: popup.player !== null && popup.player.isPlaying
                onClicked: S.AudioService.runAction("playPause", true, S.AudioService.playerKey(popup.player))
            }
            IconButton {
                icon: "󰒭"
                name: "next"
                opacity: popup.player && popup.player.canGoNext ? 1 : 0.35
                onClicked: S.AudioService.runAction("next", true, S.AudioService.playerKey(popup.player))
            }
            IconButton {
                visible: popup.player !== null && popup.player.loopSupported
                icon: parent.loop === MprisLoopState.Track ? "󰑘" : parent.loop === MprisLoopState.Playlist ? "󰑖" : "󰑗"
                name: "loop"
                active: parent.loop !== MprisLoopState.None
                onClicked: {
                    const loop = parent.loop;
                    popup.player.loopState = loop === MprisLoopState.None ? MprisLoopState.Playlist
                        : loop === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None;
                }
            }
            Item { Layout.fillWidth: true }
        }
    }
}
