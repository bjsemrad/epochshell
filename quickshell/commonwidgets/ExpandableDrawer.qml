import QtQuick
import QtQuick.Layouts
import qs.theme as T

Item {
    id: root

    property bool expanded: false
    property int drawerCount: 0
    readonly property int itemSize: T.Config.barIconSize + T.Config.barModuleHorizontalPadding
    readonly property int fullExtent: drawerCount * itemSize + Math.max(0, drawerCount - 1) * T.Config.barModuleSpacing
    property real revealProgress: expanded ? 1 : 0
    readonly property int animationDuration: 300
    readonly property int collapsedWidth: chevron.implicitWidth
    readonly property int expandedWidth: fullExtent + chevron.implicitWidth

    implicitWidth: collapsedWidth + (expandedWidth - collapsedWidth) * revealProgress
    implicitHeight: T.Config.barHeight

    Behavior on revealProgress {
        NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutCubic
        }
    }

    HoverHandler {
        onHoveredChanged: root.expanded = hovered
    }

    clip: true

    Rectangle {
        id: chevron
        width: implicitWidth
        height: implicitHeight
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        color: chevronMouse.containsMouse ? T.Config.surfaceContainer : "transparent"
        radius: T.Config.popupRadius
        implicitWidth: inner.implicitWidth + T.Config.barModuleHorizontalPadding
        implicitHeight: inner.implicitHeight + T.Config.barModuleVerticalPadding
        z: 1

        Rectangle {
            id: inner
            implicitWidth: T.Config.barIconSize
            implicitHeight: T.Config.barIconSize
            color: "transparent"
            anchors.centerIn: parent

            Text {
                text: "\uf053"
                font.pixelSize: T.Config.barIconSize
                font.family: T.Config.fontFamily
                anchors.centerIn: parent
                color: T.Config.surfaceText
                rotation: root.expanded ? 180 : 0

                Behavior on rotation {
                    NumberAnimation {
                        duration: root.animationDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        MouseArea {
            id: chevronMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }

    Row {
        id: itemsRow
        anchors.right: chevron.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: T.Config.barModuleSpacing

        default property alias content: itemsRow.data
    }
}
