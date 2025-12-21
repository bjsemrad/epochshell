import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.theme as T
import qs.services as S

Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 75

    property var player: S.AudioService.player

    Rectangle {
        anchors.fill: parent
        radius: T.Config.cornerRadius
        color: T.Config.surfaceContainer

        RowLayout {
            anchors.fill: parent
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 20

            Image {
                Layout.preferredWidth: 55
                Layout.preferredHeight: 55
                fillMode: Image.PreserveAspectCrop
                source: root.player && root.player.canPlay ? root.player.trackArtUrl : ""
                visible: source !== ""
                smooth: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: root.player ? (root.player.trackTitle || "Nothing playing") : "No player"
                    elide: Text.ElideRight
                    color: T.Config.surfaceText
                    font.pixelSize: T.Config.fontSizeLarge
                }

                Text {
                    Layout.fillWidth: true
                    text: root.player ? (root.player.trackArtist || "") : ""
                    elide: Text.ElideRight
                    color: T.Config.surfaceText
                    font.pixelSize: T.Config.fontSizeNormal
                    visible: text.length > 0
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 14
                spacing: 18

                Item {
                    id: previous
                    width: 34
                    height: 34

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: previousMouseArea.containsMouse ? T.Config.surfaceContainerHighest : T.Config.surface
                        border.color: T.Config.accent
                        border.width: 1
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰒮"
                        font.pixelSize: 22
                        color: T.Config.surfaceText
                    }

                    MouseArea {
                        id: previousMouseArea
                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.player.canGoPrevious) {
                                root.player.previous();
                            }
                        }
                    }
                }

                Item {
                    id: playPause
                    width: 44
                    height: 44

                    property bool isPlaying: root.player ? root.player?.isPlaying : false
                    signal clicked

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: T.Config.accent
                        border.color: T.Config.accent
                        border.width: 1
                    }

                    Text {
                        anchors.centerIn: parent
                        text: playPause.isPlaying ? "󰏤" : "󰐊"
                        font.pixelSize: 22
                        color: T.Config.surface
                    }

                    property bool pressed: false

                    MouseArea {
                        anchors.fill: parent

                        cursorShape: Qt.PointingHandCursor
                        onPressed: playPause.pressed = true
                        onReleased: playPause.pressed = false
                        onCanceled: playPause.pressed = false
                        onClicked: {
                            if (root.player.canPlay) {
                                root.player.togglePlaying();
                            }
                        }
                    }
                }

                Item {
                    id: next
                    width: 34
                    height: 34

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: nextMouseArea.containsMouse ? T.Config.surfaceContainerHighest : T.Config.surface
                        border.color: T.Config.accent
                        border.width: 1
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰒭"
                        font.pixelSize: 22
                        color: T.Config.surfaceText
                    }

                    MouseArea {
                        id: nextMouseArea
                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.player.canGoPrevious) {
                                root.player.next();
                            }
                        }
                    }
                }
            }
        }
    }
}
