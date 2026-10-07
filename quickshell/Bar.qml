import QtQuick
import QtQuick.Layouts
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

            implicitHeight: T.Config.barHeight

            // Clicks on the bar, or in the island style on the island only: the screen showing
            // either side of it is the desktop's, not the bar's.
            mask: Region {
                item: barWindow.island ? islandShape : barArea
            }

            // First child, so it sits behind everything else the bar draws.
            Rectangle {
                id: barArea
                anchors.fill: parent
                // In the island style the ground is the island below, and the strip is only the
                // frame the modules are laid out in.
                color: barWindow.island ? "transparent" : T.Config.barBackground
            }

            // --- Island ------------------------------------------------------------------------
            //
            // In the island style the three groups sit side by side, in one island hanging from the
            // top of the screen and centred on it. Its width is whatever they need -- so it moves
            // as the drawer opens, workspaces come and go, or the media title appears -- or, while
            // a panel too wide for it is open, enough to carry that panel (BarPanels.widthAround).
            readonly property bool island: T.Config.barStyle === "island"
            // Between one group and the next, and after the last.
            readonly property int islandGap: T.Config.barModuleSpacing * 2
            readonly property real islandNatural: T.Config.barModuleSpacing + leftSide.width + islandGap
                + centerSide.width + islandGap + rightSide.width + T.Config.barModuleSpacing
            readonly property real islandWidth: panelTracker.widthAround(islandNatural, T.Config.popupRadius)
            readonly property real islandX: Math.round((width - islandWidth) / 2)
            // Where the groups start: centred in the island, which is only wider than them while
            // it carries a wide panel.
            readonly property real islandContentX: islandX + Math.round((islandWidth - islandNatural) / 2)

            AttachedSurface {
                id: islandShape
                visible: barWindow.island
                x: barWindow.islandX
                width: barWindow.islandWidth
                height: T.Config.barHeight
                // Square where it meets the top of the screen; only its bottom corners are round.
                flare: 0
                // Round its sides and along its bottom while a panel is open; the panel covers
                // the bottom line where it hangs, and outlines the rest of itself.
                outlineOpacity: T.Config.panelOutline === "bar" ? panelTracker.openness : 0
            }

            // The island's body, for panels to anchor to.
            Item {
                id: islandBody
                x: barWindow.islandX
                width: barWindow.islandWidth
                height: T.Config.barHeight
            }

            // How far open the most-open panel from this bar is: panels attach here on opening
            // (see HoverPopupWindow), and the outline below fades in with them.
            BarPanels {
                id: panelTracker
            }

            // With a panel open, an outline along the bar's bottom edge. The panel draws the rest
            // -- round its flares, sides and bottom -- so the bar and the panel are outlined as one
            // shape. The panel covers this line where it hangs, since it overlaps the bar by a
            // pixel.
            Rectangle {
                visible: !barWindow.island && T.Config.panelOutline === "bar" && opacity > 0
                opacity: panelTracker.openness
                y: T.Config.barHeight - 1
                width: parent.width
                height: 1
                color: T.Config.outline
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
                readonly property var barPanels: panelTracker
                readonly property Item barIsland: barWindow.island ? islandBody : null
                readonly property Item barStrip: barArea
                // Placed by x rather than anchors, in both styles. An anchor removed at runtime
                // leaves the item where the anchor put it -- an x binding underneath does not take
                // over until something it reads changes -- so switching to the island style after
                // startup, as reading config.toml does, left the groups at the screen's edges.
                x: (barWindow.island ? barWindow.islandContentX : 0) + T.Config.barModuleSpacing

                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }

                children: [
                    ApplicationLauncher {},
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
                readonly property var barPanels: panelTracker
                readonly property Item barIsland: barWindow.island ? islandBody : null
                readonly property Item barStrip: barArea
                x: barWindow.island ? leftSide.x + leftSide.width + barWindow.islandGap
                    : Math.round((parent.width - width) / 2)
                width: Math.min(centerContent.implicitWidth, parent.width * T.Config.workspaceStripMaxWidthRatio)
                contentWidth: centerContent.implicitWidth
                contentHeight: height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentWidth > width

                anchors {
                    top: parent.top
                    bottom: parent.bottom
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
                readonly property var barPanels: panelTracker
                readonly property Item barIsland: barWindow.island ? islandBody : null
                readonly property Item barStrip: barArea
                x: barWindow.island ? centerSide.x + centerSide.width + barWindow.islandGap
                    : parent.width - width - T.Config.barModuleSpacing
                Layout.alignment: Qt.AlignVCenter

                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }

                IndividualBarRight {}

                // The time at the far right, after the system icons, where most desktops keep it.
                ClickableClock {
                    id: clock
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
