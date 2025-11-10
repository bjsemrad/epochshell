import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland        // for WlrLayershell + WlrLayer
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import "../theme" as T

Rectangle {
    id: root

    NetworkMonitor {
        id: netMon
    }

    property string iconName: ""
    property color iconColor: Theme.surfaceText
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

    function hoverTint(base) {
        const factor = 1.2
        return Theme.isLightMode ? Qt.darker(base, factor) : Qt.lighter(base, factor)
    }

    readonly property color _containerBg: T.Config.bg0
        // Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b,
        //         Theme.getContentBackgroundAlpha() * SettingsData.controlCenterWidgetBackgroundOpacity)

    color: _containerBg
    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.10)
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

    Rectangle {
        id: rightHoverOverlay
        anchors.fill: parent
        radius: root.radius
        z: 0
        visible: false
        color: hoverTint(_containerBg)
        opacity: 0.08
        antialiasing: true
        Behavior on opacity { NumberAnimation { duration: Theme.shortDuration } }
    }

    Row {
        id: row
        anchors.fill: parent
        anchors.leftMargin: _padH
        anchors.rightMargin: Theme.spacingM
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
            color: T.Config.red //isActive ? _tileBgActive : _tileBgInactive
            border.color: isActive ? _tileRingActive : "transparent"
            border.width: isActive ? 1 : 0
            antialiasing: true

            Rectangle {
                anchors.fill: parent
                            anchors.left: parent.left
                radius: _tileRadius
                color: hoverTint(iconTile.color)
                opacity: tileMouse.pressed ? 0.3 : (tileMouse.containsMouse ? 0.2 : 0.0)
                visible: opacity > 0
                antialiasing: true
                Behavior on opacity { NumberAnimation { duration: Theme.shortDuration } }
            }

              IconImage {
                    source:  Quickshell.iconPath(netMon.connected
                            ? "network-wireless-signal-excellent-symbolic"
                            : "network-offline-symbolic")
                    implicitWidth: 18
                    implicitHeight: 18
                    anchors.centerIn: parent

                }


            MouseArea {
                id: tileMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggled()
            }
        }

        Item {
            id: body
            width: row.width - iconTile.width - row.spacing
            height: row.height
            anchors.left: iconTile.right
            anchors.leftMargin: 10


            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Label {
                    text: netMon.connected
                          ? `${netMon.ssid}`
                          : "Wi-Fi Disabled"
                          color: "white" //T.Config.fg
                    font.pixelSize: 14
                    font.weight: Font.Normal
                    font.family: T.Config.fontFamily
                    Layout.fillWidth: true
                }
                  Label {
                    text: netMon.connected
                          ? "Connected"
                          : "Disconnected"
                          color: T.Config.fg
                    font.pixelSize: 12
                    font.weight: Font.Normal
                    font.family: T.Config.fontFamily
                    Layout.fillWidth: true
                }

            }

            MouseArea {
                id: bodyMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: { rightHoverOverlay.visible = true; rightHoverOverlay.opacity = 0.08 }
                onExited:  { rightHoverOverlay.opacity = 0.0; rightHoverOverlay.visible = false }
                onPressed: rightHoverOverlay.opacity = 0.16
                onReleased: rightHoverOverlay.opacity = containsMouse ? 0.08 : 0.0
                onClicked: root.expandClicked()
                onWheel: function (ev) {
                    root.wheelEvent(ev)
                }
            }

        }
    }

    focus: true
    Keys.onPressed: function (ev) {
        if (ev.key === Qt.Key_Space || ev.key === Qt.Key_Return) { root.toggled(); ev.accepted = true }
        else if (ev.key === Qt.Key_Right) { root.expandClicked(); ev.accepted = true }
    }
}

