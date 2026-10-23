import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.theme as T

Rectangle {
    id: root

    property string appName: ""
    property string appIcon: ""
    property string summary: ""
    property string body: ""
    property string image: ""
    property int urgency: 1
    property real timestamp: 0
    property int count: 1
    property var actions: []

    signal dismissRequested()
    signal clicked()
    signal actionInvoked(string actionId)
    signal historyRequested()

    readonly property bool critical: urgency === 2
    readonly property bool low: urgency === 0
    readonly property bool hovered: mouseArea.containsMouse || closeMouse.containsMouse || moreMouse.containsMouse
    readonly property string iconSource: iconSourceOf(appIcon.length > 0 ? appIcon : image)
    readonly property string pictureSource: image.length > 0 && image !== appIcon ? iconSourceOf(image) : ""
    function iconSourceOf(icon) {
        const value = String(icon || "");
        if (value.length === 0) return "";
        if (value.startsWith("file:") || value.startsWith("http") || value.startsWith("data:") || value.startsWith("image:")) return value;
        if (value.startsWith("/")) return "file://" + value;
        return Quickshell.iconPath(value, true);
    }
    function readableRed() {
        const red = T.Config.red;
        for (let t = 0; t <= 1; t += 0.1) {
            const c = Qt.rgba(red.r + (1 - red.r) * t, red.g + (1 - red.g) * t, red.b + (1 - red.b) * t, 1);
            if (Ui.contrast(c, T.Config.background) >= 4.5) return c;
        }
        return Qt.rgba(1, 1, 1, 1);
    }
    function plain(text) {
        return String(text || "").replace(/<[^>]*>/g, "").replace(/&nbsp;/g, " ").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").trim();
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    readonly property string age: {
        const minutes = Math.max(0, Math.floor((clock.date.getTime() - root.timestamp) / 60000));
        if (minutes < 1) return "now";
        if (minutes < 60) return minutes + "m";
        return Math.floor(minutes / 60) + "h";
    }

    implicitWidth: 340
    implicitHeight: content.implicitHeight + 24
    width: implicitWidth
    height: implicitHeight
    radius: T.Config.popupRadius
    antialiasing: true
    clip: true
    color: root.hovered ? Ui.over(T.Config.surfaceContainer, 0.6) : T.Config.popupBackground
    border.width: 1
    border.color: root.critical ? T.Config.red : T.Config.outline

    Rectangle {
        visible: root.critical
        x: 1
        y: 1
        width: Ui.tick
        height: parent.height - 2
        color: T.Config.red
    }

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
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 8

        Item {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 18
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 1
            Image {
                id: appIconImage
                width: 18
                height: 18
                visible: root.iconSource.length > 0 && status !== Image.Error
                source: root.iconSource
                sourceSize.width: 18 * Screen.devicePixelRatio
                sourceSize.height: 18 * Screen.devicePixelRatio
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
            }
            Text {
                visible: !appIconImage.visible
                text: "󰂚"
                color: Ui.detail
                font.pixelSize: 16
                font.family: Ui.font
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                Text {
                    Layout.fillWidth: true
                    text: [root.appName.toLowerCase(), root.critical ? "critical" : "", root.count > 1 ? root.count + " new" : "", root.age]
                        .filter(x => x.length > 0).join(" · ")
                    color: root.critical ? root.readableRed() : Ui.key
                    font.pixelSize: Ui.detailSize - 1
                    font.family: Ui.font
                    elide: Text.ElideRight
                }
                Text {
                    visible: root.count > 1
                    text: "›"
                    color: moreMouse.containsMouse ? Ui.value : Ui.detail
                    font.pixelSize: Ui.valueSize
                    font.family: Ui.font
                    MouseArea {
                        id: moreMouse
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.historyRequested()
                    }
                }
            }

            Text {
                visible: text.length > 0
                Layout.fillWidth: true
                text: root.plain(root.summary)
                color: root.low ? Ui.detail : Ui.value
                font.pixelSize: Ui.valueSize - 1
                font.family: Ui.font
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                visible: text.length > 0
                Layout.fillWidth: true
                text: root.plain(root.body)
                color: Ui.detail
                font.pixelSize: Ui.detailSize
                font.family: Ui.font
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }

            Image {
                visible: root.pictureSource.length > 0 && status === Image.Ready
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? Math.min(120, implicitHeight > 0 ? implicitHeight * width / Math.max(1, implicitWidth) : 120) : 0
                Layout.topMargin: 4
                source: root.pictureSource
                sourceSize.width: 340
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            Row {
                visible: root.actions.length > 0
                Layout.topMargin: 4
                spacing: 4
                Repeater {
                    model: root.actions
                    delegate: Rectangle {
                        required property var modelData
                        width: actionText.implicitWidth + 10
                        height: actionText.implicitHeight + 6
                        radius: Ui.hoverRadius
                        color: actionMouse.containsMouse ? Ui.hover : "transparent"
                        Text {
                            id: actionText
                            anchors.centerIn: parent
                            text: modelData.label
                            color: Ui.value
                            font.pixelSize: Ui.detailSize
                            font.family: Ui.font
                        }
                        MouseArea {
                            id: actionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.actionInvoked(modelData.id)
                        }
                    }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 14
            text: "×"
            opacity: root.hovered ? 1 : 0
            color: closeMouse.containsMouse ? Ui.value : Ui.detail
            font.pixelSize: Ui.valueSize
            font.family: Ui.font
            MouseArea {
                id: closeMouse
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.dismissRequested()
            }
        }
    }
}
