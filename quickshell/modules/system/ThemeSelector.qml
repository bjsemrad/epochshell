import QtQuick
import QtQuick.Layouts
import qs.theme as T

// The Theme row in the system menu: what is worn now, and the way into the picker.
//
// The row itself is the picker's trigger -- the panel anchors to this item and flies out beside
// the menu. It hides while there is nothing to choose between: a single theme is not a choice, and
// an empty list is what the shell shows for the moment before it has finished looking on disk.
Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: T.Config.settingsHeaderHeight
    visible: T.Config.availableThemes.length > 1

    property var popup

    Rectangle {
        id: rowBackground
        anchors.fill: parent
        anchors.rightMargin: T.Config.systemActionSpacing
        radius: T.Config.popupRadius
        color: (root.popup && root.popup.open) || rowMouse.containsMouse ? T.Config.surfaceContainerHigh : "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: T.Config.layoutMarginSmall
            anchors.rightMargin: T.Config.layoutMarginSmall
            spacing: T.Config.layoutMarginSmall

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                Text {
                    text: "Theme"
                    color: T.Config.surfaceText
                    font.pixelSize: T.Config.fontSizeNormal
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                // The name of what is on screen, which during a preview is the theme being tried
                // rather than the one chosen -- the row should agree with the shell around it.
                Text {
                    text: T.Config.themeLoaded ? T.Config.themeName : (T.Config.themeName + " -- file missing")
                    color: T.Config.themeLoaded ? T.Config.outline : T.Config.orange
                    font.pixelSize: T.Config.fontSizeSubtext
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            // Points at where the panel comes out.
            Text {
                text: ""
                color: T.Config.outline
                font.pixelSize: T.Config.fontSizeSubtext
                font.family: T.Config.fontFamily
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Hover opens it, the way every other panel in this shell opens. Clicking still toggles,
        // for anyone who would rather not have a panel appear at them.
        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onEntered: {
                closeTimer.stop();
                if (root.popup) root.popup.showPanel();
            }

            // Not an immediate hide: the pointer leaving this row is usually the pointer on its
            // way into the panel, and the gap between the two is real estate the pointer has to
            // cross. The timer gives it time to arrive, and the panel cancels the close once it
            // reports the pointer inside itself.
            onExited: closeTimer.restart()

            onClicked: {
                if (!root.popup) return;
                if (root.popup.open) {
                    root.popup.hidePanel();
                } else {
                    root.popup.showPanel();
                }
            }
        }

        Timer {
            id: closeTimer
            interval: 200
            repeat: false
            onTriggered: {
                if (root.popup && !root.popup.popupHover) root.popup.hidePanel();
            }
        }
    }
}
