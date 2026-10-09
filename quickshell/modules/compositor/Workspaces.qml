import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
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
    readonly property bool bubbles: T.Config.workspaceStyle !== "plain"
    // The pill style, the default: the bubble, with the number inside it at the bar's size instead
    // of in a badge.
    readonly property bool numberInside: T.Config.workspaceStyle !== "bubble"

    implicitHeight: inner.implicitHeight + verticalPadding
    implicitWidth: inner.implicitWidth + padding * 2

    // Nothing to show until EpochOxide has answered; the strip collapses rather than holding
    // stale state from a compositor that may no longer be running.
    visible: S.CompositorService.workspaces.length > 0

    RowLayout {
        id: inner
        spacing: workspaceFrame.bubbles ? 6 : padding / 2
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
                readonly property bool bubbled: workspaceFrame.bubbles
                Layout.preferredWidth: !visible ? 0 : bubbled ? bubble.width : innerRow.implicitWidth + padding * 2
                Layout.preferredHeight: !visible ? 0 : bubbled ? bubble.height : innerRow.implicitHeight + verticalPadding / 2

                // No pill for the active workspace. The one it had was surfaceContainer, which is
                // the exact colour every bar icon paints on hover -- so the active workspace read
                // as permanently hovered, and the pill was carrying almost no contrast anyway
                // (1.21:1 against the ground). Which workspace is current is said by the numeral
                // instead: full-strength text and bold, against 75% and regular for the rest.
                //
                // Deliberately not the accent. A colour here would be the brightest thing on the
                // bar and would pull the eye every time focus moved, which is a lot of noise for
                // something you already know you just did.
                color: !bubbled && mwrap.containsMouse ? T.Config.onBar(T.Config.activeSelection) : "transparent"
                radius: 10
                antialiasing: true

                WrapperMouseArea {
                    id: mwrap
                    visible: !workspaceWrapper.bubbled
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

                // --- The bubble and pill styles --------------------------------------------------
                // A ringed circle holding the workspace's window, the number in a badge over its
                // top-left edge -- stretching into an oval to hold every window when there is more
                // than one, the focused one at full strength and the rest dimmed, as the plain
                // style shows them. Sized so the badge stays inside the bar.
                //
                // The pill style puts the number inside instead, ahead of the icons and at the
                // bar's own text size: no badge, so nothing small to read.
                Item {
                    id: bubble
                    visible: workspaceWrapper.bubbled
                    anchors.centerIn: parent
                    readonly property int diameter: T.Config.barHeight - 14
                    readonly property int badge: Math.round(diameter * 0.72)
                    readonly property int iconSize: Math.round(diameter * 0.58)
                    readonly property int iconSpacing: 6
                    readonly property var shownWindows: T.Config.workspaceIcons ? workspaceWrapper.windows : []
                    // A circle for none or one. Stretched for more, it pads its icons in from the
                    // round ends by about half its height, or they crowd into the curve.
                    readonly property int sidePadding: Math.round(diameter * 0.45)
                    readonly property bool numberInside: workspaceFrame.numberInside
                    readonly property int iconsWidth: shownWindows.length * iconSize + Math.max(0, shownWindows.length - 1) * iconSpacing
                    // Everything inside: the icons, and in the pill style the number ahead of them.
                    readonly property int itemCount: shownWindows.length + (numberInside ? 1 : 0)
                    readonly property int innerWidth: numberInside
                        ? number.implicitWidth + (shownWindows.length > 0 ? iconSpacing + iconsWidth : 0)
                        : iconsWidth
                    readonly property int pillWidth: itemCount <= 1 ? diameter : innerWidth + sidePadding * 2
                    // The badge hangs mostly outside the bubble's top-left, far enough out that its
                    // disc stays clear of the icon's corner and only crosses the bubble's ring.
                    // With the number inside there is no badge, and the bubble is all there is.
                    width: pillWidth + (numberInside ? 0 : Math.round(badge * 0.75))
                    height: diameter + (numberInside ? 0 : Math.round(badge * 0.45))
                    // Only the current workspace's ring stands out. The others are a hint of a
                    // boundary, close to the bar's own colour -- a row of strong outlines on a
                    // strip that is always on screen is busy, and the ring's job there is only to
                    // say which icons belong together.
                    readonly property color ring: workspaceWrapper.urgent ? T.Config.red
                        : workspaceWrapper.active ? T.Config.accent : T.Config.surfaceVariant

                    Rectangle {
                        id: circle
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        width: bubble.pillWidth
                        height: bubble.diameter
                        radius: height / 2
                        antialiasing: true
                        color: bubbleMouse.containsMouse ? T.Config.onBar(T.Config.surfaceContainerHigh) : "transparent"
                        border.width: workspaceWrapper.active || workspaceWrapper.urgent ? 2 : 1
                        border.color: bubble.ring
                        opacity: workspaceWrapper.occupied || workspaceWrapper.active ? 1 : 0.6

                        Row {
                            anchors.centerIn: parent
                            spacing: bubble.iconSpacing

                            Text {
                                id: number
                                visible: bubble.numberInside
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
                                model: bubble.shownWindows
                                delegate: IconImage {
                                    required property var modelData
                                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                    implicitWidth: bubble.iconSize
                                    implicitHeight: bubble.iconSize
                                    source: S.CompositorService.getDesktopIcon(S.CompositorService.getDesktopEntry(String(modelData.app_id || "")))
                                    // The focused window is the one the user is looking at; the rest
                                    // of a workspace's windows are dimmed.
                                    opacity: modelData.focused || bubble.shownWindows.length === 1 ? 1.0 : 0.45
                                }
                            }
                        }
                    }

                    // The number, in a small disc over the circle's edge. The current one solid in
                    // the accent; the rest bright text on the dark of the background, unringed --
                    // the disc only cuts the number out of the bubble's ring, since a ring round
                    // the badge as well made two outlines per workspace. (Grey text on a grey disc,
                    // the first version, was hard to read at this size.)
                    Rectangle {
                        visible: !bubble.numberInside
                        anchors.left: parent.left
                        anchors.top: parent.top
                        width: bubble.badge
                        height: bubble.badge
                        radius: width / 2
                        antialiasing: true
                        color: workspaceWrapper.urgent ? T.Config.red
                            : workspaceWrapper.active ? T.Config.accent : T.Config.background

                        Text {
                            anchors.centerIn: parent
                            text: workspaceWrapper.wsName
                            color: workspaceWrapper.active || workspaceWrapper.urgent ? T.Config.background
                                : workspaceWrapper.occupied ? T.Config.surfaceText : T.Config.inactive
                            font.pixelSize: 14
                            font.bold: true
                            font.family: T.Config.fontFamily
                        }
                    }

                    MouseArea {
                        id: bubbleMouse
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
