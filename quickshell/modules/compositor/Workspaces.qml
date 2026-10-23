import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import QtQuick.Effects
import qs.commonwidgets
import qs.theme as T
import qs.services as S

Rectangle {
    id: workspaceFrame
    radius: 20
    antialiasing: true
    color: "transparent"
    Layout.alignment: Qt.AlignVCenter

    property int padding: 7
    property int verticalPadding: 10
    readonly property bool minimapStyle: T.Config.workspaceStyle === "minimap"
    readonly property bool ledgeStyle: T.Config.workspaceStyle === "ledge" || minimapStyle
    readonly property bool pills: T.Config.workspaceStyle !== "plain" && !ledgeStyle

    implicitHeight: ledgeStyle ? T.Config.barHeight : inner.implicitHeight + verticalPadding
    implicitWidth: inner.implicitWidth + padding * 2

    visible: S.CompositorService.workspaces.length > 0

    RowLayout {
        id: inner
        spacing: workspaceFrame.ledgeStyle ? T.Config.barModuleSpacing : workspaceFrame.pills ? 6 : padding / 2
        anchors.centerIn: parent

        Repeater {
            model: S.CompositorService.workspaces

            delegate: Rectangle {
                id: workspaceWrapper
                required property var modelData

                readonly property string wsId: String(modelData.id)
                readonly property string wsName: String(modelData.name)
                readonly property bool active: modelData.active === true
                readonly property bool urgent: modelData.urgent === true
                readonly property var windows: S.CompositorService.windowsForWorkspace(wsName)
                readonly property bool occupied: windows.length > 0

                visible: !T.Config.hideInactiveWorkspaces || active || occupied
                readonly property bool pilled: workspaceFrame.pills
                readonly property bool ledged: workspaceFrame.ledgeStyle
                Layout.preferredWidth: !visible ? 0 : ledged ? ledgeRow.implicitWidth : pilled ? pill.width : innerRow.implicitWidth + padding * 2
                Layout.preferredHeight: !visible ? 0 : ledged ? T.Config.barHeight : pilled ? pill.height : innerRow.implicitHeight + verticalPadding / 2

                color: !pilled && !ledged && mwrap.containsMouse ? T.Config.onBar(T.Config.activeSelection) : "transparent"
                radius: 10
                antialiasing: true

                WrapperMouseArea {
                    id: mwrap
                    visible: !workspaceWrapper.pilled && !workspaceWrapper.ledged
                    anchors.centerIn: parent
                    implicitWidth: visible ? innerRow.implicitWidth : 0
                    implicitHeight: visible ? innerRow.implicitHeight : 0
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onPressed: S.CompositorService.focusWorkspace(workspaceWrapper.wsId)

                    RowLayout {
                        id: innerRow
                        anchors.fill: parent
                        spacing: 5

                        Text {
                            text: workspaceWrapper.wsName
                            font.pixelSize: T.Config.barIconSize
                            font.weight: workspaceWrapper.active ? Font.Bold : Font.Normal
                            font.family: T.Config.fontFamily
                            color: workspaceWrapper.urgent ? T.Config.red : workspaceWrapper.active ? T.Config.active : T.Config.inactive
                        }

                        Repeater {
                            model: T.Config.workspaceIcons ? workspaceWrapper.windows : []

                            delegate: IconImage {
                                required property var modelData

                                implicitWidth: T.Config.barIconSize
                                implicitHeight: T.Config.barIconSize
                                source: S.CompositorService.getDesktopIcon(S.CompositorService.getDesktopEntry(String(modelData.app_id || "")))
                                opacity: modelData.focused ? 1.0 : 0.35
                            }
                        }
                    }
                }

                Item {
                    id: pill
                    visible: workspaceWrapper.pilled
                    anchors.centerIn: parent
                    readonly property int diameter: T.Config.barHeight - 14
                    readonly property int iconSize: Math.round(diameter * 0.58)
                    readonly property int iconSpacing: 6
                    readonly property var shownWindows: T.Config.workspaceIcons ? workspaceWrapper.windows : []
                    readonly property int sidePadding: Math.round(diameter * 0.45)
                    readonly property int iconsWidth: shownWindows.length * iconSize + Math.max(0, shownWindows.length - 1) * iconSpacing
                    readonly property int innerWidth: number.implicitWidth + (shownWindows.length > 0 ? iconSpacing + iconsWidth : 0)
                    width: shownWindows.length === 0 ? diameter : innerWidth + sidePadding * 2
                    height: diameter
                    readonly property color ring: workspaceWrapper.urgent ? T.Config.red
                        : workspaceWrapper.active ? T.Config.accent : T.Config.surfaceVariant

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.min(height / 2, T.Config.cardRadius)
                        antialiasing: true
                        color: pillMouse.containsMouse ? T.Config.onBar(T.Config.surfaceContainerHigh) : "transparent"
                        border.width: 1
                        border.color: pill.ring
                        opacity: workspaceWrapper.occupied || workspaceWrapper.active ? 1 : 0.6

                        Row {
                            anchors.centerIn: parent
                            spacing: pill.iconSpacing

                            Text {
                                id: number
                                anchors.verticalCenter: parent.verticalCenter
                                text: workspaceWrapper.wsName
                                color: workspaceWrapper.urgent ? T.Config.red
                                    : workspaceWrapper.active ? T.Config.accent
                                    : workspaceWrapper.occupied ? T.Config.surfaceText : T.Config.inactive
                                font.pixelSize: T.Config.barIconSize
                                font.bold: workspaceWrapper.active
                                font.family: T.Config.fontFamily
                            }

                            Repeater {
                                model: pill.shownWindows
                                delegate: IconImage {
                                    required property var modelData
                                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                    implicitWidth: pill.iconSize
                                    implicitHeight: pill.iconSize
                                    source: S.CompositorService.getDesktopIcon(S.CompositorService.getDesktopEntry(String(modelData.app_id || "")))
                                    opacity: modelData.focused || pill.shownWindows.length === 1 ? 1.0 : 0.45
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: pillMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: S.CompositorService.focusWorkspace(workspaceWrapper.wsId)
                    }
                }

                Item {
                    id: ledgeItem
                    visible: workspaceWrapper.ledged
                    anchors.fill: parent

                    readonly property var ordered: workspaceWrapper.windows.slice().sort((a, b) => (Number(a.x) || 0) - (Number(b.x) || 0))
                    readonly property int limit: Math.max(0, T.Config.workspaceIconLimit)
                    readonly property var shown: T.Config.workspaceIcons ? ordered.slice(0, limit) : []
                    readonly property int overflow: T.Config.workspaceIcons ? ordered.length - shown.length : 0
                    readonly property int iconSize: T.Config.barSmallIconSize
                    readonly property bool mono: T.Config.workspaceIconsMono

                    readonly property bool mapped: workspaceFrame.minimapStyle && S.CompositorService.isNiri && workspaceWrapper.active
                    readonly property var columns: mapped ? S.CompositorService.columnsForWorkspace(workspaceWrapper.wsName) : []
                    readonly property int cellIcon: T.Config.barIconSize - 2
                    readonly property int stackIcon: T.Config.barIconSize - 6
                    readonly property var focusedWindow: workspaceWrapper.windows.find(window => window.focused === true) || null

                    readonly property var strip: {
                        const cols = ledgeItem.columns;
                        const icon = ledgeItem.cellIcon;
                        const gap = 3;
                        const monitorWidth = S.CompositorService.monitorWidthForWorkspace(workspaceWrapper.wsName);
                        const proportional = monitorWidth > 0 && cols.some(c => !c.floating && c.width > 0);
                        let widths = cols.map(c => (c.floating || !proportional) ? icon + 10
                            : Math.max(icon + 4, Math.min(56, Math.round(c.width / monitorWidth * 64))));
                        const max = Math.max(icon + 4, T.Config.workspaceMinimapMaxWidth);
                        const total = list => list.reduce((a, b) => a + b, 0) + gap * Math.max(0, list.length - 1);
                        if (total(widths) > max) widths = widths.map(() => icon + 4);
                        let start = 0;
                        let end = cols.length;
                        if (total(widths) > max) {
                            const more = 22;
                            const fit = Math.max(1, Math.floor((max - 2 * more + gap) / (icon + 4 + gap)));
                            const focus = Math.max(0, cols.findIndex(c => c.focused));
                            start = Math.max(0, Math.min(focus - Math.floor((fit - 1) / 2), cols.length - fit));
                            end = Math.min(cols.length, start + fit);
                        }
                        const cells = [];
                        let x = 0;
                        for (let i = start; i < end; i++) {
                            cells.push({ column: cols[i], width: widths[i], x: x });
                            x += widths[i] + gap;
                        }
                        return { cells: cells, hiddenLeft: start, hiddenRight: cols.length - end, width: Math.max(0, x - gap) };
                    }

                    // Snapped to whole device pixels: at a fractional scale a 2px line straddles
                    // rows and blurs.
                    readonly property real dpr: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1
                    function px(value) {
                        return Math.max(1, Math.round(value * dpr)) / dpr;
                    }
                    function snap(value) {
                        return Math.round(value * dpr) / dpr;
                    }

                    Row {
                        id: ledgeRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: ledgeItem.snap((parent.height - height) / 2 - 2)
                        spacing: 5

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: workspaceWrapper.wsName
                            font.pixelSize: T.Config.barIconSize
                            font.family: T.Config.fontFamily
                            font.weight: workspaceWrapper.active ? Font.Bold : Font.Normal
                            color: workspaceWrapper.urgent ? T.Config.red
                                : workspaceWrapper.active || ledgeMouse.containsMouse ? T.Config.active : T.Config.inactive
                        }

                        Row {
                            visible: ledgeItem.shown.length > 0 && !ledgeItem.mapped
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Repeater {
                                model: ledgeItem.shown

                                delegate: Item {
                                    id: ledgeIcon
                                    required property var modelData
                                    width: ledgeItem.iconSize
                                    height: ledgeItem.iconSize

                                    readonly property string home: T.Config.workspaceHomeFor(modelData.app_id)
                                    readonly property bool away: home.length > 0 && home !== String(modelData.workspace)
                                    readonly property bool inColour: away || (workspaceWrapper.active && modelData.focused === true)

                                    IconImage {
                                        anchors.fill: parent
                                        source: S.CompositorService.getDesktopIcon(S.CompositorService.getDesktopEntry(String(ledgeIcon.modelData.app_id || "")))
                                        opacity: ledgeIcon.inColour ? 1.0 : 0.6
                                        layer.enabled: !ledgeIcon.inColour || ledgeItem.mono
                                        layer.effect: MultiEffect {
                                            saturation: ledgeItem.mono ? -1.0 : -0.5
                                        }
                                    }

                                    Rectangle {
                                        visible: ledgeIcon.away
                                        x: 0
                                        y: ledgeItem.snap(parent.height + 4)
                                        width: parent.width
                                        height: ledgeItem.px(2)
                                        color: T.Config.inactive
                                    }
                                }
                            }
                        }

                        Text {
                            visible: ledgeItem.overflow > 0 && !ledgeItem.mapped
                            anchors.verticalCenter: parent.verticalCenter
                            text: "+" + ledgeItem.overflow
                            color: T.Config.inactive
                            font.pixelSize: T.Config.fontSizeSubtext
                            font.family: T.Config.fontFamily
                        }

                        Item {
                            id: stripSlot
                            visible: ledgeItem.mapped
                            width: minimap.implicitWidth
                            height: 1
                        }

                        Text {
                            readonly property string title: ledgeItem.focusedWindow ? String(ledgeItem.focusedWindow.title || "") : ""
                            visible: ledgeItem.mapped && T.Config.workspaceShowTitle && title.length > 0
                            anchors.verticalCenter: parent.verticalCenter
                            leftPadding: 1
                            text: title.length > 28 ? title.slice(0, 27) + "…" : title
                            color: Qt.rgba(T.Config.surfaceText.r, T.Config.surfaceText.g, T.Config.surfaceText.b, 0.45)
                            font.pixelSize: T.Config.fontSizeSubtext
                            font.family: T.Config.fontFamily
                        }
                    }

                    Rectangle {
                        readonly property real inset: ledgeItem.px(4)
                        visible: workspaceWrapper.active && !ledgeItem.mapped
                        x: ledgeRow.x
                        height: ledgeItem.px(Ui.tick)
                        y: Math.floor((parent.height - inset - height) * ledgeItem.dpr) / ledgeItem.dpr
                        width: ledgeRow.width
                        color: T.Config.accent
                    }

                    MouseArea {
                        id: ledgeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: S.CompositorService.focusWorkspace(workspaceWrapper.wsId)
                    }

                    Item {
                        id: minimap
                        visible: ledgeItem.mapped
                        x: ledgeRow.x + stripSlot.x
                        width: implicitWidth
                        height: parent.height
                        readonly property real lead: hiddenLeft.visible ? hiddenLeft.implicitWidth + 4 : 0
                        implicitWidth: lead + ledgeItem.strip.width + (hiddenRight.visible ? hiddenRight.implicitWidth + 4 : 0)
                        readonly property real centre: ledgeRow.y + ledgeRow.height / 2
                        readonly property real barHeight: ledgeItem.px(Ui.tick)
                        readonly property real barY: Math.floor((height - ledgeItem.px(4) - barHeight) * ledgeItem.dpr) / ledgeItem.dpr

                        component More: Text {
                            y: minimap.centre - height / 2
                            color: T.Config.inactive
                            font.pixelSize: T.Config.fontSizeSubtext
                            font.family: T.Config.fontFamily
                        }

                        More {
                            id: hiddenLeft
                            visible: ledgeItem.strip.hiddenLeft > 0
                            x: 0
                            text: "+" + ledgeItem.strip.hiddenLeft
                        }

                        Repeater {
                            model: ledgeItem.strip.cells
                            delegate: Item {
                                id: cell
                                required property var modelData
                                readonly property var column: modelData.column
                                readonly property var windows: column.windows
                                readonly property var target: windows.find(window => window.focused === true) || windows[0]
                                readonly property bool lit: column.focused || cellMouse.containsMouse
                                x: minimap.lead + modelData.x
                                width: modelData.width
                                height: minimap.height

                                component CellIcon: IconImage {
                                    required property var window
                                    property int size: ledgeItem.cellIcon
                                    implicitWidth: size
                                    implicitHeight: size
                                    source: S.CompositorService.getDesktopIcon(S.CompositorService.getDesktopEntry(String(window.app_id || "")))
                                    opacity: cell.lit ? 1.0 : 0.7
                                    layer.enabled: ledgeItem.mono
                                    layer.effect: MultiEffect {
                                        saturation: -1.0
                                    }
                                }

                                CellIcon {
                                    visible: cell.windows.length === 1
                                    window: cell.windows[0]
                                    x: Math.round((cell.width - width) / 2)
                                    y: Math.round(minimap.centre - height / 2)
                                }
                                Column {
                                    visible: cell.windows.length > 1
                                    x: Math.round((cell.width - width - (stackMore.visible ? stackMore.implicitWidth + 1 : 0)) / 2)
                                    y: Math.round(minimap.centre - height / 2)
                                    spacing: 1
                                    Repeater {
                                        model: cell.windows.slice(0, 2)
                                        delegate: CellIcon {
                                            required property var modelData
                                            window: modelData
                                            size: ledgeItem.stackIcon
                                        }
                                    }
                                }
                                Text {
                                    id: stackMore
                                    visible: cell.windows.length > 2
                                    x: Math.round((cell.width + ledgeItem.stackIcon - implicitWidth) / 2) + 1
                                    y: Math.round(minimap.centre - height / 2)
                                    text: "+" + (cell.windows.length - 2)
                                    color: T.Config.inactive
                                    font.pixelSize: Math.max(8, T.Config.fontSizeSubtext - 2)
                                    font.family: T.Config.fontFamily
                                }

                                Rectangle {
                                    visible: !cell.column.floating
                                    y: minimap.barY
                                    width: cell.width
                                    height: minimap.barHeight
                                    color: cell.column.focused ? (ledgeItem.mono ? T.Config.active : T.Config.accent)
                                        : Qt.rgba(T.Config.surfaceText.r, T.Config.surfaceText.g, T.Config.surfaceText.b, 0.20)
                                }

                                MouseArea {
                                    id: cellMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: if (cell.target) S.CompositorService.focusWindow(cell.target.id)
                                }
                            }
                        }

                        More {
                            id: hiddenRight
                            visible: ledgeItem.strip.hiddenRight > 0
                            x: minimap.lead + ledgeItem.strip.width + 4
                            text: "+" + ledgeItem.strip.hiddenRight
                        }
                    }
                }
            }
        }
    }
}
