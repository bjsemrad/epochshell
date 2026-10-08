import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.theme as T

// A notification, in the panels' language: the app's icon (or a bell in a disc), the app's name
// small and quiet, the summary in bold, the body underneath in the secondary text colour -- the
// interface font for words, the icon font only for icons.
//
// Two settings for it:
//   a toast (`embedded` false) floats over whatever window is underneath, so it keeps a ground
//   and a soft edge to separate it from that;
//   in the history panel (`embedded` true) it is a row of a list, like ListRow: no box of its
//   own, only lifted a shade under the pointer.
// A critical one says so with a red edge and a red app name.
//
// Clicking it goes to whatever sent it; right-clicking, or the close button that appears under
// the pointer, dismisses it.
Rectangle {
    id: root

    property string appName: ""
    property string appIcon: ""
    property string summary: ""
    property string body: ""
    property string image: ""
    property int urgency: 1
    property bool closeVisible: true
    property bool embedded: false
    property int contentPadding: T.Config.popupPadding + 2

    signal dismissRequested()
    signal clicked()

    readonly property bool critical: urgency === 2
    readonly property bool hovered: mouseArea.containsMouse || closeButton.hovered

    readonly property string iconSource: image.length > 0 ? image : iconSourceOf(appIcon)

    function iconSourceOf(icon) {
        const value = String(icon || "");
        if (value.length === 0) return "";
        if (value.startsWith("file:") || value.startsWith("http") || value.startsWith("data:") || value.startsWith("image:")) return value;
        if (value.startsWith("/")) return "file://" + value;
        return Quickshell.iconPath(value, true);
    }

    implicitWidth: 380
    implicitHeight: content.implicitHeight + contentPadding * 2
    width: implicitWidth
    height: implicitHeight
    radius: T.Config.cardRadius
    antialiasing: true
    clip: true
    color: root.embedded
        ? (root.hovered ? T.Config.surfaceContainerHigh : "transparent")
        : (root.hovered ? T.Config.surfaceContainerHigh : T.Config.popupBackground)
    border.width: root.critical || !root.embedded ? 1 : 0
    border.color: root.critical ? T.Config.red : T.Config.surfaceVariant

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) root.dismissRequested();
            else root.clicked();
        }
    }

    RowLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: root.contentPadding
        }
        spacing: T.Config.layoutMarginSmall * 2

        // The sender's image or icon; a bell in a disc when it gave neither, so every
        // notification is laid out the same.
        Item {
            Layout.preferredWidth: T.Config.connectedIconSize
            Layout.preferredHeight: T.Config.connectedIconSize
            Layout.alignment: Qt.AlignTop

            Image {
                id: iconImage
                anchors.fill: parent
                visible: root.iconSource.length > 0 && status !== Image.Error
                source: root.iconSource
                sourceSize.width: T.Config.connectedIconSize * Screen.devicePixelRatio
                sourceSize.height: T.Config.connectedIconSize * Screen.devicePixelRatio
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
            }

            Rectangle {
                anchors.fill: parent
                visible: !iconImage.visible
                radius: width / 2
                antialiasing: true
                color: T.Config.surfaceContainerHigh

                Text {
                    anchors.centerIn: parent
                    text: "󰂚"
                    color: root.critical ? T.Config.red : T.Config.accent
                    font.pixelSize: T.Config.fontSizeLarge
                    font.family: T.Config.fontFamily
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 2

            Text {
                visible: root.appName.length > 0
                text: root.appName
                color: root.critical ? T.Config.red : T.Config.outline
                font.pixelSize: T.Config.fontSizeSubtext
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                visible: root.summary.length > 0
                text: root.summary
                color: T.Config.surfaceText
                font.pixelSize: T.Config.fontSizeNormal
                font.bold: true
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                visible: root.body.length > 0
                text: root.body
                color: T.Config.inactive
                font.pixelSize: T.Config.fontSizeNormal
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // Dismiss: there when the pointer is, out of the way when it is not. Its space is kept
        // either way, so the text does not reflow under the pointer.
        IconButton {
            id: closeButton
            readonly property bool hovered: closeMouse.containsMouse
            Layout.alignment: Qt.AlignTop
            size: T.Config.barIconSize + 8
            icon: "󰅖"
            iconColor: T.Config.inactive
            opacity: root.closeVisible && root.hovered ? 1 : 0
            enabled: root.closeVisible
            onClicked: root.dismissRequested()

            HoverHandler {
                id: closeMouse
            }
        }
    }
}
