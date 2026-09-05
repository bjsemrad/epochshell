import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.modules.wifi
import qs.commonwidgets
import qs.theme as T

Rectangle {
    id: root
    Layout.fillWidth: true
    color: T.Config.surfaceContainer
    bottomLeftRadius: T.Config.cornerRadius
    bottomRightRadius: T.Config.cornerRadius
    Layout.preferredHeight: expanded ? height : 0
    height: expanded ? fullHeight : 0
    clip: true
    visible: false

    default property alias content: col.data
    property int contentPadding: 12
    property real fullHeight: col.implicitHeight + contentPadding * 2
    property bool expanded: false
    property bool animationEnabled: true

    Behavior on height {
        enabled: animationEnabled
        NumberAnimation {
            duration: 300
            easing.type: Easing.InOutQuad
        }
    }

    function resetCard() {
        expanded = false;
        visible = false;
    }

    function openCard() {
        fullHeight = col.implicitHeight + contentPadding * 2;
        expanded = true;
        visible = true;
    }

    function closeCard() {
        expanded = false;
    }

    onImplicitHeightChanged: {
        if (!expanded && height === 0) {
            visible = false;
        }
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors {
            leftMargin: root.contentPadding
            topMargin: root.contentPadding
            rightMargin: root.contentPadding
            bottomMargin: root.contentPadding
        }
        clip: true
        onImplicitHeightChanged: {
            if (root.visible) {
                openCard();
            }
        }
    }
}
