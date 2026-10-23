import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.theme as T

// `status` rather than `state`: Item already has `state`.
Item {
    id: row

    property string icon: ""
    property string iconSource: ""
    property color iconColor: row.active ? Ui.accent : Ui.value
    property string value: ""
    property real valueWidth: 0
    property string detail: ""
    property string status: ""
    property string hoverStatus: ""
    property color statusColor: row.active ? Ui.accent : Ui.detail
    property bool active: false
    property bool current: false
    property bool toggleable: false
    property bool hasSwitch: toggleable
    property bool checked: active
    property bool hasPage: false
    property bool interactive: true
    default property alias middle: middleSlot.data

    signal toggled()
    signal opened()
    signal clicked()
    signal secondaryClicked()

    readonly property bool lit: interactive && (mouse.containsMouse || chevronMouse.containsMouse || (activeFocus && Ui.keyboardActive))

    function activate() {
        if (!interactive) return;
        if (toggleable) toggled();
        else if (hasPage) opened();
        else clicked();
    }

    Layout.fillWidth: true
    implicitHeight: Ui.rowHeight
    implicitWidth: content.implicitWidth
    activeFocusOnTab: interactive

    function key() {
        Ui.keyboardActive = true;
    }
    Keys.onReturnPressed: { key(); row.activate(); }
    Keys.onEnterPressed: { key(); row.activate(); }
    Keys.onRightPressed: { key(); if (row.hasPage) row.opened(); }
    Keys.onSpacePressed: { key(); if (row.hasSwitch && row.interactive) row.toggled(); }
    Keys.onDownPressed: {
        key();
        const next = row.nextItemInFocusChain(true);
        if (next) next.forceActiveFocus();
    }
    Keys.onUpPressed: {
        key();
        const previous = row.nextItemInFocusChain(false);
        if (previous) previous.forceActiveFocus();
    }

    Rectangle {
        anchors.fill: parent
        radius: Ui.hoverRadius
        color: row.lit ? Ui.hover : "transparent"
    }

    Rectangle {
        visible: row.current
        x: 0
        width: Ui.tick
        height: parent.height - Ui.rowHoverInset
        anchors.verticalCenter: parent.verticalCenter
        color: Ui.accent
    }

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.leftMargin: Ui.tickClearance
        anchors.rightMargin: Ui.spaceM
        spacing: Ui.spaceM

        Item {
            visible: row.iconSource.length > 0
            Layout.preferredWidth: Ui.iconColumn
            Layout.preferredHeight: Ui.iconSize
            IconImage {
                anchors.centerIn: parent
                implicitSize: Ui.iconSize
                source: row.iconSource
            }
        }

        Text {
            visible: row.iconSource.length === 0
            Layout.preferredWidth: Ui.iconColumn
            horizontalAlignment: Text.AlignHCenter
            text: row.icon
            color: row.iconColor
            font.pixelSize: Ui.iconSize
            font.family: Ui.font
        }

        Text {
            Layout.preferredWidth: row.valueWidth > 0 ? row.valueWidth : implicitWidth
            Layout.maximumWidth: row.valueWidth > 0 ? row.valueWidth : Number.POSITIVE_INFINITY
            Layout.minimumWidth: 0
            Layout.fillWidth: row.valueWidth <= 0 && row.detail.length === 0
            text: row.value
            color: Ui.value
            font.pixelSize: Ui.valueSize
            font.family: Ui.font
            elide: Text.ElideRight
        }

        Item {
            id: middleSlot
            visible: children.length > 0
            Layout.preferredWidth: childrenRect.width
            Layout.preferredHeight: childrenRect.height
        }

        // Always present, even empty: it takes the spare width so everything before it stays packed
        // left.
        Text {
            Layout.fillWidth: true
            Layout.preferredWidth: implicitWidth
            text: row.detail
            // opacity, not visible, so the layout does not change with it.
            opacity: truncated && width < Ui.detailMinWidth ? 0 : 1
            color: Ui.detail
            font.pixelSize: Ui.detailSize
            font.family: Ui.font
            elide: Text.ElideRight
        }

        Text {
            readonly property string shown: row.lit && row.hoverStatus.length > 0 ? row.hoverStatus : row.status
            visible: shown.length > 0
            Layout.minimumWidth: implicitWidth
            text: shown
            color: row.lit && row.hoverStatus.length > 0 ? Ui.value : row.statusColor
            font.pixelSize: Ui.detailSize
            font.family: Ui.font
        }

        ToggleSwitch {
            visible: row.hasSwitch
            Layout.minimumWidth: implicitWidth
            Layout.alignment: Qt.AlignVCenter
            checked: row.checked
            onToggled: if (row.interactive) row.toggled()
        }

        Item {
            visible: row.hasPage
            Layout.preferredWidth: Ui.chevronColumn
            Layout.minimumWidth: Ui.chevronColumn
            Layout.fillHeight: true

            Text {
                anchors.centerIn: parent
                text: "›"
                color: chevronMouse.containsMouse ? Ui.value : Ui.detail
                font.pixelSize: Ui.chevronSize
                font.family: Ui.font
            }

            MouseArea {
                id: chevronMouse
                anchors.fill: parent
                anchors.leftMargin: -Ui.chevronSlop
                anchors.rightMargin: -Ui.hitSlop
                enabled: row.interactive && row.toggleable && row.hasPage
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: row.opened()
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        z: -1
        enabled: row.interactive
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onEntered: Ui.keyboardActive = false
        onClicked: event => {
            if (event.button === Qt.RightButton) row.secondaryClicked();
            else row.activate();
        }
    }
}
