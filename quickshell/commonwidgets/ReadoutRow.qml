import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.theme as T

// A Readout row: icon · value · (anything in the middle, a gauge) · dim detail · status · optional ›.
// (`status` is the brief's "state": Item already has a `state`, the states machinery's.)
//
// A click toggles when the row is `toggleable`, otherwise opens its page (`hasPage`), otherwise is
// a plain `clicked()`. A row that does both keeps its › as a target of its own, so drilling in
// does not toggle. A toggle shows a ReadoutSwitch at the right end -- never "on" or "off" as text;
// the status column is for information -- and a row that opens its page on a click but still has
// something to switch (Wi-Fi: the network list is what a click is after) sets `hasSwitch` without
// `toggleable`, so only the switch itself flips it. Keyboard: Up and Down move through the rows, Enter activates, Right opens the
// page; every panel gets it from here.
Item {
    id: row

    property string icon: ""
    // An image in the icon column instead of a glyph: an app's icon.
    property string iconSource: ""
    property color iconColor: row.active ? Readout.accent : Readout.value
    property string value: ""
    // A fixed width for the value, for a list that should read as a table: what follows it (a
    // gauge, a swatch, the detail) then starts at the same place on every row. 0: as wide as it is.
    property real valueWidth: 0
    property string detail: ""
    property string status: ""
    // Shown in place of `status` while hovered or focused: the row's action ("connect").
    property string hoverStatus: ""
    property color statusColor: row.active ? Readout.accent : Readout.detail
    property bool active: false
    property bool toggleable: false
    property bool hasSwitch: toggleable
    property bool checked: active
    property bool hasPage: false
    property bool interactive: true
    // Anything between the value and the detail: a gauge.
    default property alias middle: middleSlot.data

    signal toggled()
    signal opened()
    signal clicked()
    signal secondaryClicked()

    readonly property bool lit: interactive && (mouse.containsMouse || chevronMouse.containsMouse || (activeFocus && Readout.keyboardActive))

    function activate() {
        if (!interactive) return;
        if (toggleable) toggled();
        else if (hasPage) opened();
        else clicked();
    }

    Layout.fillWidth: true
    implicitHeight: Readout.rowHeight
    implicitWidth: content.implicitWidth
    activeFocusOnTab: interactive

    // Each of these marks the keyboard as in use (Readout.keyboardActive), so focus is drawn.
    function key() {
        Readout.keyboardActive = true;
    }
    Keys.onReturnPressed: { key(); row.activate(); }
    Keys.onEnterPressed: { key(); row.activate(); }
    Keys.onRightPressed: { key(); if (row.hasPage) row.opened(); }
    // Space flips the switch, for a row whose Enter opens its page instead.
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
        radius: Readout.hoverRadius
        color: row.lit ? Readout.hover : "transparent"
    }

    // What's on.
    Rectangle {
        visible: row.active
        x: 0
        width: Readout.tick
        height: parent.height - 10
        anchors.verticalCenter: parent.verticalCenter
        color: Readout.accent
    }

    RowLayout {
        id: content
        anchors.fill: parent
        // Clear of the tick on the left edge, so the tick reads as a mark beside the row rather
        // than part of its icon.
        anchors.leftMargin: 10
        anchors.rightMargin: 6
        spacing: 6

        Item {
            visible: row.iconSource.length > 0
            Layout.preferredWidth: Readout.iconColumn
            Layout.preferredHeight: Readout.iconSize
            IconImage {
                anchors.centerIn: parent
                implicitSize: Readout.iconSize
                source: row.iconSource
            }
        }

        Text {
            visible: row.iconSource.length === 0
            Layout.preferredWidth: Readout.iconColumn
            horizontalAlignment: Text.AlignHCenter
            text: row.icon
            color: row.iconColor
            font.pixelSize: Readout.iconSize
            font.family: Readout.font
        }

        Text {
            Layout.preferredWidth: row.valueWidth > 0 ? row.valueWidth : implicitWidth
            Layout.maximumWidth: row.valueWidth > 0 ? row.valueWidth : Number.POSITIVE_INFINITY
            text: row.value
            color: Readout.value
            font.pixelSize: Readout.valueSize
            font.family: Readout.font
            elide: Text.ElideRight
        }

        Item {
            id: middleSlot
            visible: children.length > 0
            Layout.preferredWidth: childrenRect.width
            Layout.preferredHeight: childrenRect.height
        }

        // Always there, even empty: it is what takes the row's spare width, so everything before
        // it stays packed to the left -- without it, a row with a fixed-width value and no detail
        // had its spare width spread around the value, pushing it off its column.
        Text {
            Layout.fillWidth: true
            Layout.preferredWidth: implicitWidth
            text: row.detail
            color: Readout.detail
            font.pixelSize: Readout.detailSize
            font.family: Readout.font
            elide: Text.ElideRight
        }

        Text {
            readonly property string shown: row.lit && row.hoverStatus.length > 0 ? row.hoverStatus : row.status
            visible: shown.length > 0
            text: shown
            color: row.lit && row.hoverStatus.length > 0 ? Readout.value : row.statusColor
            font.pixelSize: Readout.detailSize
            font.family: Readout.font
        }

        ReadoutSwitch {
            visible: row.hasSwitch
            Layout.alignment: Qt.AlignVCenter
            checked: row.checked
            onToggled: if (row.interactive) row.toggled()
        }

        // The way into the page: a glyph big enough to see, in a target as tall as the row and
        // wider than the glyph, so it can be hit without aiming.
        Item {
            visible: row.hasPage
            Layout.preferredWidth: 22
            Layout.fillHeight: true

            Text {
                anchors.centerIn: parent
                text: "›"
                color: chevronMouse.containsMouse ? Readout.value : Readout.detail
                font.pixelSize: Readout.chevronSize
                font.family: Readout.font
            }

            MouseArea {
                id: chevronMouse
                anchors.fill: parent
                anchors.leftMargin: -8
                anchors.rightMargin: -6
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
        onEntered: Readout.keyboardActive = false
        onClicked: event => {
            if (event.button === Qt.RightButton) row.secondaryClicked();
            else row.activate();
        }
    }
}
