import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import QtQuick.Effects
import qs.theme as T
import qs.services as S

// The bar's workspace strip, for whichever compositor is running.
//
// Everything it renders comes from CompositorService's normalized state, so there is one widget
// rather than one per compositor. Window icons are shown when Config.workspaceIcons is set.
Rectangle {
    id: workspaceFrame
    radius: 20
    antialiasing: true
    color: "transparent"
    Layout.alignment: Qt.AlignVCenter

    property int padding: 7
    property int verticalPadding: 10
    // The ledge style: no boxes, a mono number and quiet icons, an accent tick under the current
    // workspace on the bar's bottom edge. A path of its own below, not folded into the others.
    readonly property bool ledgeStyle: T.Config.workspaceStyle === "ledge"
    // The pill style, the default: each workspace a ringed pill holding its number and its icons.
    readonly property bool pills: T.Config.workspaceStyle !== "plain" && !ledgeStyle

    // The ledge style takes the bar's whole height, so the tick can sit on the bar's bottom edge.
    implicitHeight: ledgeStyle ? T.Config.barHeight : inner.implicitHeight + verticalPadding
    implicitWidth: inner.implicitWidth + padding * 2

    // Nothing to show until EpochOxide has answered; the strip collapses rather than holding
    // stale state from a compositor that may no longer be running.
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

                // An empty, inactive workspace is not worth a slot in the bar.
                visible: !T.Config.hideInactiveWorkspaces || active || occupied
                readonly property bool pilled: workspaceFrame.pills
                readonly property bool ledged: workspaceFrame.ledgeStyle
                Layout.preferredWidth: !visible ? 0 : ledged ? ledgeRow.implicitWidth : pilled ? pill.width : innerRow.implicitWidth + padding * 2
                Layout.preferredHeight: !visible ? 0 : ledged ? T.Config.barHeight : pilled ? pill.height : innerRow.implicitHeight + verticalPadding / 2

                // No pill for the active workspace. The one it had was surfaceContainer, which is
                // the exact colour every bar icon paints on hover -- so the active workspace read
                // as permanently hovered, and the pill was carrying almost no contrast anyway
                // (1.21:1 against the ground). Which workspace is current is said by the numeral
                // instead: full-strength text and bold, against 75% and regular for the rest.
                //
                // Deliberately not the accent. A colour here would be the brightest thing on the
                // bar and would pull the eye every time focus moved, which is a lot of noise for
                // something you already know you just did.
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
                                // The focused window is the one the user is looking at; the rest
                                // of a workspace's windows are dimmed.
                                opacity: modelData.focused ? 1.0 : 0.35
                            }
                        }
                    }
                }

                // --- The pill style ----------------------------------------------------------------
                // A ringed pill holding the number at the bar's own text size and then the
                // workspace's windows, the focused one at full strength and the rest dimmed, as the
                // plain style shows them. A square for an empty workspace or a lone window.
                Item {
                    id: pill
                    visible: workspaceWrapper.pilled
                    anchors.centerIn: parent
                    readonly property int diameter: T.Config.barHeight - 14
                    readonly property int iconSize: Math.round(diameter * 0.58)
                    readonly property int iconSpacing: 6
                    readonly property var shownWindows: T.Config.workspaceIcons ? workspaceWrapper.windows : []
                    // Padding in from the ends, about half the height, or the icons crowd the corners.
                    readonly property int sidePadding: Math.round(diameter * 0.45)
                    readonly property int iconsWidth: shownWindows.length * iconSize + Math.max(0, shownWindows.length - 1) * iconSpacing
                    readonly property int innerWidth: number.implicitWidth + (shownWindows.length > 0 ? iconSpacing + iconsWidth : 0)
                    width: shownWindows.length === 0 ? diameter : innerWidth + sidePadding * 2
                    height: diameter
                    // Only the current workspace's ring stands out. The others are a hint of a
                    // boundary, close to the bar's own colour -- a row of strong outlines on a
                    // strip that is always on screen is busy, and the ring's job there is only to
                    // say which icons belong together.
                    readonly property color ring: workspaceWrapper.urgent ? T.Config.red
                        : workspaceWrapper.active ? T.Config.accent : T.Config.surfaceVariant

                    Rectangle {
                        anchors.fill: parent
                        // The rounded rectangle every selection and row in the shell is drawn with,
                        // rather than a capsule.
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
                                    // The focused window is the one the user is looking at; the rest
                                    // of a workspace's windows are dimmed.
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

                // --- The ledge style --------------------------------------------------------------
                // One row, no box: the number and the windows' icons in layout order. A number and
                // its icons are held tight (5px, and 3px between icons) against the wider gap between
                // workspaces, which is what makes each read as one unit without a box round it.
                //
                // The number is never the accent, for the reason the plain style's is not: the
                // accent here means only "where you are", and that is said once, by the tick.
                Item {
                    id: ledgeItem
                    visible: workspaceWrapper.ledged
                    anchors.fill: parent

                    // Every window, left to right as laid out (on niri `x` is the column).
                    readonly property var ordered: workspaceWrapper.windows.slice().sort((a, b) => (Number(a.x) || 0) - (Number(b.x) || 0))
                    readonly property int limit: Math.max(0, T.Config.workspaceIconLimit)
                    readonly property var shown: T.Config.workspaceIcons ? ordered.slice(0, limit) : []
                    readonly property int overflow: T.Config.workspaceIcons ? ordered.length - shown.length : 0
                    readonly property int iconSize: T.Config.barSmallIconSize

                    // Lines snapped to whole device pixels. At a fractional scale (4/3 here) a 2px
                    // line is 2.67 pixels and lands between rows, and both its edges blur; rounded to
                    // the screen's own pixels, the tick and the underline stay sharp.
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
                        // A touch above centre, to leave the tick below some air: centred, the icons
                        // and the tick crowded each other at the bar's bottom.
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
                            visible: ledgeItem.shown.length > 0
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Repeater {
                                model: ledgeItem.shown

                                delegate: Item {
                                    id: ledgeIcon
                                    required property var modelData
                                    width: ledgeItem.iconSize
                                    height: ledgeItem.iconSize

                                    // Away from home: an app with a home workspace that is somewhere
                                    // else stays in full colour, so it can be found, underlined.
                                    readonly property string home: T.Config.workspaceHomeFor(modelData.app_id)
                                    readonly property bool away: home.length > 0 && home !== String(modelData.workspace)
                                    // Colour for the window you are in, or for a stray; every other
                                    // icon -- the rest of this workspace's too -- quieted the same way,
                                    // so "the one you are in" is the only thing that stands out.
                                    readonly property bool inColour: away || (workspaceWrapper.active && modelData.focused === true)

                                    IconImage {
                                        anchors.fill: parent
                                        source: S.CompositorService.getDesktopIcon(S.CompositorService.getDesktopEntry(String(ledgeIcon.modelData.app_id || "")))
                                        // Quieted, not stripped: half the colour and a little dimmer,
                                        // so an app is still recognisably itself. Fully grey read as
                                        // a different style from the active workspace's icons.
                                        opacity: ledgeIcon.inColour ? 1.0 : 0.6
                                        layer.enabled: !ledgeIcon.inColour
                                        layer.effect: MultiEffect {
                                            saturation: -0.5
                                        }
                                    }

                                    // Not the accent: the accent means "here", and this means "not
                                    // where it lives".
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
                            visible: ledgeItem.overflow > 0
                            anchors.verticalCenter: parent.verticalCenter
                            text: "+" + ledgeItem.overflow
                            color: T.Config.inactive
                            font.pixelSize: T.Config.fontSizeSubtext
                            font.family: T.Config.fontFamily
                        }

                    }

                    // Where you are: a tick under the number and icons, near the bar's bottom
                    // edge but with a band of the bar's own ground below it. Flush on the edge it
                    // ran into whatever was behind the bar and was hard to read. The strip is the
                    // bar's height in this style, so the bottom here is the bar's.
                    Rectangle {
                        readonly property real inset: ledgeItem.px(4)
                        visible: workspaceWrapper.active
                        x: ledgeRow.x
                        height: ledgeItem.px(3)
                        // Its top on a whole pixel row.
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
                }
            }
        }
    }
}
