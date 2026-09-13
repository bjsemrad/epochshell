import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.commonwidgets
import qs.theme as T

// The theme picker, flying out of the system menu's Theme row.
//
// It is a separate window rather than a list that unfolds inside the system menu because that menu
// is 300px wide and already tall: a machine with eight themes would push the power actions off the
// bottom of the screen. Out here the list is free to be as long as it likes.
//
// Hovering a row wears the theme. That is the whole point of the panel -- a palette is not
// something a name or five dots can tell you, and the shell repainting under the cursor is the
// only honest preview -- and it costs nothing, because a preview is never written down. Leaving
// without clicking puts back whatever was actually chosen.
HoverPopupWindow {
    id: themePanel
    popupWidth: T.Config.systemPopupWidth

    // Sideways out of the row, not downwards out of a bar module. The system menu lives at the
    // right-hand end of the bar, so the picker opens to its left, top-aligned with the row that
    // opened it.
    anchorEdges: Edges.Left | Edges.Top
    anchorGravity: Edges.Left | Edges.Bottom
    anchorRectY: 0

    // Deliberately not registered with PopupManager, and deliberately no closeOthers.
    //
    // PopupManager's panels are peers -- opening one closes the rest, which is right for a bar
    // full of them. This one is not a peer: it hangs off a row inside the system menu, so closing
    // "the others" would take away the window it is anchored to, and the system menu closing the
    // others on its own way open would take away this one. It lives and dies with its parent
    // instead, which is what `parentPanel` below is for.
    property var parentPanel: null

    onVisibleChanged: if (!visible) T.Config.endPreview()

    Connections {
        target: themePanel.parentPanel
        function onOpenChanged() {
            if (!themePanel.parentPanel.open) themePanel.hidePanel();
        }
    }

    Text {
        text: "Themes"
        color: T.Config.surfaceText
        font.pixelSize: T.Config.fontSizeLarge
        font.bold: true
        Layout.fillWidth: true
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        // Ending the preview here rather than on each row means moving between rows never flickers
        // back through the chosen theme on the way.
        HoverHandler {
            id: listHover
            onHoveredChanged: if (!hovered) T.Config.endPreview()
        }

        Repeater {
            model: T.Config.availableThemes

            delegate: Rectangle {
                id: row
                required property string modelData
                readonly property bool current: row.modelData === T.Config.themeName

                Layout.fillWidth: true
                Layout.preferredHeight: T.Config.cardHeight - 14
                radius: T.Config.popupRadius
                color: row.current ? T.Config.accentLightShade
                     : rowMouse.containsMouse ? T.Config.surfaceContainerHigh
                     : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: T.Config.layoutMarginSmall
                    anchors.rightMargin: T.Config.layoutMarginSmall
                    spacing: T.Config.layoutMarginSmall

                    // The palette itself, read out of the theme's file rather than out of the
                    // running shell, which is the only way to show one theme while wearing another.
                    //
                    // A little plate of the theme's own ground with its colours sitting on it: the
                    // ground is half of what a theme is, and showing it as one more square in a row
                    // of squares loses it against whatever ground the picker happens to have.
                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: swatchRow.implicitWidth + 10
                        implicitHeight: 20
                        radius: 5
                        color: T.Config.themeColor(row.modelData, "background")
                        border.width: 1
                        border.color: T.Config.themeColor(row.modelData, "surfaceVariant")

                        Row {
                            id: swatchRow
                            anchors.centerIn: parent
                            spacing: 3

                            Repeater {
                                model: T.Config.swatchKeys

                                delegate: Rectangle {
                                    required property string modelData
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: T.Config.themeColor(row.modelData, modelData)
                                }
                            }
                        }
                    }

                    Text {
                        text: row.modelData
                        color: T.Config.surfaceText
                        font.pixelSize: T.Config.fontSizeNormal
                        font.family: T.Config.fontFamily
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: "󰄬"
                        visible: row.current
                        color: T.Config.accent
                        font.pixelSize: T.Config.fontSizeNormal
                        font.family: T.Config.fontFamily
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: T.Config.previewTheme(row.modelData)
                    onClicked: T.Config.selectTheme(row.modelData)
                }
            }
        }
    }

    Text {
        text: "Hover to try, click to keep"
        color: T.Config.outline
        font.pixelSize: T.Config.fontSizeSubtext
        Layout.fillWidth: true
    }

    ComponentSpacer {
        bottomMargin: 2
    }
}
