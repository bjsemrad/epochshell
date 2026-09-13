import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import qs.theme as T
import qs.services as S

// No border, for the reason given in BarIconPopup.qml: an uncoloured 1px border draws black.
Rectangle {
    id: root
    color: popup && popup.open ? T.Config.surfaceContainer : mouseArea.containsMouse ? T.Config.surfaceContainer : "transparent"
    radius: T.Config.popupRadius
    implicitWidth: inner.implicitWidth + T.Config.barModuleHorizontalPadding
    implicitHeight: inner.implicitHeight + T.Config.barModuleVerticalPadding

    property var popup
    required property string iconText
    required property bool mouseEnabled
    required property bool hoverEnabled
    property int fontPixelSize: T.Config.barIconSize

    MouseArea {
        id: mouseArea
        enabled: mouseEnabled
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: mouseEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (popup.open) {
                popup.hidePanel();
            } else {
                popup.showPanel();
            }
        }

        onEntered: {
            if (root.hoverEnabled) {
                if (mouseArea.containsMouse) {
                    popup.showPanel();
                } else {
                    popup.hidePanel();
                }
            }
        }

        onExited: {
            if (root.hoverEnabled) {
                if (!mouseArea.containsMouse) {
                    popup.hidePanel();
                }
            }
        }
    }

    // A fixed icon-sized box, the same one BarIcon and BarIconPopup use, rather than whatever the
    // glyph happens to measure. Sizing this from the text made this module -- the only one that
    // did -- taller and wider than every other icon on the bar: a text item's implicit height is
    // a whole line box, ascent and descent included, which for an 18px glyph is nearer 25px, and
    // its width is the glyph's own advance. The power symbol also comes from a fallback face
    // rather than the Nerd Font the rest use, so its metrics were not even consistently wrong.
    Rectangle {
        id: inner
        implicitWidth: T.Config.barIconSize
        implicitHeight: T.Config.barIconSize
        color: "transparent"
        anchors.centerIn: parent
        Text {
            id: iconText
            text: root.iconText
            font.pixelSize: root.fontPixelSize
            font.family: T.Config.fontFamily
            anchors.centerIn: parent
            color: T.Config.surfaceText
        }
    }
}
