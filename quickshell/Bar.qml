import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.theme as T
import qs.popups
import qs.modules
import qs.modules.audio
import qs.modules.compositor
import qs.commonwidgets
import qs.services as S

Scope {
    id: bar
    property string time

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property var modelData
            screen: modelData
            WlrLayershell.layer: WlrLayer.Top
            anchors {
                top: true
                left: true
                right: true
            }
            // The window itself is transparent and the ground is painted by a Rectangle inside it,
            // which is how every panel in this shell does it -- and the reason the panels' opacity
            // slider worked while the bar's did not.
            //
            // A Wayland surface's opaque region is decided when the surface is created. A window
            // created with an opaque colour stays marked opaque, so lowering the alpha of
            // `PanelWindow.color` afterwards changes the colour and nothing else: the compositor
            // goes on compositing it as solid. Painting the ground as ordinary content sidesteps
            // that entirely, because the surface is transparent from the start and the alpha lives
            // in a Rectangle that can change whenever it likes.
            color: "transparent"

            // Floating, the window takes the gap above the bar too, so the space it reserves
            // ends where the bar does.
            implicitHeight: T.Config.barBottom

            // Clicks on the bar, or centered on the pill only: the screen either side of it is the
            // desktop's, not the bar's.
            mask: barWindow.centered ? pillMask : barMask
            Region {
                id: barMask
                item: barArea
            }
            Region {
                id: pillMask
                item: pill
            }

            // Blur behind the bar while it is see-through (T.Config.barBlur), in its own shape:
            // the strip with its corners, or the pill.
            BackgroundEffect.blurRegion: !T.Config.barBlur ? null : barWindow.centered ? pillBlur : barBlur
            Region {
                id: barBlur
                item: barArea
                radius: barArea.radius
            }
            Region {
                id: pillBlur
                item: pill
                radius: pill.radius
            }

            // First child, so it sits behind everything else the bar draws.
            Rectangle {
                id: barArea
                // Floating, held in from the screen's top and sides with its corners rounded; the
                // gaps around it are outside the input mask, so clicks there reach the desktop.
                x: T.Config.barSideGap
                y: T.Config.barTopGap
                width: parent.width - T.Config.barSideGap * 2
                height: T.Config.barHeight
                radius: T.Config.barFloating ? T.Config.popupRadius : 0
                antialiasing: true
                // Centered, the ground is the pill, and the strip is only the frame it sits in.
                color: barWindow.centered ? "transparent" : T.Config.barBackground
            }

            // --- Centered ----------------------------------------------------------------------
            //
            // One pill in the middle of the screen holding all three groups side by side, as wide
            // as they are. A panel hangs from it, kept within its flat bottom edge; one wider than
            // the pill widens it evenly both ways to carry the panel (BarPanels), with the groups
            // kept in the middle.
            readonly property bool centered: T.Config.barCentered
            // Between the pill's ends and what it holds.
            readonly property int pillPadding: T.Config.barModuleSpacing
            // Between one group and the next, with a hairline down the middle of the gap; none
            // before an empty group.
            readonly property int groupGap: T.Config.barModuleSpacing
            readonly property real centeredContentWidth: (leftSide.width > 0 ? leftSide.width + groupGap : 0)
                + centerSide.width + groupGap + rightSide.width
            // Where the groups start: centred in the pill as drawn, so they stay put while it grows
            // evenly either side to carry a panel.
            readonly property real centeredContentX: pill.x + Math.round((pill.width - centeredContentWidth) / 2)

            BarPanels { id: pillPanels }
            // The full and floating bars' panels.
            BarPanels { id: panelTracker }

            Rectangle {
                id: pill
                readonly property real natural: barWindow.centeredContentWidth + barWindow.pillPadding * 2
                visible: barWindow.centered
                x: Math.round((barWindow.width - width) / 2)
                y: T.Config.barTopGap
                // The drawn width follows a panel as it opens.
                width: pillPanels.widthAround(natural, T.Config.popupRadius)
                height: T.Config.barHeight
                radius: T.Config.popupRadius
                antialiasing: true
                // As a ledge the pill is only the geometry -- where the content, the input mask and
                // the blur go -- and the ledge below draws the ground.
                color: T.Config.barIsLedge ? "transparent" : T.Config.barBackground
                // With a panel open and the bar outline asked for, the pill is outlined, and the
                // panel outlines the rest of the shape.
                border.width: !T.Config.barIsLedge && T.Config.panelOutline === "bar" && pillPanels.openness > 0 ? 1 : 0
                border.color: Qt.rgba(T.Config.outline.r, T.Config.outline.g, T.Config.outline.b, pillPanels.openness)
            }

            // The ledge (T.Config.barLedge): the pill poured out of the screen's top edge, its top
            // corners flaring into the edge and its bottom ones rounded -- the shape a panel makes
            // growing out of the bar, so a panel opened from it reads as more of the same. The
            // flares sit outside the body, so the shape is the pill's width plus a flare each side,
            // with the body exactly where the pill is: nothing inside moves. It follows the pill's
            // width as a panel widens it.
            AttachedSurface {
                id: ledge
                visible: T.Config.barIsLedge
                x: pill.x - flare
                y: 0
                width: pill.width + flare * 2
                height: T.Config.barHeight
                fillColor: T.Config.barBackground
                // Square at the bottom while expanded into a panel: the panel carries the sides on
                // down to its own rounded bottom.
                radius: ledge.joined ? 0 : T.Config.popupRadius
                flare: T.Config.popupRadius
                readonly property bool joined: pillPanels.leadingJoin === "snap"
                // No outline at rest. Expanded, the shape is outlined from the flares at the screen's
                // edge down both sides -- the panel takes it on round its bottom -- unless outlines
                // are off; the bottom is left open, as that is where the panel carries on. With a
                // panel hanging from it instead, round the ledge as the pill is outlined, when the
                // bar outline is asked for.
                outlineOpacity: joined ? (T.Config.panelOutline !== "none" ? pillPanels.openness : 0)
                    : T.Config.panelOutline === "bar" ? pillPanels.openness : 0
                outlineBottom: !joined
                outlineFade: joined && T.Config.panelOutline === "fade" ? flare : 0
            }

            // A snapped panel shares the ledge's straight sides, so nothing in the shape says where
            // the bar ends: a hairline there gives the bar row its bottom edge back.
            Rectangle {
                visible: T.Config.barIsLedge && pillPanels.leadingJoin === "snap"
                x: pill.x + T.Config.popupPadding
                y: T.Config.barHeight - 1
                width: pill.width - T.Config.popupPadding * 2
                height: 1
                color: Qt.rgba(T.Config.surfaceText.r, T.Config.surfaceText.g, T.Config.surfaceText.b, 0.10)
            }

            // Where a panel anchors to the pill: the pill at the width it is growing to, so a panel
            // is placed once, for where the pill will be, rather than chasing it.
            Item {
                id: pillBody
                // What the pill holds, never widened: how a panel on the ledge decides how to join
                // it (HoverPopupWindow.ledgeJoin).
                readonly property real naturalWidth: pill.natural
                width: pillPanels.targetWidth(pill.natural, T.Config.popupRadius)
                x: Math.round((barWindow.width - width) / 2)
                y: T.Config.barTopGap
                height: T.Config.barHeight
            }

            // With a panel open, an outline along the bar's bottom edge. The panel draws the rest
            // -- round its flares, sides and bottom -- so the bar and the panel are outlined as one
            // shape. The panel covers this line where it hangs, since it overlaps the bar by a
            // pixel.
            Rectangle {
                visible: !barWindow.centered && T.Config.panelOutline === "bar" && opacity > 0
                opacity: panelTracker.openness
                x: barArea.x + barArea.radius
                y: T.Config.barBottom - 1
                width: barArea.width - barArea.radius * 2
                height: 1
                color: T.Config.outline
            }

            // Centered, hairlines either side of the workspaces: before them when there is a media
            // button, and between them and the capsule.
            Rectangle {
                visible: barWindow.centered && leftSide.width > 0
                x: Math.round(centerSide.x - (barWindow.groupGap + width) / 2)
                y: T.Config.barTopGap + Math.round((T.Config.barHeight - height) / 2)
                width: 1
                height: Math.round(T.Config.barHeight * 0.45)
                color: Qt.rgba(T.Config.surfaceText.r, T.Config.surfaceText.g, T.Config.surfaceText.b, 0.18)
            }
            Rectangle {
                visible: barWindow.centered && rightSide.width > 0
                x: Math.round(centerSide.x + centerSide.width + (barWindow.groupGap - width) / 2)
                y: T.Config.barTopGap + Math.round((T.Config.barHeight - height) / 2)
                width: 1
                height: Math.round(T.Config.barHeight * 0.45)
                color: Qt.rgba(T.Config.surfaceText.r, T.Config.surfaceText.g, T.Config.surfaceText.b, 0.18)
            }

            // Stay awake, at the compositor's level. The backend holds a logind inhibitor, which
            // is what hypridle and systemd watch; this is the belt to that pair of braces, because
            // a Wayland idle-inhibit stops the compositor reporting idle at all -- and it has to
            // live here, since the protocol inhibits against a surface and the daemon has none.
            IdleInhibitor {
                window: barWindow
                enabled: S.StayAwake.enabled
            }

            // Left: the launcher and what is playing.
            RowLayout {
                id: leftSide
                spacing: T.Config.barModuleSpacing
                // Found by panels opened from in here; see HoverPopupWindow.
                readonly property var barPanels: barWindow.centered ? pillPanels : panelTracker
                readonly property Item barIsland: barWindow.centered ? pillBody : null
                readonly property Item barStrip: barArea
                // Placed by x rather than anchors, in every style. An anchor removed at runtime
                // leaves the item where the anchor put it -- an x binding underneath does not take
                // over until something it reads changes -- so switching style after startup, as
                // reading config.toml does, left the groups where the first style put them.
                x: barWindow.centered ? barWindow.centeredContentX : barArea.x + T.Config.barModuleSpacing

                anchors {
                    top: barArea.top
                    bottom: barArea.bottom
                }

                children: [
                    ApplicationLauncher {},
                    // Centered, a play/pause button only (see MediaIndicator).
                    MediaIndicator {
                        id: mediaIndicator
                        popup: mediaPanel
                    }
                ]
            }

            // Centre: the workspaces, the thing glanced at most, where the eye lands. A strip of
            // many workspaces is capped at a share of the bar and scrolls rather than pushing into
            // the groups either side.
            Flickable {
                id: centerSide
                readonly property var barPanels: barWindow.centered ? pillPanels : panelTracker
                readonly property Item barIsland: barWindow.centered ? pillBody : null
                readonly property Item barStrip: barArea
                x: barWindow.centered ? barWindow.centeredContentX + (leftSide.width > 0 ? leftSide.width + barWindow.groupGap : 0)
                    : Math.round((parent.width - width) / 2)
                width: Math.min(centerContent.implicitWidth, parent.width * T.Config.workspaceStripMaxWidthRatio)
                contentWidth: centerContent.implicitWidth
                contentHeight: height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentWidth > width

                anchors {
                    top: barArea.top
                    bottom: barArea.bottom
                }

                RowLayout {
                    id: centerContent
                    height: parent.height
                    spacing: T.Config.barModuleSpacing

                    Workspaces {}
                }
            }

            RowLayout {
                id: rightSide
                // The drawer's own spacing between its icons (IndividualBarRight), so the clock
                // after them sits at the same distance as one icon from the next rather than
                // standing off as a group of its own.
                spacing: Math.max(4, Math.round(T.Config.barModuleSpacing / 2))
                readonly property var barPanels: barWindow.centered ? pillPanels : panelTracker
                readonly property Item barIsland: barWindow.centered ? pillBody : null
                readonly property Item barStrip: barArea
                x: barWindow.centered ? centerSide.x + centerSide.width + barWindow.groupGap
                    : barArea.x + barArea.width - width - T.Config.barModuleSpacing
                Layout.alignment: Qt.AlignVCenter

                anchors {
                    top: barArea.top
                    bottom: barArea.bottom
                }

                IndividualBarRight {}

                // The time at the far right, after the system icons, where most desktops keep it.
                // Compact, the time is in the status capsule instead (IndividualBarRight).
                ClickableClock {
                    id: clock
                    visible: !T.Config.barCompact
                    Layout.alignment: Qt.AlignVCenter
                    popup: calendarPanel
                }
            }

            CalendarPanel {
                id: calendarPanel
                trigger: clock
            }

            MediaPanel {
                id: mediaPanel
                trigger: mediaIndicator
            }
        }
    }
}
